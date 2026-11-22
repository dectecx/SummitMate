package sharedsets_test

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"math/rand"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"golang.org/x/crypto/bcrypt"

	"summitmate/internal/auth"
	"summitmate/internal/platform/ratelimit"
	"summitmate/internal/server"
	"summitmate/internal/sharedsets"
	"summitmate/internal/sync"
)

// Needs a real PostgreSQL; set TEST_DATABASE_URL to run (see internal/sync/integration_test.go).
// Each test gets its own schema, dropped afterwards.

func testPool(t *testing.T) *pgxpool.Pool {
	t.Helper()
	url := os.Getenv("TEST_DATABASE_URL")
	if url == "" {
		t.Skip("TEST_DATABASE_URL not set")
	}
	ctx := context.Background()
	admin, err := pgxpool.New(ctx, url)
	require.NoError(t, err)
	schema := fmt.Sprintf("t_%d", rand.Int63())
	_, err = admin.Exec(ctx, "CREATE SCHEMA "+schema)
	require.NoError(t, err)
	cfg, err := pgxpool.ParseConfig(url)
	require.NoError(t, err)
	cfg.ConnConfig.RuntimeParams["search_path"] = schema + ",pg_catalog"
	pool, err := pgxpool.NewWithConfig(ctx, cfg)
	require.NoError(t, err)
	ddl, err := os.ReadFile("../../migrations/000001_init_schema.up.sql")
	require.NoError(t, err)
	_, err = pool.Exec(ctx, string(ddl))
	require.NoError(t, err)
	t.Cleanup(func() {
		pool.Close()
		_, _ = admin.Exec(ctx, "DROP SCHEMA "+schema+" CASCADE")
		admin.Close()
	})
	return pool
}

type env struct {
	h      http.Handler
	tokens *auth.TokenManager
	pool   *pgxpool.Pool
}

func newEnv(t *testing.T) *env {
	pool := testPool(t)
	tm := auth.NewTokenManager("test-secret-test-secret-test-secret-123", time.Minute)
	svc := sharedsets.NewService(sharedsets.NewPgRepository(pool), sharedsets.Options{
		BcryptCost: bcrypt.MinCost, WrongKeys: ratelimit.NewMemory(3, time.Minute),
	})
	h := server.NewRouter(server.Options{
		Auth: auth.NewHandler(nil), Sync: sync.NewHandler(nil), SharedSets: sharedsets.NewHandler(svc),
		Tokens: tm, MaxBodyBytes: 1 << 20, RequestTimeout: 10 * time.Second,
	})
	return &env{h: h, tokens: tm, pool: pool}
}

func (e *env) user(t *testing.T, name string) string {
	var id uuid.UUID
	require.NoError(t, e.pool.QueryRow(context.Background(), `INSERT INTO users (email, password_hash, display_name, is_verified)
		VALUES ($1, 'x', $2, TRUE) RETURNING id`, name+"@example.com", name).Scan(&id))
	tok, err := e.tokens.NewAccessToken(id.String())
	require.NoError(t, err)
	return tok
}

func (e *env) do(method, path, token, key string, body any) *httptest.ResponseRecorder {
	var rd bytes.Buffer
	if body != nil {
		_ = json.NewEncoder(&rd).Encode(body)
	}
	req := httptest.NewRequest(method, "/api/v1"+path, &rd)
	req.Header.Set("Content-Type", "application/json")
	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}
	if key != "" {
		req.Header.Set("X-Access-Key", key)
	}
	rec := httptest.NewRecorder()
	e.h.ServeHTTP(rec, req)
	return rec
}

func decode(t *testing.T, rec *httptest.ResponseRecorder) map[string]any {
	var m map[string]any
	require.NoError(t, json.Unmarshal(rec.Body.Bytes(), &m), rec.Body.String())
	return m
}

func body(title, vis, key string) map[string]any {
	b := map[string]any{"title": title, "visibility": vis, "items": []map[string]any{
		{"kind": "gear", "name": "睡袋", "category": "sleep", "weight": 900, "quantity": 1, "note": ""},
		{"kind": "gear", "name": "水壺", "category": "cook", "weight": 100, "quantity": 2, "note": ""},
		{"kind": "meal", "name": "飯糰", "category": "lunch", "weight": 180, "calories": 320, "quantity": 2, "day": 1, "note": ""},
	}}
	if key != "" {
		b["access_key"] = key
	}
	return b
}

func TestSharedSetsHTTPMatrix(t *testing.T) {
	e := newEnv(t)
	alice, bob := e.user(t, "alice"), e.user(t, "bob")

	// create requires a token
	assert.Equal(t, 401, e.do("POST", "/shared-sets", "", "", body("x", "public", "")).Code)
	assert.Equal(t, 400, e.do("POST", "/shared-sets", alice, "", body("x", "protected", "")).Code)

	rec := e.do("POST", "/shared-sets", alice, "", body("Alpine 三天", "public", ""))
	require.Equal(t, 201, rec.Code, rec.Body.String())
	pub := decode(t, rec)
	assert.Equal(t, "alice", pub["author_name"])
	assert.EqualValues(t, 1100, pub["total_weight"])
	assert.EqualValues(t, 2, pub["gear_count"])
	assert.EqualValues(t, 1, pub["meal_count"])
	assert.Equal(t, true, pub["mine"])
	assert.NotContains(t, pub, "items")
	assert.NotContains(t, pub, "access_key_hash")

	rec = e.do("POST", "/shared-sets", alice, "", body("受保護_100%", "protected", "key123"))
	require.Equal(t, 201, rec.Code, rec.Body.String())
	prot := decode(t, rec)
	rec = e.do("POST", "/shared-sets", alice, "", body("私人備份", "private", ""))
	require.Equal(t, 201, rec.Code)
	priv := decode(t, rec)

	// public list: anonymous sees public + protected, never private
	rec = e.do("GET", "/shared-sets?scope=public", "", "", nil)
	require.Equal(t, 200, rec.Code, rec.Body.String())
	page := decode(t, rec)
	items := page["items"].([]any)
	require.Len(t, items, 2)
	assert.Equal(t, prot["id"], items[0].(map[string]any)["id"], "newest first")
	assert.Equal(t, false, items[0].(map[string]any)["mine"])
	assert.NotContains(t, page, "next_cursor")
	// with token, mine is filled
	page = decode(t, e.do("GET", "/shared-sets?scope=public", alice, "", nil))
	assert.Equal(t, true, page["items"].([]any)[0].(map[string]any)["mine"])
	// invalid token on an optional-auth route is rejected, not treated as anonymous
	assert.Equal(t, 401, e.do("GET", "/shared-sets?scope=public", "garbage", "", nil).Code)

	// search, wildcards are literal
	page = decode(t, e.do("GET", "/shared-sets?scope=public&q=alpine", "", "", nil))
	assert.Len(t, page["items"], 1)
	page = decode(t, e.do("GET", "/shared-sets?scope=public&q=100%25", "", "", nil))
	assert.Len(t, page["items"], 1)
	page = decode(t, e.do("GET", "/shared-sets?scope=public&q=%25", "", "", nil))
	assert.Len(t, page["items"], 1, "only the title containing a literal percent")
	page = decode(t, e.do("GET", "/shared-sets?scope=public&q=_", "", "", nil))
	assert.Len(t, page["items"], 1, "only the title containing a literal underscore")

	// mine requires auth and includes private
	assert.Equal(t, 401, e.do("GET", "/shared-sets?scope=mine", "", "", nil).Code)
	page = decode(t, e.do("GET", "/shared-sets?scope=mine", alice, "", nil))
	assert.Len(t, page["items"], 3)
	page = decode(t, e.do("GET", "/shared-sets?scope=mine", bob, "", nil))
	assert.Len(t, page["items"], 0)
	assert.Equal(t, 400, e.do("GET", "/shared-sets?scope=all", "", "", nil).Code)
	assert.Equal(t, 400, e.do("GET", "/shared-sets?scope=public&limit=51", "", "", nil).Code)

	// keyset pagination
	p1 := decode(t, e.do("GET", "/shared-sets?scope=mine&limit=2", alice, "", nil))
	require.Len(t, p1["items"], 2)
	cur, ok := p1["next_cursor"].(string)
	require.True(t, ok)
	p2 := decode(t, e.do("GET", "/shared-sets?scope=mine&limit=2&cursor="+cur, alice, "", nil))
	require.Len(t, p2["items"], 1)
	assert.Equal(t, pub["id"], p2["items"].([]any)[0].(map[string]any)["id"])
	assert.NotContains(t, p2, "next_cursor")

	// detail matrix
	pubID, protID, privID := pub["id"].(string), prot["id"].(string), priv["id"].(string)
	rec = e.do("GET", "/shared-sets/"+pubID, "", "", nil)
	require.Equal(t, 200, rec.Code)
	d := decode(t, rec)
	assert.Len(t, d["items"], 3)
	assert.Equal(t, "meal", d["items"].([]any)[2].(map[string]any)["kind"])

	assert.Equal(t, 404, e.do("GET", "/shared-sets/"+privID, "", "", nil).Code)
	assert.Equal(t, 404, e.do("GET", "/shared-sets/"+privID, bob, "", nil).Code)
	assert.Equal(t, 200, e.do("GET", "/shared-sets/"+privID, alice, "", nil).Code)
	assert.Equal(t, 404, e.do("GET", "/shared-sets/"+uuid.NewString(), "", "", nil).Code)

	rec = e.do("GET", "/shared-sets/"+protID, bob, "", nil)
	assert.Equal(t, 403, rec.Code)
	assert.Equal(t, "access_key_required", decode(t, rec)["code"])
	rec = e.do("GET", "/shared-sets/"+protID, bob, "wrong", nil)
	assert.Equal(t, 403, rec.Code)
	assert.Equal(t, "invalid_access_key", decode(t, rec)["code"])
	assert.Equal(t, 200, e.do("GET", "/shared-sets/"+protID, bob, "key123", nil).Code)
	assert.Equal(t, 200, e.do("GET", "/shared-sets/"+protID, "", "key123", nil).Code)
	assert.Equal(t, 200, e.do("GET", "/shared-sets/"+protID, alice, "", nil).Code, "owner needs no key")

	// rate limit: 3 wrong keys then 429 (the counter was not reset by the earlier success? it was, so start fresh)
	for i := 0; i < 3; i++ {
		assert.Equal(t, 403, e.do("GET", "/shared-sets/"+protID, "", "bad", nil).Code)
	}
	rec = e.do("GET", "/shared-sets/"+protID, "", "bad", nil)
	assert.Equal(t, 429, rec.Code)
	assert.Equal(t, "too_many_requests", decode(t, rec)["code"])

	// delete: auth required, owner only, soft
	assert.Equal(t, 401, e.do("DELETE", "/shared-sets/"+pubID, "", "", nil).Code)
	assert.Equal(t, 404, e.do("DELETE", "/shared-sets/"+pubID, bob, "", nil).Code)
	assert.Equal(t, 204, e.do("DELETE", "/shared-sets/"+pubID, alice, "", nil).Code)
	assert.Equal(t, 404, e.do("DELETE", "/shared-sets/"+pubID, alice, "", nil).Code)
	assert.Equal(t, 404, e.do("GET", "/shared-sets/"+pubID, alice, "", nil).Code)
	var n int
	require.NoError(t, e.pool.QueryRow(context.Background(), `SELECT count(*) FROM shared_sets WHERE deleted_at IS NOT NULL`).Scan(&n))
	assert.Equal(t, 1, n)
	page = decode(t, e.do("GET", "/shared-sets?scope=public", "", "", nil))
	assert.Len(t, page["items"], 1)

	// the stored key is a bcrypt hash
	var hash string
	require.NoError(t, e.pool.QueryRow(context.Background(), `SELECT access_key_hash FROM shared_sets WHERE id = $1`, protID).Scan(&hash))
	assert.NoError(t, bcrypt.CompareHashAndPassword([]byte(hash), []byte("key123")))
}
