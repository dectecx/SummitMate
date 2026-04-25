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

// ReplaceAll 以 Transaction 方式先清除舊資料再寫入新資料
func (r *weatherRepository) ReplaceAll(ctx context.Context, records []WeatherRecord) error {
	db := database.GetQuerier(ctx, r.db)

	tx, ok := db.(pgx.Tx)
	if !ok {
		return database.WithTransaction(ctx, r.db, func(txCtx context.Context) error {
			return r.ReplaceAll(txCtx, records)
		})
	}

	// 清除舊資料
	if _, err := tx.Exec(ctx, "DELETE FROM weather_data"); err != nil {
		return fmt.Errorf("clear old weather data: %w", err)
	}

	// 寫入新資料 (使用 CopyFrom 批次寫入)
	columnNames := []string{
		"location", "start_time", "end_time", "wx", "temp", "pop",
		"min_temp", "max_temp", "humidity", "wind_speed", "min_at", "max_at",
		"issue_time", "fetched_at",
	}

	now := time.Now()
	copyRows := make([][]any, len(records))
	for i, rec := range records {
		copyRows[i] = []any{
			rec.Location, rec.StartTime, rec.EndTime,
			rec.Wx, rec.Temp, rec.PoP,
			rec.MinTemp, rec.MaxTemp, rec.Humidity,
			rec.WindSpeed, rec.MinAT, rec.MaxAT,
			rec.IssueTime, now,
		}
	}

	_, err := tx.CopyFrom(
		ctx,
		pgx.Identifier{"weather_data"},
		columnNames,
		pgx.CopyFromRows(copyRows),
	)
	if err != nil {
		return fmt.Errorf("copy weather records to database: %w", err)
	}

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
