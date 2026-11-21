package ratelimit

import (
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
)

func TestMemoryLimiterWindowAndReset(t *testing.T) {
	now := time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC)
	l := NewMemory(2, time.Minute).(*memory)
	l.now = func() time.Time { return now }

	assert.True(t, l.Allow("k"))
	l.Record("k")
	l.Record("k")
	assert.False(t, l.Allow("k"))
	assert.True(t, l.Allow("other"), "keys are independent")

	now = now.Add(61 * time.Second)
	assert.True(t, l.Allow("k"), "events expire after the window")

	l.Record("k")
	l.Record("k")
	l.Reset("k")
	assert.True(t, l.Allow("k"))
}
