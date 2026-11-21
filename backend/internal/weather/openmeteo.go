package weather

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"math"
	"net/http"
	"net/url"
	"strconv"
	"time"
)

const (
	// OpenMeteoURL is the public forecast endpoint (free, no API key).
	OpenMeteoURL    = "https://api.open-meteo.com/v1/forecast"
	clientTimeout   = 5 * time.Second
	maxResponseSize = 1 << 20 // 1 MiB; a 16-day daily response is a few KB
	dailyVariables  = "weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,precipitation_sum,wind_speed_10m_max,wind_gusts_10m_max"
)

// OpenMeteo is the Upstream backed by the Open-Meteo forecast API.
type OpenMeteo struct {
	baseURL string
	client  *http.Client
}

// NewOpenMeteo returns a client for baseURL (use OpenMeteoURL in production, an httptest URL in tests).
func NewOpenMeteo(baseURL string) *OpenMeteo {
	return &OpenMeteo{baseURL: baseURL, client: &http.Client{Timeout: clientTimeout}}
}

type openMeteoResponse struct {
	Latitude  *float64 `json:"latitude"`
	Longitude *float64 `json:"longitude"`
	Elevation *float64 `json:"elevation"`
	Timezone  string   `json:"timezone"`
	Daily     struct {
		Time          []string   `json:"time"`
		WeatherCode   []*float64 `json:"weather_code"`
		TempMax       []*float64 `json:"temperature_2m_max"`
		TempMin       []*float64 `json:"temperature_2m_min"`
		PrecipProbMax []*float64 `json:"precipitation_probability_max"`
		PrecipSum     []*float64 `json:"precipitation_sum"`
		WindSpeedMax  []*float64 `json:"wind_speed_10m_max"`
		WindGustsMax  []*float64 `json:"wind_gusts_10m_max"`
	} `json:"daily"`
}

// Fetch implements Upstream. FetchedAt is left zero; the Service stamps it.
func (c *OpenMeteo) Fetch(ctx context.Context, q Query) (Forecast, error) {
	v := url.Values{}
	v.Set("latitude", strconv.FormatFloat(q.Lat, 'f', -1, 64))
	v.Set("longitude", strconv.FormatFloat(q.Lng, 'f', -1, 64))
	if q.Elevation != nil {
		v.Set("elevation", strconv.FormatFloat(*q.Elevation, 'f', -1, 64))
	}
	v.Set("daily", dailyVariables)
	v.Set("timezone", "auto")
	v.Set("forecast_days", strconv.Itoa(q.Days))

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, c.baseURL+"?"+v.Encode(), nil)
	if err != nil {
		return Forecast{}, err
	}
	req.Header.Set("User-Agent", "summitmate-backend")
	req.Header.Set("Accept", "application/json")
	resp, err := c.client.Do(req)
	if err != nil {
		return Forecast{}, fmt.Errorf("open-meteo request: %w", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		_, _ = io.Copy(io.Discard, io.LimitReader(resp.Body, 4096))
		return Forecast{}, fmt.Errorf("open-meteo status %d", resp.StatusCode)
	}
	body, err := io.ReadAll(io.LimitReader(resp.Body, maxResponseSize+1))
	if err != nil {
		return Forecast{}, fmt.Errorf("open-meteo read: %w", err)
	}
	if len(body) > maxResponseSize {
		return Forecast{}, errors.New("open-meteo response too large")
	}
	return parseOpenMeteo(body, q.Days)
}

func parseOpenMeteo(body []byte, wantDays int) (Forecast, error) {
	var r openMeteoResponse
	if err := json.Unmarshal(body, &r); err != nil {
		return Forecast{}, fmt.Errorf("open-meteo decode: %w", err)
	}
	if r.Latitude == nil || r.Longitude == nil || !finite(*r.Latitude) || !finite(*r.Longitude) {
		return Forecast{}, errors.New("open-meteo response lacks coordinates")
	}
	d := r.Daily
	n := len(d.Time)
	if n == 0 || n > wantDays {
		return Forecast{}, fmt.Errorf("open-meteo returned %d days, want 1..%d", n, wantDays)
	}
	for _, l := range []int{len(d.WeatherCode), len(d.TempMax), len(d.TempMin), len(d.PrecipProbMax),
		len(d.PrecipSum), len(d.WindSpeedMax), len(d.WindGustsMax)} {
		if l != n {
			return Forecast{}, errors.New("open-meteo daily arrays have different lengths")
		}
	}
	f := Forecast{Latitude: *r.Latitude, Longitude: *r.Longitude, Timezone: r.Timezone, Daily: make([]Day, n)}
	if r.Elevation != nil && finite(*r.Elevation) {
		f.Elevation = r.Elevation
	}
	for i := range n {
		if _, err := time.Parse(time.DateOnly, d.Time[i]); err != nil {
			return Forecast{}, fmt.Errorf("open-meteo bad date %q", d.Time[i])
		}
		code, tmax, tmin := d.WeatherCode[i], d.TempMax[i], d.TempMin[i]
		psum, wind := d.PrecipSum[i], d.WindSpeedMax[i]
		for _, p := range []*float64{code, tmax, tmin, psum, wind} {
			if p == nil || !finite(*p) {
				return Forecast{}, fmt.Errorf("open-meteo missing value on day %d", i)
			}
		}
		day := Day{Date: d.Time[i], WeatherCode: int(*code), TempMax: *tmax, TempMin: *tmin, PrecipitationSum: *psum, WindSpeedMax: *wind}
		if p := d.PrecipProbMax[i]; p != nil && finite(*p) {
			v := int(math.Round(*p))
			day.PrecipitationProbabilityMax = &v
		}
		if g := d.WindGustsMax[i]; g != nil && finite(*g) {
			v := *g
			day.WindGustsMax = &v
		}
		f.Daily[i] = day
	}
	return f, nil
}

func finite(v float64) bool { return !math.IsNaN(v) && !math.IsInf(v, 0) }
