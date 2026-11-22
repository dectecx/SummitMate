package gearset

import (
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestValidateJSON(t *testing.T) {
	assert.NoError(t, ValidateJSON(`[]`))
	assert.NoError(t, ValidateJSON(`[{"kind":"meal","name":"飯糰","weight":180,"calories":320,"quantity":2,"day":1}]`))
	for _, bad := range []string{``, `{`, `{}`, `[1]`, `[{"kind":"x","name":"a"}]`, `[{"kind":"gear","name":"` + strings.Repeat("好", 201) + `"}]`} {
		assert.Error(t, ValidateJSON(bad), bad)
	}
	assert.NoError(t, ValidateJSON(`[{"kind":"gear","name":"`+strings.Repeat("好", 200)+`"}]`), "200 runes is fine")
}

func TestTotals(t *testing.T) {
	cal := 300.0
	items := []Item{
		{Kind: KindGear, Name: "a", Weight: 100, Quantity: 2},
		{Kind: KindGear, Name: "b", Weight: 50.5, Quantity: 1},
		{Kind: KindMeal, Name: "c", Weight: 999, Quantity: 3, Calories: &cal},
	}
	w, g, m := Totals(items)
	assert.Equal(t, 250.5, w)
	assert.Equal(t, 2, g)
	assert.Equal(t, 1, m)
	require.NoError(t, ValidateAll(items, true))
	assert.Error(t, ValidateAll(nil, true))
	assert.NoError(t, ValidateAll(nil, false))
}
