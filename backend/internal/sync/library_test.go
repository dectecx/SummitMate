package sync

import (
	"encoding/json"
	"fmt"
	"strings"
	"testing"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestLibraryItemOwnerLifecycle(t *testing.T) {
	pool := testPool(t)
	s := NewService(pool)
	alice := newUser(t, pool, "alice")
	id := uuid.New()

	res := mustPush(t, s, alice, upsert("library_items", id, map[string]any{
		"kind": "gear", "name": "睡袋", "category": "sleep", "weight": 900.0,
	}))
	require.Equal(t, StatusApplied, res[0].Status, res[0].Message)
	assert.Equal(t, alice.String(), res[0].Row["user_id"])
	assert.Equal(t, "gear", res[0].Row["kind"])

	// kind is immutable; other fields change.
	res = mustPush(t, s, alice, upsert("library_items", id, map[string]any{"kind": "meal", "weight": 850.0, "note": "冬季"}))
	require.Equal(t, StatusApplied, res[0].Status, res[0].Message)
	assert.Equal(t, "gear", res[0].Row["kind"])
	assert.EqualValues(t, 850, res[0].Row["weight"])
	assert.Equal(t, "冬季", res[0].Row["note"])

	ch := pullAll(t, s, alice, nil)
	require.Len(t, ch.Rows["library_items"], 1)

	res = mustPush(t, s, alice, del("library_items", id))
	assert.Equal(t, StatusApplied, res[0].Status)
	ch = pullAll(t, s, alice, nil)
	require.Len(t, ch.Rows["library_items"], 1)
	assert.NotNil(t, ch.Rows["library_items"][0]["deleted_at"], "tombstone is pulled")

	res = mustPush(t, s, alice, upsert("library_items", id, map[string]any{"name": "x"}), del("library_items", id))
	assert.Equal(t, StatusGone, res[0].Status)
	assert.Equal(t, StatusGone, res[1].Status)
}

func TestLibraryItemValidation(t *testing.T) {
	pool := testPool(t)
	s := NewService(pool)
	alice := newUser(t, pool, "alice")
	other := uuid.New()

	res := mustPush(t, s, alice,
		upsert("library_items", uuid.New(), map[string]any{"kind": "tool", "name": "x"}),
		upsert("library_items", uuid.New(), map[string]any{"name": "no kind"}),
		upsert("library_items", uuid.New(), map[string]any{"kind": "gear", "weight": -1.0}),
		upsert("library_items", uuid.New(), map[string]any{"kind": "meal", "calories": -5.0}),
		upsert("library_items", uuid.New(), map[string]any{"kind": "gear", "user_id": other.String()}),
		upsert("library_items", uuid.New(), map[string]any{"kind": "gear", "trip_id": other.String()}),
	)
	for i, r := range res {
		assert.Equal(t, StatusInvalid, r.Status, "op %d: %s", i, r.Message)
	}
	assert.Contains(t, res[0].Message, "kind")
	assert.Empty(t, pullAll(t, s, alice, nil).Rows["library_items"])
}

func TestLibraryAndTemplatesAreOwnerOnly(t *testing.T) {
	pool := testPool(t)
	s := NewService(pool)
	alice := newUser(t, pool, "alice")
	bob := newUser(t, pool, "bob")
	lib, tpl := uuid.New(), uuid.New()

	mustPush(t, s, alice,
		upsert("library_items", lib, map[string]any{"kind": "gear", "name": "帳篷"}),
		upsert("templates", tpl, map[string]any{"title": "三天兩夜"}))

	res := mustPush(t, s, bob,
		upsert("library_items", lib, map[string]any{"name": "hijack"}),
		del("library_items", lib),
		upsert("templates", tpl, map[string]any{"title": "hijack"}),
		del("templates", tpl))
	for i, r := range res {
		assert.Equal(t, StatusForbidden, r.Status, "op %d", i)
	}

	ch := pullAll(t, s, bob, nil)
	assert.Empty(t, ch.Rows["library_items"])
	assert.Empty(t, ch.Rows["templates"])

	ch = pullAll(t, s, alice, nil)
	require.Len(t, ch.Rows["library_items"], 1)
	assert.Equal(t, "帳篷", ch.Rows["library_items"][0]["name"])
	require.Len(t, ch.Rows["templates"], 1)
	assert.Equal(t, "三天兩夜", ch.Rows["templates"][0]["title"])
}

func TestTemplateItemsValidation(t *testing.T) {
	pool := testPool(t)
	s := NewService(pool)
	alice := newUser(t, pool, "alice")

	good := `[{"kind":"gear","name":"睡袋","category":"sleep","weight":900,"quantity":1,"note":""},` +
		`{"kind":"meal","name":"飯糰","category":"lunch","weight":180,"calories":320,"quantity":2,"day":1,"note":""}]`
	id := uuid.New()
	res := mustPush(t, s, alice, upsert("templates", id, map[string]any{"title": "ok", "items": good}))
	require.Equal(t, StatusApplied, res[0].Status, res[0].Message)
	assert.Equal(t, good, res[0].Row["items"])

	many := make([]map[string]any, 301)
	for i := range many {
		many[i] = map[string]any{"kind": "gear", "name": fmt.Sprint("g", i)}
	}
	tooMany, _ := json.Marshal(many)
	exactly, _ := json.Marshal(many[:300])

	bad := map[string]string{
		"not json":   `{oops`,
		"not array":  `{"kind":"gear","name":"x"}`,
		"scalar":     `"hi"`,
		"null elem":  `[null]`,
		"str elem":   `["x"]`,
		"bad kind":   `[{"kind":"tool","name":"x"}]`,
		"no name":    `[{"kind":"gear"}]`,
		"empty name": `[{"kind":"gear","name":""}]`,
		"num name":   `[{"kind":"gear","name":5}]`,
		"long name":  `[{"kind":"gear","name":"` + strings.Repeat("a", 201) + `"}]`,
		"neg weight": `[{"kind":"gear","name":"x","weight":-1}]`,
		"str weight": `[{"kind":"gear","name":"x","weight":"1"}]`,
		"neg cal":    `[{"kind":"meal","name":"x","calories":-1}]`,
		"frac qty":   `[{"kind":"gear","name":"x","quantity":1.5}]`,
		"day zero":   `[{"kind":"meal","name":"x","day":0}]`,
		"301 items":  string(tooMany),
	}
	for name, items := range bad {
		r := mustPush(t, s, alice, upsert("templates", uuid.New(), map[string]any{"items": items}))
		assert.Equal(t, StatusInvalid, r[0].Status, name)
		assert.NotEmpty(t, r[0].Message, name)
	}
	// Updating an existing template with bad items is rejected and leaves it unchanged.
	r := mustPush(t, s, alice, upsert("templates", id, map[string]any{"items": `{`}))
	assert.Equal(t, StatusInvalid, r[0].Status)

	r = mustPush(t, s, alice, upsert("templates", uuid.New(), map[string]any{"items": string(exactly)}), upsert("templates", uuid.New(), map[string]any{"items": "[]"}))
	assert.Equal(t, StatusApplied, r[0].Status, r[0].Message)
	assert.Equal(t, StatusApplied, r[1].Status)
	// title-only patch (no items) is fine.
	r = mustPush(t, s, alice, upsert("templates", id, map[string]any{"title": "renamed"}))
	assert.Equal(t, StatusApplied, r[0].Status)
	assert.Equal(t, good, r[0].Row["items"])
}

func TestLibraryPushIsIdempotent(t *testing.T) {
	pool := testPool(t)
	s := NewService(pool)
	alice := newUser(t, pool, "alice")
	op := upsert("library_items", uuid.New(), map[string]any{"kind": "meal", "name": "泡麵", "calories": 450.0})
	first := mustPush(t, s, alice, op)
	again := mustPush(t, s, alice, op)
	assert.Equal(t, first[0], again[0])

	// Another user replaying the same op_id gets an invalid result and no row.
	bob := newUser(t, pool, "bob")
	r := mustPush(t, s, bob, op)
	assert.Equal(t, StatusInvalid, r[0].Status)
	assert.Empty(t, pullAll(t, s, bob, nil).Rows["library_items"])
}
