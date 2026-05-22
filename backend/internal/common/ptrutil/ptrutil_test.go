package ptrutil

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestSafeGet(t *testing.T) {
	t.Run("nil string pointer", func(t *testing.T) {
		var ptr *string
		assert.Equal(t, "", SafeGet(ptr))
	})

	t.Run("non-nil string pointer", func(t *testing.T) {
		val := "hello"
		ptr := &val
		assert.Equal(t, "hello", SafeGet(ptr))
	})

	t.Run("nil int pointer", func(t *testing.T) {
		var ptr *int
		assert.Equal(t, 0, SafeGet(ptr))
	})
}

func TestSafeGetDefault(t *testing.T) {
	t.Run("nil string pointer with default", func(t *testing.T) {
		var ptr *string
		assert.Equal(t, "default", SafeGetDefault(ptr, "default"))
	})

	t.Run("non-nil string pointer with default", func(t *testing.T) {
		val := "hello"
		ptr := &val
		assert.Equal(t, "hello", SafeGetDefault(ptr, "default"))
	})
}

func TestAssignIfPresent(t *testing.T) {
	t.Run("nil source pointer", func(t *testing.T) {
		dest := "original"
		var src *string
		AssignIfPresent(&dest, src)
		assert.Equal(t, "original", dest)
	})

	t.Run("non-nil source pointer", func(t *testing.T) {
		dest := "original"
		srcVal := "updated"
		src := &srcVal
		AssignIfPresent(&dest, src)
		assert.Equal(t, "updated", dest)
	})

	t.Run("nil destination pointer", func(t *testing.T) {
		var dest *string
		srcVal := "updated"
		src := &srcVal
		// Should not panic
		assert.NotPanics(t, func() {
			AssignIfPresent(dest, src)
		})
	})
}

func TestAssignPtrIfPresent(t *testing.T) {
	t.Run("nil source pointer", func(t *testing.T) {
		orig := "original"
		var dest *string = &orig
		var src *string
		AssignPtrIfPresent(&dest, src)
		assert.Equal(t, "original", *dest)
	})

	t.Run("non-nil source pointer", func(t *testing.T) {
		orig := "original"
		var dest *string = &orig
		srcVal := "updated"
		src := &srcVal
		AssignPtrIfPresent(&dest, src)
		assert.Equal(t, "updated", *dest)
	})

	t.Run("nil destination pointer", func(t *testing.T) {
		var dest **string
		srcVal := "updated"
		src := &srcVal
		assert.NotPanics(t, func() {
			AssignPtrIfPresent(dest, src)
		})
	})
}
