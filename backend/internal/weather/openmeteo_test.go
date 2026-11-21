package weather

import (
	"context"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

const okBody = `{"latitude":23.44,"longitude":121.04,"elevation":3000.0,"timezone":"Asia/Taipei",
"daily":{"time":["2026-11-22","2026-11-23"],"weather_code":[1,53],"temperature_2m_max":[11.1,13.7],
"temperature_2m_min":[2.0,2.4],"precipitation_probability_max":[2,null],"precipitation_sum":[0.0,1.3],
"wind_speed_10m_max":[11.7,13.0],"wind_gusts_10m_max":[41.8,null]}}`

func serve(t *testing.T, status int, body string, check func(*http.Request)) *OpenMeteo {
	t.Helper()
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if check != nil {
			check(r)
		}
		w.WriteHeader(status)
		_, _ = w.Write([]byte(body))
	}))
	t.Cleanup(srv.Close)
	return NewOpenMeteo(srv.URL)
}

func TestOpenMeteoSuccess(t *testing.T) {
	c := serve(t, 200, okBody, func(r *http.Request) {
		q := r.URL.Query()
		assert.Equal(t, "23.4", q.Get("latitude"))
		assert.Equal(t, "121", q.Get("longitude"))
		assert.Equal(t, "3000", q.Get("elevation"))
		assert.Equal(t, "auto", q.Get("timezone"))
		assert.Equal(t, "2", q.Get("forecast_days"))
		assert.Equal(t, dailyVariables, q.Get("daily"))
		assert.Equal(t, "summitmate-backend", r.UserAgent())
	})
	f, err := c.Fetch(context.Background(), Query{Lat: 23.4, Lng: 121, Elevation: f64(3000), Days: 2})
	require.NoError(t, err)
	assert.Equal(t, "Asia/Taipei", f.Timezone)
	require.NotNil(t, f.Elevation)
	assert.Equal(t, 3000.0, *f.Elevation)
	require.Len(t, f.Daily, 2)
	d0, d1 := f.Daily[0], f.Daily[1]
	assert.Equal(t, "2026-11-22", d0.Date)
	assert.Equal(t, 1, d0.WeatherCode)
	assert.Equal(t, 11.1, d0.TempMax)
	assert.Equal(t, 2.0, d0.TempMin)
	assert.Equal(t, 2, *d0.PrecipitationProbabilityMax)
	assert.Equal(t, 41.8, *d0.WindGustsMax)
	assert.Nil(t, d1.PrecipitationProbabilityMax)
	assert.Nil(t, d1.WindGustsMax)
	assert.Equal(t, 1.3, d1.PrecipitationSum)
}

func TestOpenMeteoOmitsElevationWhenUnset(t *testing.T) {
	c := serve(t, 200, okBody, func(r *http.Request) { assert.False(t, r.URL.Query().Has("elevation")) })
	_, err := c.Fetch(context.Background(), Query{Lat: 1, Lng: 2, Days: 2})
	require.NoError(t, err)
}

func TestOpenMeteoFailures(t *testing.T) {
	tests := []struct {
		name   string
		status int
		body   string
	}{
		{"non-200", 500, `{"error":true,"reason":"x"}`},
		{"rate limited", 429, ``},
		{"malformed json", 200, `{not json`},
		{"empty object", 200, `{}`},
		{"mismatched lengths", 200, strings.Replace(okBody, `"weather_code":[1,53]`, `"weather_code":[1]`, 1)},
		{"missing required value", 200, strings.Replace(okBody, `"temperature_2m_max":[11.1,13.7]`, `"temperature_2m_max":[11.1,null]`, 1)},
		{"bad date", 200, strings.Replace(okBody, `2026-11-23`, `tomorrow`, 1)},
		{"more days than asked", 200, okBody},
		{"oversized body", 200, `{"timezone":"` + strings.Repeat("x", maxResponseSize) + `"}`},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			days := 2
			if tc.name == "more days than asked" {
				days = 1
			}
			_, err := serve(t, tc.status, tc.body, nil).Fetch(context.Background(), Query{Lat: 1, Lng: 2, Days: days})
			assert.Error(t, err)
		})
	}
}

func TestOpenMeteoUnreachable(t *testing.T) {
	srv := httptest.NewServer(http.NotFoundHandler())
	url := srv.URL
	srv.Close()
	_, err := NewOpenMeteo(url).Fetch(context.Background(), Query{Lat: 1, Lng: 2, Days: 1})
	assert.Error(t, err)
}
