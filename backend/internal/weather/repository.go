package weather

import (
	"context"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// WeatherRepository 定義天氣資料存取介面。
type WeatherRepository interface {
	ReplaceAll(ctx context.Context, records []WeatherRecord) error
	ListAll(ctx context.Context) ([]WeatherRecord, error)
	ListByLocation(ctx context.Context, location string) ([]WeatherRecord, error)
}

type weatherRepository struct {
	pool *pgxpool.Pool
}

func NewWeatherRepository(pool *pgxpool.Pool) WeatherRepository {
	return &weatherRepository{pool: pool}
}

// ReplaceAll 以 Transaction 方式先清除舊資料再寫入新資料
func (r *weatherRepository) ReplaceAll(ctx context.Context, records []WeatherRecord) error {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	// 清除舊資料
	if _, err := tx.Exec(ctx, "DELETE FROM weather_data"); err != nil {
		return err
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

	_, err = tx.CopyFrom(
		ctx,
		pgx.Identifier{"weather_data"},
		columnNames,
		pgx.CopyFromRows(copyRows),
	)
	if err != nil {
		return err
	}

	return tx.Commit(ctx)
}

// ListAll 取得所有天氣資料
func (r *weatherRepository) ListAll(ctx context.Context) ([]WeatherRecord, error) {
	rows, err := r.pool.Query(ctx,
		`SELECT id, location, start_time, end_time, wx, temp, pop, min_temp, max_temp, humidity, wind_speed, min_at, max_at, issue_time, fetched_at
		 FROM weather_data ORDER BY location, start_time`)
	if err != nil {
		return nil, err
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
			return nil, err
		}
		results = append(results, rec)
	}
	return results, nil
}

// ListByLocation 取得特定地點的天氣資料
func (r *weatherRepository) ListByLocation(ctx context.Context, location string) ([]WeatherRecord, error) {
	rows, err := r.pool.Query(ctx,
		`SELECT id, location, start_time, end_time, wx, temp, pop, min_temp, max_temp, humidity, wind_speed, min_at, max_at, issue_time, fetched_at
		 FROM weather_data WHERE location = $1 ORDER BY start_time`, location)
	if err != nil {
		return nil, err
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
			return nil, err
		}
		results = append(results, rec)
	}
	return results, nil
}
