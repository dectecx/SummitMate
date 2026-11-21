package cache

import (
	"context"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
)

func TestMemoryCache(t *testing.T) {
	t.Run("Given default context, When calling MemoryCache, Then it should perform successfully", func(t *testing.T) {
		c := NewMemoryCache[string]()
		testCache(t, c)
	})
}

func testCache(t *testing.T, c Cache[string]) {
	ctx := context.Background()
	key := Key{Module: ModuleAuth, Domain: "test", ID: "123"}

	t.Run("Given SetAndGet, When calling testCache, Then it behaves as expected", func(t *testing.T) {
		err := c.Set(ctx, key, "value", time.Minute)
		assert.NoError(t, err)

		val, err := c.Get(ctx, key)
		assert.NoError(t, err)
		assert.Equal(t, "value", val)
	})

	t.Run("Given GetNotFound, When calling testCache, Then it behaves as expected", func(t *testing.T) {
		_, err := c.Get(ctx, Key{Module: ModuleAuth, Domain: "test", ID: "not-exists"})
		assert.ErrorIs(t, err, ErrKeyNotFound)
	})

	t.Run("Given Delete, When calling testCache, Then it behaves as expected", func(t *testing.T) {
		err := c.Set(ctx, key, "value", time.Minute)
		assert.NoError(t, err)

		err = c.Delete(ctx, key)
		assert.NoError(t, err)

		_, err = c.Get(ctx, key)
		assert.ErrorIs(t, err, ErrKeyNotFound)
	})

	t.Run("Given Expiration, When calling testCache, Then it behaves as expected", func(t *testing.T) {
		if _, ok := c.(*memoryCache[string]); ok {
			err := c.Set(ctx, key, "value", time.Millisecond*100)
			assert.NoError(t, err)

			time.Sleep(time.Millisecond * 200)

			_, err = c.Get(ctx, key)
			assert.ErrorIs(t, err, ErrKeyNotFound)
		}
	})
}

func TestIncrement(t *testing.T) {
	ctx := context.Background()
	key := Key{Module: ModuleAuth, Domain: "test", ID: "counter"}

	t.Run("Given MemoryCache Increment String, When calling Increment, Then it behaves as expected", func(t *testing.T) {
		c := NewMemoryCache[string]()
		val, err := c.Increment(ctx, key, time.Minute)
		assert.NoError(t, err)
		assert.Equal(t, int64(1), val)

		// Verify Get returns string
		s, err := c.Get(ctx, key)
		assert.NoError(t, err)
		assert.Equal(t, "1", s)

		val, err = c.Increment(ctx, key, time.Minute)
		assert.NoError(t, err)
		assert.Equal(t, int64(2), val)
	})

	t.Run("Given MemoryCache Increment Int64, When calling Increment, Then it behaves as expected", func(t *testing.T) {
		c := NewMemoryCache[int64]()
		val, err := c.Increment(ctx, key, time.Minute)
		assert.NoError(t, err)
		assert.Equal(t, int64(1), val)

		// Verify Get returns int64
		i, err := c.Get(ctx, key)
		assert.NoError(t, err)
		assert.Equal(t, int64(1), i)
	})
}
