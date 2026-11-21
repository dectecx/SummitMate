package weather

import (
	"fmt"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
)

type fakeClock struct{ t time.Time }

func (c *fakeClock) Now() time.Time          { return c.t }
func (c *fakeClock) Advance(d time.Duration) { c.t = c.t.Add(d) }

func TestMemoryCacheExpiryAndBound(t *testing.T) {
	clk := &fakeClock{t: time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC)}
	c := newMemoryCache(3, time.Hour, clk.Now)

	c.Set("a", Forecast{Timezone: "a"})
	got, ok := c.Get("a")
	assert.True(t, ok)
	assert.Equal(t, "a", got.Timezone)

	clk.Advance(time.Hour)
	_, ok = c.Get("a")
	assert.False(t, ok, "expired entries are not returned")

	// Oldest is evicted when full.
	for i := range 4 {
		c.Set(fmt.Sprint("k", i), Forecast{})
		clk.Advance(time.Minute)
	}
	assert.Len(t, c.entries, 3)
	_, ok = c.Get("k0")
	assert.False(t, ok)
	_, ok = c.Get("k3")
	assert.True(t, ok)

	// Expired entries are dropped before live ones.
	clk.Advance(57 * time.Minute) // k1 expired, k2/k3 not
	c.Set("new", Forecast{})
	_, ok = c.Get("k3")
	assert.True(t, ok)
	_, ok = c.Get("k2")
	assert.True(t, ok)
	assert.Len(t, c.entries, 3)
}
