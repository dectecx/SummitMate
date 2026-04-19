package weather

import "time"

// WeatherRecord 對應 DB weather_data 資料表
type WeatherRecord struct {
	ID        string     `json:"id"`
	Location  string     `json:"location"`
	StartTime time.Time  `json:"start_time"`
	EndTime   time.Time  `json:"end_time"`
	Wx        string     `json:"wx"`
	Temp      float64    `json:"temp"`
	PoP       int        `json:"pop"`
	MinTemp   float64    `json:"min_temp"`
	MaxTemp   float64    `json:"max_temp"`
	Humidity  float64    `json:"humidity"`
	WindSpeed float64    `json:"wind_speed"`
	MinAT     float64    `json:"min_at"`
	MaxAT     float64    `json:"max_at"`
	IssueTime *time.Time `json:"issue_time,omitempty"`
	FetchedAt time.Time  `json:"fetched_at"`
}
