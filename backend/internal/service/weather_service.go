package service

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"strconv"
	"strings"
	"time"

	"summitmate/internal/model"
	"summitmate/internal/repository"
)

const (
	cwaDataID  = "F-B0053-033"
	cwaBaseURL = "https://opendata.cwa.gov.tw/fileapi/v1/opendataapi"
)

// WeatherService 處理天氣資料的 ETL 與查詢
type WeatherService struct {
	logger    *slog.Logger
	repo      repository.WeatherRepository
	cwaAPIKey string
	locations []string
}

func NewWeatherService(logger *slog.Logger, repo repository.WeatherRepository, cwaAPIKey string, locations []string) *WeatherService {
	return &WeatherService{
		logger:    logger.With("component", "weather"),
		repo:      repo,
		cwaAPIKey: cwaAPIKey,
		locations: locations,
	}
}

// FetchAndStore 執行完整的 ETL 流程：Fetch → Parse → Aggregate → Store
func (s *WeatherService) FetchAndStore(ctx context.Context) error {
	if s.cwaAPIKey == "" {
		return fmt.Errorf("CWA_API_KEY 未設定")
	}

	// 1. Fetch from CWA
	rawData, issueTime, err := s.fetchFromCWA(ctx)
	if err != nil {
		return fmt.Errorf("CWA Fetch 失敗: %w", err)
	}
	s.logger.Info("CWA 原始資料取得完成", "count", len(rawData), "issue_time", issueTime)

	// 2. Aggregate
	records := s.aggregate(rawData, issueTime)
	s.logger.Info("資料聚合完成", "count", len(records))

	// 3. Store to DB
	if err := s.repo.ReplaceAll(ctx, records); err != nil {
		return fmt.Errorf("寫入 DB 失敗: %w", err)
	}
	s.logger.Info("天氣資料已寫入 DB")

	return nil
}

// ListAll 取得所有天氣資料
func (s *WeatherService) ListAll(ctx context.Context) ([]model.WeatherRecord, error) {
	return s.repo.ListAll(ctx)
}

// ListByLocation 取得特定地點的天氣資料
func (s *WeatherService) ListByLocation(ctx context.Context, location string) ([]model.WeatherRecord, error) {
	return s.repo.ListByLocation(ctx, location)
}

// --- 內部方法 ---

// rawRow 代表攤平後的一筆原始資料
type rawRow struct {
	Location    string
	StartTime   time.Time
	EndTime     time.Time
	ElementName string
	Value       string
}

func (s *WeatherService) fetchFromCWA(ctx context.Context) ([]rawRow, *time.Time, error) {
	url := fmt.Sprintf("%s/%s?Authorization=%s&format=JSON&downloadType=WEB", cwaBaseURL, cwaDataID, s.cwaAPIKey)

	req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		return nil, nil, err
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, nil, err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, nil, err
	}

	// 處理 BOM
	if len(body) >= 3 && body[0] == 0xEF && body[1] == 0xBB && body[2] == 0xBF {
		body = body[3:]
	}

	// 解析 JSON
	var root map[string]interface{}
	if err := json.Unmarshal(body, &root); err != nil {
		return nil, nil, fmt.Errorf("JSON 解析失敗: %w", err)
	}

	cwaopendata, ok := root["cwaopendata"].(map[string]interface{})
	if !ok {
		return nil, nil, fmt.Errorf("JSON 結構不符: 缺少 cwaopendata")
	}

	dataset, ok := cwaopendata["Dataset"].(map[string]interface{})
	if !ok {
		return nil, nil, fmt.Errorf("JSON 結構不符: 缺少 Dataset")
	}

	// 取得 IssueTime
	var issueTime *time.Time
	if dsInfo, ok := dataset["DatasetInfo"].(map[string]interface{}); ok {
		if its, ok := dsInfo["IssueTime"].(string); ok && its != "" {
			if t, err := time.Parse(time.RFC3339, its); err == nil {
				issueTime = &t
			}
		}
	}

	locationsObj, ok := dataset["Locations"].(map[string]interface{})
	if !ok {
		return nil, nil, fmt.Errorf("JSON 結構不符: 缺少 Locations")
	}

	locList, ok := locationsObj["Location"].([]interface{})
	if !ok {
		return nil, nil, fmt.Errorf("JSON 結構不符: Location 不是陣列")
	}

	s.logger.Debug("解析地點數量", "count", len(locList))

	var rows []rawRow

	for _, locRaw := range locList {
		loc, ok := locRaw.(map[string]interface{})
		if !ok {
			continue
		}
		locName, _ := loc["LocationName"].(string)

		elements, ok := loc["WeatherElement"].([]interface{})
		if !ok {
			continue
		}

		for _, elRaw := range elements {
			el, ok := elRaw.(map[string]interface{})
			if !ok {
				continue
			}
			elName, _ := el["ElementName"].(string)

			timeSlots, ok := el["Time"].([]interface{})
			if !ok {
				continue
			}

			for _, tRaw := range timeSlots {
				t, ok := tRaw.(map[string]interface{})
				if !ok {
					continue
				}

				startStr, _ := t["StartTime"].(string)
				endStr, _ := t["EndTime"].(string)

				startTime, err := time.Parse(time.RFC3339, startStr)
				if err != nil {
					startTime, err = time.Parse("2006-01-02T15:04:05", startStr)
					if err != nil {
						continue
					}
				}
				endTime, err := time.Parse(time.RFC3339, endStr)
				if err != nil {
					endTime, err = time.Parse("2006-01-02T15:04:05", endStr)
					if err != nil {
						continue
					}
				}

				val := extractValue(elName, t["ElementValue"])

				rows = append(rows, rawRow{
					Location:    locName,
					StartTime:   startTime,
					EndTime:     endTime,
					ElementName: elName,
					Value:       val,
				})
			}
		}
	}

	return rows, issueTime, nil
}

// extractValue 從 ElementValue 中提取主要數值（對應 GAS 的 extractValue）
func extractValue(elementName string, valObj interface{}) string {
	// ElementValue 可能是 map 或 array
	if arr, ok := valObj.([]interface{}); ok {
		if len(arr) > 0 {
			valObj = arr[0]
		} else {
			return ""
		}
	}

	m, ok := valObj.(map[string]interface{})
	if !ok {
		return ""
	}

	keyMap := map[string]string{
		"平均溫度":     "Temperature",
		"平均相對濕度":   "RelativeHumidity",
		"12小時降雨機率": "ProbabilityOfPrecipitation",
		"風速":       "WindSpeed",
		"天氣現象":     "Weather",
		"最高溫度":     "MaxTemperature",
		"最低溫度":     "MinTemperature",
		"最高體感溫度":   "MaxApparentTemperature",
		"最低體感溫度":   "MinApparentTemperature",
	}

	if key, found := keyMap[elementName]; found {
		if v, ok := m[key]; ok {
			return fmt.Sprintf("%v", v)
		}
	}

	// Fallback: 取第一個 value
	for _, v := range m {
		return fmt.Sprintf("%v", v)
	}
	return ""
}

// aggregate 將原始資料聚合為 WeatherRecord（對應 GAS 的 generateAppView）
func (s *WeatherService) aggregate(rows []rawRow, issueTime *time.Time) []model.WeatherRecord {
	type shortKey = string
	elementMap := map[string]shortKey{
		"平均溫度":     "T",
		"平均相對濕度":   "RH",
		"12小時降雨機率": "PoP",
		"風速":       "WS",
		"天氣現象":     "Wx",
		"最高溫度":     "MaxT",
		"最低溫度":     "MinT",
		"最高體感溫度":   "MaxAT",
		"最低體感溫度":   "MinAT",
	}

	type compositeKey struct {
		Location  string
		StartTime time.Time
		EndTime   time.Time
	}

	consolidated := map[compositeKey]map[string]string{}

	for _, row := range rows {
		sk, ok := elementMap[row.ElementName]
		if !ok {
			continue
		}

		ck := compositeKey{Location: row.Location, StartTime: row.StartTime, EndTime: row.EndTime}
		if consolidated[ck] == nil {
			consolidated[ck] = map[string]string{}
		}
		consolidated[ck][sk] = row.Value
	}

	var records []model.WeatherRecord
	for ck, vals := range consolidated {
		records = append(records, model.WeatherRecord{
			Location:  ck.Location,
			StartTime: ck.StartTime,
			EndTime:   ck.EndTime,
			Wx:        vals["Wx"],
			Temp:      parseFloat(vals["T"]),
			PoP:       parseInt(vals["PoP"]),
			MinTemp:   parseFloat(vals["MinT"]),
			MaxTemp:   parseFloat(vals["MaxT"]),
			Humidity:  parseFloat(vals["RH"]),
			WindSpeed: parseFloat(vals["WS"]),
			MinAT:     parseFloat(vals["MinAT"]),
			MaxAT:     parseFloat(vals["MaxAT"]),
			IssueTime: issueTime,
		})
	}

	return records
}

func parseFloat(s string) float64 {
	s = strings.TrimSpace(s)
	v, _ := strconv.ParseFloat(s, 64)
	return v
}

func parseInt(s string) int {
	s = strings.TrimSpace(s)
	v, _ := strconv.Atoi(s)
	return v
}
