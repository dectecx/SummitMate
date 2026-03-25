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
	httpClient *http.Client
}

func NewWeatherService(logger *slog.Logger, repo repository.WeatherRepository, cwaAPIKey string, locations []string) *WeatherService {
	return &WeatherService{
		logger:    logger.With("component", "weather"),
		repo:      repo,
		cwaAPIKey: cwaAPIKey,
		locations: locations,
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
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

// --- CWA API 結構體 ---

type cwaResponse struct {
	CwaOpenData struct {
		Dataset struct {
			DatasetInfo struct {
				IssueTime string `json:"IssueTime"`
			} `json:"DatasetInfo"`
			Locations struct {
				Location []struct {
					LocationName   string `json:"LocationName"`
					WeatherElement []struct {
						ElementName string `json:"ElementName"`
						Time        []struct {
							StartTime    string `json:"StartTime"`
							EndTime      string `json:"EndTime"`
							ElementValue any    `json:"ElementValue"`
						} `json:"Time"`
					} `json:"WeatherElement"`
				} `json:"Location"`
			} `json:"Locations"`
		} `json:"Dataset"`
	} `json:"cwaopendata"`
}

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

	resp, err := s.httpClient.Do(req)
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
	var root cwaResponse
	if err := json.Unmarshal(body, &root); err != nil {
		return nil, nil, fmt.Errorf("JSON 解析失敗: %w", err)
	}

	dataset := root.CwaOpenData.Dataset
	issueTimeStr := dataset.DatasetInfo.IssueTime
	var issueTime *time.Time
	if issueTimeStr != "" {
		if t, err := time.Parse(time.RFC3339, issueTimeStr); err == nil {
			issueTime = &t
		}
	}

	var rows []rawRow
	for _, loc := range dataset.Locations.Location {
		for _, el := range loc.WeatherElement {
			for _, t := range el.Time {
				startTime, err := time.Parse(time.RFC3339, t.StartTime)
				if err != nil {
					startTime, _ = time.Parse("2006-01-02T15:04:05", t.StartTime)
				}
				endTime, err := time.Parse(time.RFC3339, t.EndTime)
				if err != nil {
					endTime, _ = time.Parse("2006-01-02T15:04:05", t.EndTime)
				}

				val := extractValue(el.ElementName, t.ElementValue)

				rows = append(rows, rawRow{
					Location:    loc.LocationName,
					StartTime:   startTime,
					EndTime:     endTime,
					ElementName: el.ElementName,
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
