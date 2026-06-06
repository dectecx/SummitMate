package ptrutil

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestSafeGet(t *testing.T) {
	t.Run("Given nil string pointer, When calling SafeGet, Then it handles nil value gracefully", func(t *testing.T) {
		var ptr *string
		assert.Equal(t, "", SafeGet(ptr))
	})

	t.Run("Given non-nil string pointer, When calling SafeGet, Then it handles nil value gracefully", func(t *testing.T) {
		val := "hello"
		ptr := &val
		assert.Equal(t, "hello", SafeGet(ptr))
	})

	t.Run("Given nil int pointer, When calling SafeGet, Then it handles nil value gracefully", func(t *testing.T) {
		var ptr *int
		assert.Equal(t, 0, SafeGet(ptr))
	})
}

func TestSafeGetDefault(t *testing.T) {
	t.Run("Given nil string pointer with default, When calling SafeGetDefault, Then it handles nil value gracefully", func(t *testing.T) {
		var ptr *string
		assert.Equal(t, "default", SafeGetDefault(ptr, "default"))
	})

	t.Run("Given non-nil string pointer with default, When calling SafeGetDefault, Then it handles nil value gracefully", func(t *testing.T) {
		val := "hello"
		ptr := &val
		assert.Equal(t, "hello", SafeGetDefault(ptr, "default"))
	})
}

func TestAssignIfPresent(t *testing.T) {
	t.Run("Given nil source pointer, When calling AssignIfPresent, Then it handles nil value gracefully", func(t *testing.T) {
		dest := "original"
		var src *string
		AssignIfPresent(&dest, src)
		assert.Equal(t, "original", dest)
	})

	t.Run("Given non-nil source pointer, When calling AssignIfPresent, Then it handles nil value gracefully", func(t *testing.T) {
		dest := "original"
		srcVal := "updated"
		src := &srcVal
		AssignIfPresent(&dest, src)
		assert.Equal(t, "updated", dest)
	})

	t.Run("Given nil destination pointer, When calling AssignIfPresent, Then it handles nil value gracefully", func(t *testing.T) {
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
	t.Run("Given nil source pointer, When calling AssignPtrIfPresent, Then it handles nil value gracefully", func(t *testing.T) {
		orig := "original"
		var dest *string = &orig
		var src *string
		AssignPtrIfPresent(&dest, src)
		assert.Equal(t, "original", *dest)
	})

	t.Run("Given non-nil source pointer, When calling AssignPtrIfPresent, Then it handles nil value gracefully", func(t *testing.T) {
		orig := "original"
		var dest *string = &orig
		srcVal := "updated"
		src := &srcVal
		AssignPtrIfPresent(&dest, src)
		assert.Equal(t, "updated", *dest)
	})

	t.Run("Given nil destination pointer, When calling AssignPtrIfPresent, Then it handles nil value gracefully", func(t *testing.T) {
		var dest **string
		srcVal := "updated"
		src := &srcVal
		assert.NotPanics(t, func() {
			AssignPtrIfPresent(dest, src)
		})
	})
}
