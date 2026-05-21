package weather

import (
	"context"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5"
	"summitmate/internal/database"
)

// WeatherRepository 定義天氣資料存取介面。
type WeatherRepository interface {
	ReplaceAll(ctx context.Context, records []WeatherRecord) error
	ListAll(ctx context.Context) ([]WeatherRecord, error)
	ListByLocation(ctx context.Context, location string) ([]WeatherRecord, error)
}

type weatherRepository struct {
	db database.DB
}

func NewWeatherRepository(db database.DB) WeatherRepository {
	return &weatherRepository{db: db}
}

// ReplaceAll 以 Transaction 方式進行 UPSERT 寫入，並清除過期舊資料，保證服務平滑無縫與資料一致性
func (r *weatherRepository) ReplaceAll(ctx context.Context, records []WeatherRecord) error {
	db := database.GetQuerier(ctx, r.db)

	if len(records) == 0 {
		return nil
	}

	// 1. 使用 pgx.Batch 批次執行 UPSERT，保證 location, start_time, end_time 有衝突時以最新資料覆蓋，防止 Unique 衝突
	batch := &pgx.Batch{}
	now := time.Now()

	query := `
		INSERT INTO weather_data (
			location, start_time, end_time, wx, temp, pop,
			min_temp, max_temp, humidity, wind_speed, min_at, max_at,
			issue_time, fetched_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
		ON CONFLICT (location, start_time, end_time) DO UPDATE SET
			wx = EXCLUDED.wx,
			temp = EXCLUDED.temp,
			pop = EXCLUDED.pop,
			min_temp = EXCLUDED.min_temp,
			max_temp = EXCLUDED.max_temp,
			humidity = EXCLUDED.humidity,
			wind_speed = EXCLUDED.wind_speed,
			min_at = EXCLUDED.min_at,
			max_at = EXCLUDED.max_at,
			issue_time = EXCLUDED.issue_time,
			fetched_at = EXCLUDED.fetched_at
	`

	for _, rec := range records {
		batch.Queue(query,
			rec.Location, rec.StartTime, rec.EndTime,
			rec.Wx, rec.Temp, rec.PoP,
			rec.MinTemp, rec.MaxTemp, rec.Humidity,
			rec.WindSpeed, rec.MinAT, rec.MaxAT,
			rec.IssueTime, now,
		)
	}

	br := db.SendBatch(ctx, batch)
	defer br.Close()

	for i := 0; i < len(records); i++ {
		if _, err := br.Exec(); err != nil {
			return fmt.Errorf("execute batch upsert at index %d: %w", i, err)
		}
	}

	// 2. 清理已經過期的歷史天氣預報資料 (例如結束時間早於 24 小時前)
	cutoff := now.Add(-24 * time.Hour)
	_, _ = db.Exec(ctx, "DELETE FROM weather_data WHERE end_time < $1", cutoff)

	return nil
}

// ListAll 取得所有天氣資料
func (r *weatherRepository) ListAll(ctx context.Context) ([]WeatherRecord, error) {
	db := database.GetQuerier(ctx, r.db)
	rows, err := db.Query(ctx,
		`SELECT id, location, start_time, end_time, wx, temp, pop, min_temp, max_temp, humidity, wind_speed, min_at, max_at, issue_time, fetched_at
		 FROM weather_data ORDER BY location, start_time`)
	if err != nil {
		return nil, fmt.Errorf("query all weather data: %w", err)
	}
	defer rows.Close()

	var results []WeatherRecord
	for rows.Next() {
		var rec WeatherRecord
		if err := rows.Scan(
			&rec.ID, &rec.Location, &rec.StartTime, &rec.EndTime,
			&rec.Wx, &rec.Temp, &rec.PoP,
			&rec.MinTemp, &rec.MaxTemp, &rec.Humidity,
			&rec.WindSpeed, &rec.MinAT, &rec.MaxAT,
			&rec.IssueTime, &rec.FetchedAt,
		); err != nil {
			return nil, fmt.Errorf("scan weather record row: %w", err)
		}
		results = append(results, rec)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate weather rows: %w", err)
	}
	return results, nil
}

// ListByLocation 取得特定地點的天氣資料
func (r *weatherRepository) ListByLocation(ctx context.Context, location string) ([]WeatherRecord, error) {
	db := database.GetQuerier(ctx, r.db)
	rows, err := db.Query(ctx,
		`SELECT id, location, start_time, end_time, wx, temp, pop, min_temp, max_temp, humidity, wind_speed, min_at, max_at, issue_time, fetched_at
		 FROM weather_data WHERE location = $1 ORDER BY start_time`, location)
	if err != nil {
		return nil, fmt.Errorf("query weather data for location %s: %w", location, err)
	}
	defer rows.Close()

	var results []WeatherRecord
	for rows.Next() {
		var rec WeatherRecord
		if err := rows.Scan(
			&rec.ID, &rec.Location, &rec.StartTime, &rec.EndTime,
			&rec.Wx, &rec.Temp, &rec.PoP,
			&rec.MinTemp, &rec.MaxTemp, &rec.Humidity,
			&rec.WindSpeed, &rec.MinAT, &rec.MaxAT,
			&rec.IssueTime, &rec.FetchedAt,
		); err != nil {
			return nil, fmt.Errorf("scan weather record row for location %s: %w", location, err)
		}
		results = append(results, rec)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate weather rows for location %s: %w", location, err)
	}
	return results, nil
}
