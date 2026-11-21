// Package weather serves cached daily forecasts proxied from Open-Meteo.
// Layering: Handler -> Service (validation, cache, single-flight) -> Upstream (HTTP client).
package weather

import (
	"context"
	"time"
)

// Day is one forecast day.
type Day struct {
	Date                        string // YYYY-MM-DD in the location's timezone
	WeatherCode                 int    // WMO code
	TempMax                     float64
	TempMin                     float64
	PrecipitationProbabilityMax *int
	PrecipitationSum            float64
	WindSpeedMax                float64
	WindGustsMax                *float64
}

// Forecast is the upstream data plus the time we fetched it.
type Forecast struct {
	Latitude  float64
	Longitude float64
	Elevation *float64
	Timezone  string
	FetchedAt time.Time
	Daily     []Day
}

// Query is a validated forecast request.
type Query struct {
	Lat       float64
	Lng       float64
	Elevation *float64 // metres
	Days      int
}

// Upstream fetches a forecast from an external provider.
type Upstream interface {
	Fetch(ctx context.Context, q Query) (Forecast, error)
}

// Cache stores forecasts by key. Implementations must be safe for concurrent use and bounded.
type Cache interface {
	Get(key string) (Forecast, bool)
	Set(key string, f Forecast)
}
