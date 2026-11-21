package server

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"summitmate/internal/auth"
	"summitmate/internal/explore"
	"summitmate/internal/sync"
	"summitmate/internal/weather"
)

func newTestRouter() http.Handler {
	tm := auth.NewTokenManager("test-secret-test-secret-test-secret-123", time.Minute)
	// Services are nil on purpose: these tests never get past authentication or validation.
	return NewRouter(Options{
		Auth: auth.NewHandler(nil), Sync: sync.NewHandler(nil), Tokens: tm,
		MaxBodyBytes: 1 << 10, RequestTimeout: time.Second,
	})
}

func do(h http.Handler, method, path, body string) *httptest.ResponseRecorder {
	req := httptest.NewRequest(method, path, strings.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)
	return rec
}

func TestHealthIsPublic(t *testing.T) {
	rec := do(newTestRouter(), http.MethodGet, "/api/v1/health", "")
	assert.Equal(t, http.StatusOK, rec.Code)
	assert.JSONEq(t, `{"status":"ok"}`, rec.Body.String())
}

func TestExploreMountainsIsPublicButOtherRoutesAreNot(t *testing.T) {
	svc, err := explore.NewDefaultService()
	require.NoError(t, err)
	tm := auth.NewTokenManager("test-secret-test-secret-test-secret-123", time.Minute)
	h := NewRouter(Options{
		Auth: auth.NewHandler(nil), Sync: sync.NewHandler(nil), Explore: explore.NewHandler(svc), Tokens: tm,
		MaxBodyBytes: 1 << 10, RequestTimeout: time.Second,
	})

	rec := do(h, http.MethodGet, "/api/v1/explore/mountains", "") // no Authorization header
	require.Equal(t, http.StatusOK, rec.Code)
	assert.Equal(t, svc.ETag(), rec.Header().Get("ETag"))
	var body map[string]any
	require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &body))
	assert.Len(t, body["mountains"], 100)

	req := httptest.NewRequest(http.MethodGet, "/api/v1/explore/mountains", nil)
	req.Header.Set("If-None-Match", svc.ETag())
	rec = httptest.NewRecorder()
	h.ServeHTTP(rec, req)
	assert.Equal(t, http.StatusNotModified, rec.Code)
	assert.Empty(t, rec.Body.Bytes())

	for _, path := range []string{"/api/v1/sync/changes", "/api/v1/auth/me", "/api/v1/weather/forecast?lat=1&lng=1"} {
		assert.Equal(t, http.StatusUnauthorized, do(h, http.MethodGet, path, "").Code, path)
	}
}

func TestProtectedRoutesRequireAuth(t *testing.T) {
	h := newTestRouter()
	for _, tc := range []struct{ method, path string }{
		{http.MethodGet, "/api/v1/auth/me"},
		{http.MethodGet, "/api/v1/sync/changes"},
		{http.MethodPost, "/api/v1/sync/push"},
		{http.MethodGet, "/api/v1/users/search?email=a@b.co"},
		{http.MethodPost, "/api/v1/auth/change-password"},
	} {
		rec := do(h, tc.method, tc.path, "{}")
		assert.Equal(t, http.StatusUnauthorized, rec.Code, tc.path)
		var body map[string]any
		require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &body))
		assert.Equal(t, "unauthorized", body["code"])
	}
}

func TestMalformedAndOversizedBodiesAreRejected(t *testing.T) {
	h := newTestRouter()
	rec := do(h, http.MethodPost, "/api/v1/auth/login", "{not json")
	assert.Equal(t, http.StatusBadRequest, rec.Code)

	rec = do(h, http.MethodPost, "/api/v1/auth/login", `{"email":"a@b.co","password":"`+strings.Repeat("x", 2000)+`"}`)
	assert.Equal(t, http.StatusRequestEntityTooLarge, rec.Code)
}

func TestInvalidQueryParamIsBadRequest(t *testing.T) {
	// Authenticate with a real token, then send a bad `since`.
	tm := auth.NewTokenManager("test-secret-test-secret-test-secret-123", time.Minute)
	tok, err := tm.NewAccessToken("2d1d0a1e-5c0f-4a5e-8a43-0c0f0b1a1111")
	require.NoError(t, err)
	h := NewRouter(Options{Auth: auth.NewHandler(nil), Sync: sync.NewHandler(nil), Tokens: tm, MaxBodyBytes: 1 << 10, RequestTimeout: time.Second})
	req := httptest.NewRequest(http.MethodGet, "/api/v1/sync/changes?since=yesterday", nil)
	req.Header.Set("Authorization", "Bearer "+tok)
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, req)
	assert.Equal(t, http.StatusBadRequest, rec.Code)
}

type fakeForecaster struct{ got weather.Query }

func (f *fakeForecaster) Forecast(_ context.Context, q weather.Query) (weather.Forecast, error) {
	f.got = q
	elev := 3000.0
	prob := 20
	return weather.Forecast{
		Latitude: 23.44, Longitude: 121.04, Elevation: &elev, Timezone: "Asia/Taipei",
		FetchedAt: time.Date(2026, 11, 22, 1, 2, 3, 0, time.UTC),
		Daily: []weather.Day{{Date: "2026-11-22", WeatherCode: 3, TempMax: 11.1, TempMin: 2, PrecipitationProbabilityMax: &prob,
			PrecipitationSum: 0, WindSpeedMax: 11.7}},
	}, nil
}

func TestWeatherForecastRoute(t *testing.T) {
	tm := auth.NewTokenManager("test-secret-test-secret-test-secret-123", time.Minute)
	fake := &fakeForecaster{}
	h := NewRouter(Options{Auth: auth.NewHandler(nil), Sync: sync.NewHandler(nil), Weather: weather.NewHandler(fake),
		Tokens: tm, MaxBodyBytes: 1 << 10, RequestTimeout: time.Second})
	const path = "/api/v1/weather/forecast?lat=23.4&lng=121&elevation=3000&days=3"

	rec := do(h, http.MethodGet, path, "")
	assert.Equal(t, http.StatusUnauthorized, rec.Code)

	tok, err := tm.NewAccessToken("2d1d0a1e-5c0f-4a5e-8a43-0c0f0b1a1111")
	require.NoError(t, err)
	get := func(p string) *httptest.ResponseRecorder {
		req := httptest.NewRequest(http.MethodGet, p, nil)
		req.Header.Set("Authorization", "Bearer "+tok)
		rec := httptest.NewRecorder()
		h.ServeHTTP(rec, req)
		return rec
	}

	rec = get(path)
	require.Equal(t, http.StatusOK, rec.Code, rec.Body.String())
	assert.JSONEq(t, `{"latitude":23.44,"longitude":121.04,"elevation":3000,"timezone":"Asia/Taipei",
"fetched_at":"2026-11-22T01:02:03Z","daily":[{"date":"2026-11-22","weather_code":3,"temp_max":11.1,"temp_min":2,
"precipitation_probability_max":20,"precipitation_sum":0,"wind_speed_max":11.7,"wind_gusts_max":null}]}`, rec.Body.String())
	assert.Equal(t, 3, fake.got.Days)
	assert.Equal(t, 3000.0, *fake.got.Elevation)

	// Default days, strict validation (400 for out-of-range and NaN).
	require.Equal(t, http.StatusOK, get("/api/v1/weather/forecast?lat=1&lng=2").Code)
	assert.Equal(t, weather.DefaultDays, fake.got.Days)
	for _, q := range []string{"lat=91&lng=0", "lat=NaN&lng=0", "lat=0&lng=Inf", "lat=0&lng=0&days=17", "lat=0&lng=0&elevation=-5", "lng=0", "lat=abc&lng=0"} {
		assert.Equal(t, http.StatusBadRequest, get("/api/v1/weather/forecast?"+q).Code, q)
	}
}
