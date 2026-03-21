package repository

import (
	"context"

	"github.com/jackc/pgx/v5/pgxpool"

	"summitmate/internal/model"
)

// WeatherRepository 定義天氣資料存取介面。
type WeatherRepository interface {
	ReplaceAll(ctx context.Context, records []model.WeatherRecord) error
	ListAll(ctx context.Context) ([]model.WeatherRecord, error)
	ListByLocation(ctx context.Context, location string) ([]model.WeatherRecord, error)
}

type weatherRepository struct {
	pool *pgxpool.Pool
}

func NewWeatherRepository(pool *pgxpool.Pool) WeatherRepository {
	return &weatherRepository{pool: pool}
}

// ReplaceAll 以 Transaction 方式先清除舊資料再寫入新資料
func (r *weatherRepository) ReplaceAll(ctx context.Context, records []model.WeatherRecord) error {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback(ctx)

	// 清除舊資料
	if _, err := tx.Exec(ctx, "DELETE FROM weather_data"); err != nil {
		return err
	}

	// 寫入新資料
	for _, rec := range records {
		_, err := tx.Exec(ctx,
			`INSERT INTO weather_data (location, start_time, end_time, wx, temp, pop, min_temp, max_temp, humidity, wind_speed, min_at, max_at, issue_time, fetched_at)
			 VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, NOW())`,
			rec.Location, rec.StartTime, rec.EndTime,
			rec.Wx, rec.Temp, rec.PoP,
			rec.MinTemp, rec.MaxTemp, rec.Humidity,
			rec.WindSpeed, rec.MinAT, rec.MaxAT, rec.IssueTime,
		)
		if err != nil {
			return err
		}
	}

	return tx.Commit(ctx)
}

// ListAll 取得所有天氣資料
func (r *weatherRepository) ListAll(ctx context.Context) ([]model.WeatherRecord, error) {
	rows, err := r.pool.Query(ctx,
		`SELECT id, location, start_time, end_time, wx, temp, pop, min_temp, max_temp, humidity, wind_speed, min_at, max_at, issue_time, fetched_at
		 FROM weather_data ORDER BY location, start_time`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var results []model.WeatherRecord
	for rows.Next() {
		var rec model.WeatherRecord
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
func (r *weatherRepository) ListByLocation(ctx context.Context, location string) ([]model.WeatherRecord, error) {
	rows, err := r.pool.Query(ctx,
		`SELECT id, location, start_time, end_time, wx, temp, pop, min_temp, max_temp, humidity, wind_speed, min_at, max_at, issue_time, fetched_at
		 FROM weather_data WHERE location = $1 ORDER BY start_time`, location)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var results []model.WeatherRecord
	for rows.Next() {
		var rec model.WeatherRecord
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
