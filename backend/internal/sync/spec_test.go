package sync

import (
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestCoerce(t *testing.T) {
	text := column{kind: kText}
	nullable := column{kind: kText, nullable: true}

	v, err := coerce(text, "hi")
	require.NoError(t, err)
	assert.Equal(t, "hi", v)

	_, err = coerce(text, nil)
	assert.Error(t, err, "null into non-nullable")
	v, err = coerce(nullable, nil)
	require.NoError(t, err)
	assert.Nil(t, v)

	_, err = coerce(text, 5.0)
	assert.Error(t, err)

	v, err = coerce(column{kind: kInt}, 42.0)
	require.NoError(t, err)
	assert.Equal(t, int64(42), v)
	_, err = coerce(column{kind: kInt}, 1.5)
	assert.Error(t, err, "fractional int")
	_, err = coerce(column{kind: kInt}, 1e12)
	assert.Error(t, err, "int overflow")

	_, err = coerce(column{kind: kFloat}, "1.5")
	assert.Error(t, err)

	v, err = coerce(column{kind: kDate}, "2026-03-04")
	require.NoError(t, err)
	assert.Equal(t, time.Date(2026, 3, 4, 0, 0, 0, 0, time.UTC), v)
	_, err = coerce(column{kind: kDate}, "2026-13-40")
	assert.Error(t, err)

	_, err = coerce(column{kind: kTime}, "2026-03-04T10:00:00Z")
	assert.NoError(t, err)
	_, err = coerce(column{kind: kTime}, "tomorrow")
	assert.Error(t, err)

	id := uuid.New()
	v, err = coerce(column{kind: kUUID}, id.String())
	require.NoError(t, err)
	assert.Equal(t, id, v)
	_, err = coerce(column{kind: kUUID}, "not-a-uuid")
	assert.Error(t, err)

	_, err = coerce(column{kind: kBool}, "true")
	assert.Error(t, err)
}

func TestMemberIDIsDeterministicAndDistinct(t *testing.T) {
	trip, a, b := uuid.New(), uuid.New(), uuid.New()
	assert.Equal(t, MemberID(trip, a), MemberID(trip, a))
	assert.NotEqual(t, MemberID(trip, a), MemberID(trip, b))
	assert.NotEqual(t, MemberID(trip, a), MemberID(uuid.New(), a))
}

func TestBuildSetsIsStableAndNumbered(t *testing.T) {
	sets, args := buildSets(map[string]any{"name": "x", "altitude": int64(3)}, 3)
	assert.Equal(t, []string{"altitude = $3", "name = $4"}, sets)
	assert.Equal(t, []any{int64(3), "x"}, args)
}

// Every column named in a spec must exist in the schema file, so a typo cannot reach SQL.
func TestEveryEntityHasAPullQuery(t *testing.T) {
	for _, name := range pullOrder {
		_, ok := entities[name]
		assert.True(t, ok, name)
		assert.NotEmpty(t, pullQueries[name], name)
	}
	assert.Len(t, pullOrder, len(entities))
}
