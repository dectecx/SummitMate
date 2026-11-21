package weather

import (
	"context"
	"errors"
	"math"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"summitmate/internal/platform/apperror"
)

type fakeUpstream struct {
	calls atomic.Int32
	err   error
	block chan struct{} // when set, Fetch waits for it to close
	lastQ Query
}

func (u *fakeUpstream) Fetch(_ context.Context, q Query) (Forecast, error) {
	u.calls.Add(1)
	u.lastQ = q
	if u.block != nil {
		<-u.block
	}
	if u.err != nil {
		return Forecast{}, u.err
	}
	return Forecast{Latitude: q.Lat, Longitude: q.Lng, Timezone: "Asia/Taipei", Daily: []Day{{Date: "2026-01-01"}}}, nil
}

func newTestService(up Upstream) (*Service, *fakeClock) {
	clk := &fakeClock{t: time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC)}
	s := NewService(up, newMemoryCache(10, StaleTTL, clk.Now))
	s.now = clk.Now
	return s, clk
}

func f64(v float64) *float64 { return &v }
func ip(v int) *int          { return &v }

func TestServiceCacheHitMissExpiry(t *testing.T) {
	up := &fakeUpstream{}
	s, clk := newTestService(up)
	q := Query{Lat: 23.4, Lng: 121.0, Elevation: f64(3000), Days: 3}

	f, err := s.Forecast(context.Background(), q)
	require.NoError(t, err)
	assert.Equal(t, clk.Now(), f.FetchedAt)
	assert.EqualValues(t, 1, up.calls.Load())

	// Same rounded key: hit (lat/lng 2 decimals, elevation 100 m).
	_, err = s.Forecast(context.Background(), Query{Lat: 23.404, Lng: 120.996, Elevation: f64(3040), Days: 3})
	require.NoError(t, err)
	assert.EqualValues(t, 1, up.calls.Load())

	// Different days / elevation bucket: miss.
	_, _ = s.Forecast(context.Background(), Query{Lat: 23.4, Lng: 121.0, Elevation: f64(3000), Days: 4})
	_, _ = s.Forecast(context.Background(), Query{Lat: 23.4, Lng: 121.0, Elevation: f64(3100), Days: 3})
	_, _ = s.Forecast(context.Background(), Query{Lat: 23.4, Lng: 121.0, Days: 3})
	assert.EqualValues(t, 4, up.calls.Load())

	// The upstream is asked for the rounded values the key stands for.
	assert.Nil(t, up.lastQ.Elevation)

	// After the fresh TTL the entry is refreshed.
	clk.Advance(FreshTTL)
	_, err = s.Forecast(context.Background(), q)
	require.NoError(t, err)
	assert.EqualValues(t, 5, up.calls.Load())
}

func TestServiceStaleOnError(t *testing.T) {
	up := &fakeUpstream{}
	s, clk := newTestService(up)
	q := Query{Lat: 23.4, Lng: 121.0, Days: 3}
	first, err := s.Forecast(context.Background(), q)
	require.NoError(t, err)

	up.err = errors.New("boom")
	clk.Advance(2 * time.Hour)
	got, err := s.Forecast(context.Background(), q)
	require.NoError(t, err, "stale value served when upstream fails")
	assert.Equal(t, first.FetchedAt, got.FetchedAt)
	assert.EqualValues(t, 2, up.calls.Load())

	clk.Advance(StaleTTL) // now older than 6h
	_, err = s.Forecast(context.Background(), q)
	ae, ok := apperror.As(err)
	require.True(t, ok)
	assert.Equal(t, 502, ae.Status)
	assert.Equal(t, "weather_unavailable", ae.Code)
}

func TestServiceUpstreamErrorWithoutCache(t *testing.T) {
	s, _ := newTestService(&fakeUpstream{err: errors.New("boom")})
	_, err := s.Forecast(context.Background(), Query{Lat: 1, Lng: 1, Days: 1})
	ae, ok := apperror.As(err)
	require.True(t, ok)
	assert.Equal(t, "weather_unavailable", ae.Code)
}

func TestServiceSingleFlight(t *testing.T) {
	up := &fakeUpstream{block: make(chan struct{})}
	s, _ := newTestService(up)
	q := Query{Lat: 23.4, Lng: 121.0, Days: 3}

	const n = 20
	var wg sync.WaitGroup
	errs := make([]error, n)
	for i := range n {
		wg.Add(1)
		go func() {
			defer wg.Done()
			_, errs[i] = s.Forecast(context.Background(), q)
		}()
	}
	// Wait until the leader is inside upstream, give followers time to join.
	require.Eventually(t, func() bool { return up.calls.Load() == 1 }, time.Second, time.Millisecond)
	time.Sleep(50 * time.Millisecond)
	close(up.block)
	wg.Wait()

	for _, err := range errs {
		require.NoError(t, err)
	}
	assert.EqualValues(t, 1, up.calls.Load())
}

func TestNewQueryValidation(t *testing.T) {
	nan, inf := math.NaN(), math.Inf(1)
	tests := []struct {
		name string
		lat  float64
		lng  float64
		elev *float64
		days *int
		code string // empty = valid
	}{
		{"valid defaults", 23.4, 121, nil, nil, ""},
		{"valid bounds", -90, 180, f64(9000), ip(16), ""},
		{"lat too high", 90.1, 0, nil, nil, "invalid_lat"},
		{"lat nan", nan, 0, nil, nil, "invalid_lat"},
		{"lat inf", inf, 0, nil, nil, "invalid_lat"},
		{"lng too low", 0, -180.1, nil, nil, "invalid_lng"},
		{"lng nan", 0, nan, nil, nil, "invalid_lng"},
		{"elevation negative", 0, 0, f64(-1), nil, "invalid_elevation"},
		{"elevation too high", 0, 0, f64(9001), nil, "invalid_elevation"},
		{"elevation inf", 0, 0, f64(inf), nil, "invalid_elevation"},
		{"days zero", 0, 0, nil, ip(0), "invalid_days"},
		{"days 17", 0, 0, nil, ip(17), "invalid_days"},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			q, err := NewQuery(tc.lat, tc.lng, tc.elev, tc.days)
			if tc.code == "" {
				require.NoError(t, err)
				if tc.days == nil {
					assert.Equal(t, DefaultDays, q.Days)
				}
				return
			}
			ae, ok := apperror.As(err)
			require.True(t, ok)
			assert.Equal(t, 400, ae.Status)
			assert.Equal(t, tc.code, ae.Code)
		})
	}
}
