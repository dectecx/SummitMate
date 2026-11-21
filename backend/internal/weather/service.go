package weather

import (
	"context"
	"fmt"
	"log/slog"
	"math"
	"net/http"
	"sync"
	"time"

	"summitmate/internal/platform/apperror"
)

const (
	// FreshTTL is how long a cached forecast is served without asking upstream.
	FreshTTL = 30 * time.Minute
	// StaleTTL is how long a cached forecast may still be served when upstream fails.
	StaleTTL = 6 * time.Hour
	// MaxCacheEntries bounds memory use of the default cache.
	MaxCacheEntries = 1000

	DefaultDays = 7
)

var (
	ErrWeatherUnavailable = apperror.New(http.StatusBadGateway, apperror.TypeServer, "weather_unavailable", "天氣服務暫時無法使用")
	errInvalidLat         = apperror.New(http.StatusBadRequest, apperror.TypeValidation, "invalid_lat", "緯度必須介於 -90 到 90").WithParam("lat")
	errInvalidLng         = apperror.New(http.StatusBadRequest, apperror.TypeValidation, "invalid_lng", "經度必須介於 -180 到 180").WithParam("lng")
	errInvalidElevation   = apperror.New(http.StatusBadRequest, apperror.TypeValidation, "invalid_elevation", "海拔必須介於 0 到 9000 公尺").WithParam("elevation")
	errInvalidDays        = apperror.New(http.StatusBadRequest, apperror.TypeValidation, "invalid_days", "天數必須介於 1 到 16").WithParam("days")
)

// Service validates requests and serves forecasts through the cache.
type Service struct {
	upstream Upstream
	cache    Cache
	now      func() time.Time

	mu       sync.Mutex
	inflight map[string]*call
}

type call struct {
	done chan struct{}
	f    Forecast
	err  error
}

// NewService builds a Service. cache must retain entries for at least StaleTTL.
func NewService(upstream Upstream, cache Cache) *Service {
	return &Service{upstream: upstream, cache: cache, now: time.Now, inflight: map[string]*call{}}
}

// NewDefaultService uses the in-memory cache sized for production.
func NewDefaultService(upstream Upstream) *Service {
	return NewService(upstream, NewMemoryCache(MaxCacheEntries, StaleTTL))
}

// NewQuery validates raw request values. days nil means the default.
func NewQuery(lat, lng float64, elevation *float64, days *int) (Query, error) {
	if !finiteIn(lat, -90, 90) {
		return Query{}, errInvalidLat
	}
	if !finiteIn(lng, -180, 180) {
		return Query{}, errInvalidLng
	}
	if elevation != nil && !finiteIn(*elevation, 0, 9000) {
		return Query{}, errInvalidElevation
	}
	d := DefaultDays
	if days != nil {
		d = *days
	}
	if d < 1 || d > 16 {
		return Query{}, errInvalidDays
	}
	return Query{Lat: lat, Lng: lng, Elevation: elevation, Days: d}, nil
}

func finiteIn(v, lo, hi float64) bool {
	return !math.IsNaN(v) && !math.IsInf(v, 0) && v >= lo && v <= hi
}

func cacheKey(q Query) string {
	elev := "-"
	if q.Elevation != nil {
		elev = fmt.Sprint(int(math.Round(*q.Elevation/100) * 100))
	}
	return fmt.Sprintf("%.2f,%.2f,%s,%d", q.Lat, q.Lng, elev, q.Days)
}

// normalize makes the upstream request match the cache key, so a hit is exactly what a miss would fetch.
func normalize(q Query) Query {
	q.Lat = math.Round(q.Lat*100) / 100
	q.Lng = math.Round(q.Lng*100) / 100
	if q.Elevation != nil {
		e := math.Round(*q.Elevation/100) * 100
		q.Elevation = &e
	}
	return q
}

// Forecast returns a fresh cached forecast, fetches one, or falls back to a stale one.
func (s *Service) Forecast(ctx context.Context, q Query) (Forecast, error) {
	q = normalize(q)
	key := cacheKey(q)
	if f, ok := s.cache.Get(key); ok && s.now().Sub(f.FetchedAt) < FreshTTL {
		return f, nil
	}

	f, err := s.fetchShared(ctx, key, q)
	if err == nil {
		return f, nil
	}
	if stale, ok := s.cache.Get(key); ok && s.now().Sub(stale.FetchedAt) < StaleTTL {
		slog.WarnContext(ctx, "weather upstream failed, serving stale forecast", "error", err)
		return stale, nil
	}
	if ctx.Err() != nil {
		return Forecast{}, ctx.Err()
	}
	return Forecast{}, ErrWeatherUnavailable.Wrap(err)
}

// fetchShared makes concurrent identical requests share one upstream call.
func (s *Service) fetchShared(ctx context.Context, key string, q Query) (Forecast, error) {
	s.mu.Lock()
	if c, ok := s.inflight[key]; ok {
		s.mu.Unlock()
		select {
		case <-c.done:
			return c.f, c.err
		case <-ctx.Done():
			return Forecast{}, ctx.Err()
		}
	}
	c := &call{done: make(chan struct{})}
	s.inflight[key] = c
	s.mu.Unlock()

	// Detach from the leader's cancellation so followers are not failed by one client leaving;
	// the upstream client enforces its own timeout.
	c.f, c.err = s.upstream.Fetch(context.WithoutCancel(ctx), q)
	if c.err == nil {
		c.f.FetchedAt = s.now()
		s.cache.Set(key, c.f)
	}
	s.mu.Lock()
	delete(s.inflight, key)
	s.mu.Unlock()
	close(c.done)
	return c.f, c.err
}
