package friends_test

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"math/rand"
	"net/http"
	"net/http/httptest"
	"os"
	gosync "sync"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"summitmate/internal/auth"
	"summitmate/internal/friends"
	"summitmate/internal/platform/mail"
	"summitmate/internal/platform/ratelimit"
	"summitmate/internal/server"
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

type person struct {
	id    uuid.UUID
	token string
}

type env struct {
	h    http.Handler
	tm   *auth.TokenManager
	pool *pgxpool.Pool
	auth *auth.Service
}

func newEnv(t *testing.T, limit int) *env {
	pool := testPool(t)
	tm := auth.NewTokenManager("test-secret-test-secret-test-secret-123", time.Minute)
	authSvc, err := auth.NewService(auth.NewPgRepository(pool), tm, mail.LogMailer{}, auth.Options{BcryptCost: 4})
	require.NoError(t, err)
	svc := friends.NewService(friends.NewPgRepository(pool), friends.Options{Requests: ratelimit.NewMemory(limit, time.Hour)})
	h := server.NewRouter(server.Options{
		Auth: auth.NewHandler(authSvc), Sync: sync.NewHandler(sync.NewService(pool)), Friends: friends.NewHandler(svc),
		Tokens: tm, MaxBodyBytes: 1 << 20, RequestTimeout: 10 * time.Second,
	})
	return &env{h: h, tm: tm, pool: pool, auth: authSvc}
}

func (e *env) user(t *testing.T, name string) person {
	var id uuid.UUID
	require.NoError(t, e.pool.QueryRow(context.Background(), `INSERT INTO users (email, password_hash, display_name, avatar, is_verified)
		VALUES ($1, 'x', $2, '🐻', TRUE) RETURNING id`, name+"@example.com", name).Scan(&id))
	tok, err := e.tm.NewAccessToken(id.String())
	require.NoError(t, err)
	return person{id: id, token: tok}
}

func (e *env) do(method, path, token string, body any) *httptest.ResponseRecorder {
	var rd bytes.Buffer
	if body != nil {
		_ = json.NewEncoder(&rd).Encode(body)
	}
	req := httptest.NewRequest(method, "/api/v1"+path, &rd)
	req.Header.Set("Content-Type", "application/json")
	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
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

func (e *env) send(from, to person) *httptest.ResponseRecorder {
	return e.do("POST", "/friends/requests", from.token, map[string]any{"user_id": to.id})
}

func (e *env) list(t *testing.T, p person) map[string]any {
	rec := e.do("GET", "/friends", p.token, nil)
	require.Equal(t, 200, rec.Code, rec.Body.String())
	return decode(t, rec)
}

func TestFriendFlow(t *testing.T) {
	e := newEnv(t, 1000)
	alice, bob, carol := e.user(t, "alice"), e.user(t, "bob"), e.user(t, "carol")

	assert.Equal(t, 401, e.do("GET", "/friends", "", nil).Code)
	assert.Equal(t, 401, e.do("POST", "/friends/requests", "", map[string]any{"user_id": bob.id}).Code)
	empty := e.list(t, alice)
	assert.Equal(t, map[string]any{"friends": []any{}, "incoming": []any{}, "outgoing": []any{}}, empty)

	rec := e.send(alice, alice)
	assert.Equal(t, 400, rec.Code)
	assert.Equal(t, "cannot_friend_self", decode(t, rec)["code"])
	rec = e.send(alice, person{id: uuid.New(), token: alice.token})
	assert.Equal(t, 404, rec.Code)
	assert.Equal(t, "user_not_found", decode(t, rec)["code"])
	assert.Equal(t, 400, e.do("POST", "/friends/requests", alice.token, map[string]any{"user_id": "nope"}).Code)

	rec = e.send(alice, bob)
	require.Equal(t, 201, rec.Code, rec.Body.String())
	sent := decode(t, rec)
	assert.Equal(t, "pending", sent["status"])
	reqID := sent["request_id"].(string)
	assert.Equal(t, 200, e.send(alice, bob).Code)
	assert.Equal(t, reqID, decode(t, e.send(alice, bob))["request_id"])

	la, lb := e.list(t, alice), e.list(t, bob)
	out := la["outgoing"].([]any)
	require.Len(t, out, 1)
	assert.Equal(t, map[string]any{"id": bob.id.String(), "display_name": "bob", "avatar": "🐻"}, out[0].(map[string]any)["user"])
	assert.Equal(t, reqID, out[0].(map[string]any)["request_id"])
	assert.NotEmpty(t, out[0].(map[string]any)["created_at"])
	in := lb["incoming"].([]any)
	require.Len(t, in, 1)
	assert.Equal(t, alice.id.String(), in[0].(map[string]any)["user"].(map[string]any)["id"])
	assert.NotContains(t, e.do("GET", "/friends", bob.token, nil).Body.String(), "@example.com")

	// only the addressee accepts
	assert.Equal(t, 403, e.do("POST", "/friends/requests/"+reqID+"/accept", alice.token, nil).Code)
	assert.Equal(t, 403, e.do("POST", "/friends/requests/"+reqID+"/accept", carol.token, nil).Code)
	assert.Equal(t, 404, e.do("POST", "/friends/requests/"+uuid.NewString()+"/accept", bob.token, nil).Code)
	assert.Equal(t, 401, e.do("POST", "/friends/requests/"+reqID+"/accept", "", nil).Code)
	require.Equal(t, 204, e.do("POST", "/friends/requests/"+reqID+"/accept", bob.token, nil).Code)
	assert.Equal(t, 404, e.do("POST", "/friends/requests/"+reqID+"/accept", bob.token, nil).Code)

	for _, p := range []struct {
		viewer, other person
		name          string
	}{{alice, bob, "bob"}, {bob, alice, "alice"}} {
		l := e.list(t, p.viewer)
		fs := l["friends"].([]any)
		require.Len(t, fs, 1)
		f := fs[0].(map[string]any)
		assert.Equal(t, p.other.id.String(), f["user_id"])
		assert.Equal(t, p.name, f["display_name"])
		assert.NotEmpty(t, f["since"])
		assert.Empty(t, l["incoming"])
		assert.Empty(t, l["outgoing"])
	}
	rec = e.send(bob, alice)
	assert.Equal(t, 200, rec.Code)
	assert.Equal(t, "accepted", decode(t, rec)["status"])

	// an accepted friendship is not removable as a request; unfriend is idempotent and works from either side
	assert.Equal(t, 404, e.do("DELETE", "/friends/requests/"+reqID, alice.token, nil).Code)
	assert.Equal(t, 204, e.do("DELETE", "/friends/"+bob.id.String(), alice.token, nil).Code)
	assert.Equal(t, 204, e.do("DELETE", "/friends/"+bob.id.String(), alice.token, nil).Code)
	assert.Equal(t, 204, e.do("DELETE", "/friends/"+uuid.NewString(), alice.token, nil).Code)
	assert.Equal(t, 401, e.do("DELETE", "/friends/"+bob.id.String(), "", nil).Code)
	assert.Empty(t, e.list(t, bob)["friends"])

	// decline and cancel delete the row, so the request can be sent again
	rec = e.send(alice, bob)
	require.Equal(t, 201, rec.Code)
	id2 := decode(t, rec)["request_id"].(string)
	assert.Equal(t, 404, e.do("DELETE", "/friends/requests/"+id2, carol.token, nil).Code)
	assert.Equal(t, 204, e.do("DELETE", "/friends/requests/"+id2, bob.token, nil).Code)
	assert.Equal(t, 404, e.do("DELETE", "/friends/requests/"+id2, bob.token, nil).Code)
	rec = e.send(alice, bob)
	require.Equal(t, 201, rec.Code)
	assert.Equal(t, 204, e.do("DELETE", "/friends/requests/"+decode(t, rec)["request_id"].(string), alice.token, nil).Code)
	assert.Empty(t, e.list(t, bob)["incoming"])

	// crossing requests become friends at once
	rec = e.send(alice, carol)
	require.Equal(t, 201, rec.Code)
	first := decode(t, rec)["request_id"]
	rec = e.send(carol, alice)
	require.Equal(t, 201, rec.Code)
	crossed := decode(t, rec)
	assert.Equal(t, "accepted", crossed["status"])
	assert.Equal(t, first, crossed["request_id"])
	assert.Len(t, e.list(t, alice)["friends"], 1)

	var rows int
	require.NoError(t, e.pool.QueryRow(context.Background(), `SELECT count(*) FROM friendships`).Scan(&rows))
	assert.Equal(t, 1, rows)
}

func TestInactiveUsersAreHiddenAndCannotBeAsked(t *testing.T) {
	e := newEnv(t, 1000)
	alice, bob, carol, dave := e.user(t, "alice"), e.user(t, "bob"), e.user(t, "carol"), e.user(t, "dave")
	require.Equal(t, 201, e.send(alice, bob).Code)
	require.Equal(t, 201, e.send(carol, alice).Code)
	_, err := e.pool.Exec(context.Background(), `UPDATE users SET is_active = FALSE WHERE id = $1`, bob.id)
	require.NoError(t, err)
	_, err = e.pool.Exec(context.Background(), `UPDATE users SET is_verified = FALSE WHERE id = $1`, carol.id)
	require.NoError(t, err)
	l := e.list(t, alice)
	assert.Empty(t, l["outgoing"])
	assert.Empty(t, l["incoming"])
	for _, u := range []person{bob, carol} {
		rec := e.send(dave, u)
		assert.Equal(t, 404, rec.Code)
		assert.Equal(t, "user_not_found", decode(t, rec)["code"])
	}
}

func TestDeletingAnAccountRemovesItsFriendships(t *testing.T) {
	e := newEnv(t, 1000)
	alice, bob, carol := e.user(t, "alice"), e.user(t, "bob"), e.user(t, "carol")
	rec := e.send(alice, bob)
	require.Equal(t, 204, e.do("POST", "/friends/requests/"+decode(t, rec)["request_id"].(string)+"/accept", bob.token, nil).Code)
	require.Equal(t, 201, e.send(carol, alice).Code)
	require.Equal(t, 201, e.send(alice, e.user(t, "dave")).Code)
	require.Equal(t, 201, e.send(bob, carol).Code)

	require.Equal(t, 204, e.do("DELETE", "/auth/me", alice.token, nil).Code)

	var n int
	require.NoError(t, e.pool.QueryRow(context.Background(),
		`SELECT count(*) FROM friendships WHERE requester_id = $1 OR addressee_id = $1`, alice.id).Scan(&n))
	assert.Zero(t, n)
	assert.Empty(t, e.list(t, bob)["friends"])
	assert.Len(t, e.list(t, bob)["outgoing"], 1, "other people's rows stay")
	assert.Empty(t, e.list(t, carol)["outgoing"])
}

func TestLimits(t *testing.T) {
	e := newEnv(t, 2)
	alice := e.user(t, "alice")
	for i := 0; i < 2; i++ {
		require.Equal(t, 201, e.send(alice, e.user(t, fmt.Sprintf("u%d", i))).Code)
	}
	rec := e.send(alice, e.user(t, "late"))
	assert.Equal(t, 429, rec.Code)
	assert.Equal(t, "too_many_requests", decode(t, rec)["code"])
	assert.Len(t, e.list(t, alice)["outgoing"], 2)
}

func TestPendingCap(t *testing.T) {
	e := newEnv(t, 1000)
	alice := e.user(t, "alice")
	_, err := e.pool.Exec(context.Background(), `
		WITH u AS (INSERT INTO users (email, password_hash, display_name, is_verified)
			SELECT 'bulk' || g || '@example.com', 'x', 'bulk' || g, TRUE FROM generate_series(1, 101) g RETURNING id)
		INSERT INTO friendships (id, requester_id, addressee_id, status)
			SELECT uuidv7(), $1, id, 'pending' FROM (SELECT id FROM u LIMIT 100) s`, alice.id)
	require.NoError(t, err)
	rec := e.send(alice, e.user(t, "one-too-many"))
	assert.Equal(t, 409, rec.Code)
	assert.Equal(t, "too_many_pending_requests", decode(t, rec)["code"])
}

func TestConcurrentCrossingRequestsKeepOneRow(t *testing.T) {
	e := newEnv(t, 1000)
	alice, bob := e.user(t, "alice"), e.user(t, "bob")
	var wg gosync.WaitGroup
	codes := make([]int, 2)
	for i, pair := range [][2]person{{alice, bob}, {bob, alice}} {
		wg.Add(1)
		go func() {
			defer wg.Done()
			codes[i] = e.send(pair[0], pair[1]).Code
		}()
	}
	wg.Wait()
	assert.Equal(t, []int{201, 201}, codes)
	var n int
	var status string
	require.NoError(t, e.pool.QueryRow(context.Background(), `SELECT count(*), min(status) FROM friendships`).Scan(&n, &status))
	assert.Equal(t, 1, n)
	assert.Equal(t, "accepted", status)
}

func TestDatabaseRejectsSelfAndDuplicatePairs(t *testing.T) {
	e := newEnv(t, 1000)
	a, b := e.user(t, "a"), e.user(t, "b")
	ctx := context.Background()
	_, err := e.pool.Exec(ctx, `INSERT INTO friendships (id, requester_id, addressee_id, status) VALUES (uuidv7(), $1, $1, 'pending')`, a.id)
	assert.Error(t, err)
	_, err = e.pool.Exec(ctx, `INSERT INTO friendships (id, requester_id, addressee_id, status) VALUES (uuidv7(), $1, $2, 'pending')`, a.id, b.id)
	require.NoError(t, err)
	_, err = e.pool.Exec(ctx, `INSERT INTO friendships (id, requester_id, addressee_id, status) VALUES (uuidv7(), $1, $2, 'pending')`, b.id, a.id)
	assert.Error(t, err, "a pair has one row whichever side asked")
	_, err = e.pool.Exec(ctx, `UPDATE friendships SET status = 'declined'`)
	assert.Error(t, err)
}
