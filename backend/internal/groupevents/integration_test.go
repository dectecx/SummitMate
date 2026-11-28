package groupevents_test

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"math/rand"
	"net/http"
	"net/http/httptest"
	"os"
	"strings"
	gosync "sync"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"summitmate/internal/auth"
	"summitmate/internal/groupevents"
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
	h      http.Handler
	tokens *auth.TokenManager
	pool   *pgxpool.Pool
	sync   *sync.Service
}

func newEnv(t *testing.T) *env {
	pool := testPool(t)
	tm := auth.NewTokenManager("test-secret-test-secret-test-secret-123", time.Minute)
	svc := groupevents.NewService(groupevents.NewPgRepository(pool), groupevents.Options{
		Comments: ratelimit.NewMemory(1000, time.Minute), Applications: ratelimit.NewMemory(1000, time.Minute),
		Now: func() time.Time { return time.Date(2026, 11, 22, 12, 0, 0, 0, time.UTC) },
	})
	ss := sync.NewService(pool)
	h := server.NewRouter(server.Options{
		Auth: auth.NewHandler(nil), Sync: sync.NewHandler(ss), GroupEvents: groupevents.NewHandler(svc),
		Tokens: tm, MaxBodyBytes: 1 << 20, RequestTimeout: 10 * time.Second,
	})
	return &env{h: h, tokens: tm, pool: pool, sync: ss}
}

func (e *env) user(t *testing.T, name string) person {
	var id uuid.UUID
	require.NoError(t, e.pool.QueryRow(context.Background(), `INSERT INTO users (email, password_hash, display_name, avatar, is_verified)
		VALUES ($1, 'x', $2, '🐻', TRUE) RETURNING id`, name+"@example.com", name).Scan(&id))
	tok, err := e.tokens.NewAccessToken(id.String())
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

func errCode(t *testing.T, rec *httptest.ResponseRecorder) string {
	return decode(t, rec)["code"].(string)
}

func (e *env) createTrip(t *testing.T, owner person) string {
	id := uuid.New()
	res, err := e.sync.Push(context.Background(), owner.id, []sync.Op{{
		OpID: uuid.New(), Entity: "trips", EntityID: id, Patch: map[string]any{"name": "嘉明湖", "start_date": "2026-12-05"},
	}})
	require.NoError(t, err)
	require.Equal(t, sync.StatusApplied, res[0].Status, res[0].Message)
	return id.String()
}

// memberRow returns the user's trip_members row for the trip as a sync pull delivers it to that user.
func (e *env) memberRow(t *testing.T, viewer person, trip string, user person) map[string]any {
	ch, err := e.sync.Pull(context.Background(), viewer.id, nil, 0)
	require.NoError(t, err)
	for _, m := range ch.Rows["trip_members"] {
		if m["trip_id"] == trip && m["user_id"] == user.id.String() {
			return m
		}
	}
	return nil
}

func eventBody(title string) map[string]any {
	return map[string]any{
		"title": title, "category": "hiking", "location": "台東 向陽", "start_date": "2026-12-05", "end_date": "2026-12-07",
		"max_members": 8, "approval_required": true, "description": "三天兩夜", "private_message": "集合暗號 SECRET-123",
	}
}

func (e *env) createEvent(t *testing.T, host person, body map[string]any) map[string]any {
	rec := e.do("POST", "/group-events", host.token, body)
	require.Equal(t, 201, rec.Code, rec.Body.String())
	return decode(t, rec)
}

func ids(page map[string]any) []string {
	var out []string
	for _, it := range page["items"].([]any) {
		out = append(out, it.(map[string]any)["id"].(string))
	}
	return out
}

func TestCreateAndValidation(t *testing.T) {
	e := newEnv(t)
	host, alice := e.user(t, "host"), e.user(t, "alice")
	trip := e.createTrip(t, host)

	assert.Equal(t, 401, e.do("POST", "/group-events", "", eventBody("嘉明湖三日")).Code)
	bad := func(code string, mod func(map[string]any)) {
		t.Helper()
		b := eventBody("嘉明湖三日")
		mod(b)
		rec := e.do("POST", "/group-events", host.token, b)
		assert.Equal(t, 400, rec.Code, code)
		assert.Equal(t, code, errCode(t, rec))
	}
	bad("invalid_title", func(b map[string]any) { b["title"] = "短" })
	bad("invalid_category", func(b map[string]any) { b["category"] = "x" })
	bad("invalid_dates", func(b map[string]any) { b["end_date"] = "2026-12-01" })
	bad("invalid_max_members", func(b map[string]any) { b["max_members"] = 1 })
	bad("invalid_private_message", func(b map[string]any) { b["private_message"] = strings.Repeat("字", 2001) })
	bad("invalid_snapshot", func(b map[string]any) {
		b["trip_snapshot"] = map[string]any{"name": "x", "itinerary": []map[string]any{{"day": 0, "name": "a", "altitude": 1}}}
	})
	assert.Equal(t, 400, e.do("POST", "/group-events", host.token, map[string]any{"title": "沒有其他欄位"}).Code, "missing dates and members")

	// linking a trip needs ownership
	b := eventBody("嘉明湖三日")
	b["linked_trip_id"] = trip
	rec := e.do("POST", "/group-events", alice.token, b)
	assert.Equal(t, 403, rec.Code)
	assert.Equal(t, "not_trip_owner", errCode(t, rec))
	b["linked_trip_id"] = uuid.NewString()
	assert.Equal(t, 403, e.do("POST", "/group-events", host.token, b).Code, "unknown trip")

	// a good one, with link and snapshot
	b["linked_trip_id"] = trip
	b["trip_snapshot"] = map[string]any{"name": "嘉明湖三日", "start_date": "2026-12-05", "end_date": "2026-12-07",
		"itinerary": []map[string]any{
			{"day": 1, "name": "向陽登山口", "time": "07:00", "altitude": 2300, "lat": 23.3, "lng": 121.0},
			{"day": 2, "name": "嘉明湖山屋", "time": nil, "altitude": 3310, "lat": nil, "lng": nil},
		}}
	ev := e.createEvent(t, host, b)
	assert.Equal(t, "open", ev["status"])
	assert.Equal(t, true, ev["is_host"])
	assert.Equal(t, trip, ev["linked_trip_id"])
	assert.Equal(t, "集合暗號 SECRET-123", ev["private_message"])
	assert.Equal(t, false, ev["private_message_locked"])
	assert.NotNil(t, ev["snapshot_updated_at"])
	assert.EqualValues(t, 0, ev["approved_count"])
	assert.Equal(t, map[string]any{"id": host.id.String(), "display_name": "host", "avatar": "🐻"}, ev["host"])
	snap := ev["trip_snapshot"].(map[string]any)
	assert.Len(t, snap["itinerary"], 2)
	assert.Nil(t, snap["itinerary"].([]any)[1].(map[string]any)["time"])
	assert.NotContains(t, rec.Body.String(), "@example.com")
	raw := e.do("GET", "/group-events/"+ev["id"].(string), host.token, nil).Body.String()
	assert.NotContains(t, raw, "@example.com")

	// the title was trimmed, defaults applied
	b2 := map[string]any{"title": "  只有必填欄位  ", "category": "other", "start_date": "2026-12-05", "max_members": 2}
	ev2 := e.createEvent(t, host, b2)
	assert.Equal(t, "只有必填欄位", ev2["title"])
	assert.Equal(t, true, ev2["approval_required"], "approval is on by default")
	assert.Nil(t, ev2["end_date"])
	assert.Equal(t, "", ev2["location"])
	assert.Nil(t, ev2["trip_snapshot"])
}

func TestDetailVisibilityAndPrivateMessage(t *testing.T) {
	e := newEnv(t)
	host, alice, bob, carol, dave := e.user(t, "host"), e.user(t, "alice"), e.user(t, "bob"), e.user(t, "carol"), e.user(t, "dave")
	trip := e.createTrip(t, host)
	b := eventBody("嘉明湖三日")
	b["linked_trip_id"] = trip
	ev := e.createEvent(t, host, b)
	id := ev["id"].(string)
	path := "/group-events/" + id

	// apply: alice approved, bob pending, carol rejected
	for _, u := range []person{alice, bob, carol} {
		rec := e.do("POST", path+"/apply", u.token, map[string]any{"message": "帶我去"})
		require.Equal(t, 200, rec.Code, rec.Body.String())
		assert.Equal(t, "pending", decode(t, rec)["my_status"])
	}
	apps := decode(t, e.do("GET", path+"/applications", host.token, nil))["items"].([]any)
	require.Len(t, apps, 3)
	appID := func(i int) string { return apps[i].(map[string]any)["id"].(string) }
	assert.Equal(t, 200, e.do("POST", path+"/applications/"+appID(0)+"/review", host.token, map[string]any{"approve": true}).Code)
	rec := e.do("POST", path+"/applications/"+appID(2)+"/review", host.token, map[string]any{"approve": false, "reason": "名額保留"})
	require.Equal(t, 200, rec.Code)
	assert.Equal(t, "rejected", decode(t, rec)["status"])

	get := func(p person) map[string]any {
		rec := e.do("GET", path, p.token, nil)
		require.Equal(t, 200, rec.Code, rec.Body.String())
		return decode(t, rec)
	}
	for name, c := range map[string]struct {
		who     person
		visible bool
		status  any
	}{
		"host": {host, true, nil}, "approved": {alice, true, "approved"}, "pending": {bob, false, "pending"},
		"rejected": {carol, false, "rejected"}, "stranger": {dave, false, nil}, "anonymous": {person{}, false, nil},
	} {
		d := get(c.who)
		if c.visible {
			assert.Equal(t, "集合暗號 SECRET-123", d["private_message"], name)
			assert.Equal(t, false, d["private_message_locked"], name)
		} else {
			assert.Nil(t, d["private_message"], name)
			assert.Equal(t, true, d["private_message_locked"], name)
		}
		if !c.visible {
			assert.NotContains(t, e.do("GET", path, c.who.token, nil).Body.String(), "SECRET-123", name)
		}
		if c.status != nil {
			assert.Equal(t, c.status, d["my_status"], name)
		}
		assert.Equal(t, c.who == host, d["is_host"], name)
		if c.who == host {
			assert.Equal(t, trip, d["linked_trip_id"])
		} else {
			assert.Nil(t, d["linked_trip_id"], name+" never sees the linked trip id")
		}
	}
	assert.Equal(t, "名額保留", get(carol)["my_rejection_reason"])
	assert.Nil(t, get(bob)["my_rejection_reason"])
	assert.EqualValues(t, 1, get(dave)["approved_count"])

	// the private message is never in a list, for anyone
	for _, p := range []person{host, alice, {}} {
		for _, scope := range []string{"all", "upcoming", "popular"} {
			rec := e.do("GET", "/group-events?scope="+scope, p.token, nil)
			require.Equal(t, 200, rec.Code)
			assert.NotContains(t, rec.Body.String(), "SECRET-123")
			assert.NotContains(t, rec.Body.String(), "private_message")
			assert.NotContains(t, rec.Body.String(), trip, "no linked trip id in lists")
		}
	}

	// invalid token on optional-auth routes is rejected
	assert.Equal(t, 401, e.do("GET", path, "garbage", nil).Code)
	assert.Equal(t, 401, e.do("GET", "/group-events", "garbage", nil).Code)
	assert.Equal(t, 401, e.do("GET", path+"/comments", "garbage", nil).Code)
	assert.Equal(t, 404, e.do("GET", "/group-events/"+uuid.NewString(), "", nil).Code)
	assert.Equal(t, 404, e.do("GET", "/group-events/"+uuid.NewString(), alice.token, nil).Code)
	rec = e.do("GET", "/group-events/"+uuid.NewString(), "", nil)
	assert.Equal(t, "group_event_not_found", errCode(t, rec))
}

func TestListScopesSearchAndPaging(t *testing.T) {
	e := newEnv(t)
	host, alice, bob := e.user(t, "host"), e.user(t, "alice"), e.user(t, "bob")

	mk := func(title, start, loc string) string {
		b := eventBody(title)
		b["start_date"], b["end_date"], b["location"] = start, nil, loc
		return e.createEvent(t, host, b)["id"].(string)
	}
	past := mk("過去的活動呀", "2026-11-01", "宜蘭")
	soon := mk("近期的活動呀", "2026-11-25", "南投")
	later := mk("很久以後的活動", "2026-12-25", "100%_純粹")
	last := mk("最後建立的活動", "2026-12-01", "花蓮")
	cancelled := mk("取消的活動呀", "2026-12-02", "苗栗")
	require.Equal(t, 204, e.do("DELETE", "/group-events/"+cancelled, host.token, nil).Code)

	list := func(p person, q string) map[string]any {
		rec := e.do("GET", "/group-events"+q, p.token, nil)
		require.Equal(t, 200, rec.Code, rec.Body.String())
		return decode(t, rec)
	}
	// all: newest first, no cancelled; default scope is all
	assert.Equal(t, []string{last, later, soon, past}, ids(list(person{}, "")))
	assert.Equal(t, []string{last, later, soon, past}, ids(list(person{}, "?scope=all")))
	// upcoming: soonest start first, expired and cancelled gone
	assert.Equal(t, []string{soon, last, later}, ids(list(person{}, "?scope=upcoming")))

	// popular: most approved people first, then newest (nobody has joined yet)
	assert.Equal(t, []string{last, later, soon, past}, ids(list(person{}, "?scope=popular")))
	p1 := list(person{}, "?scope=popular&limit=3")
	assert.Equal(t, []string{last, later, soon}, ids(p1))
	cur := p1["next_cursor"].(string)
	p2 := list(person{}, "?scope=popular&limit=3&cursor="+cur)
	assert.Equal(t, []string{past}, ids(p2))
	assert.NotContains(t, p2, "next_cursor")

	// keyset paging over all, newest first
	a1 := list(person{}, "?limit=3")
	assert.Equal(t, []string{last, later, soon}, ids(a1))
	a2 := list(person{}, "?limit=3&cursor="+a1["next_cursor"].(string))
	assert.Equal(t, []string{past}, ids(a2))
	assert.NotContains(t, a2, "next_cursor")
	u1 := list(person{}, "?scope=upcoming&limit=2")
	assert.Equal(t, []string{soon, last}, ids(u1))
	u2 := list(person{}, "?scope=upcoming&limit=2&cursor="+u1["next_cursor"].(string))
	assert.Equal(t, []string{later}, ids(u2))
	// a cursor from another scope is refused
	assert.Equal(t, 400, e.do("GET", "/group-events?scope=popular&cursor="+a1["next_cursor"].(string), "", nil).Code)

	// search: title or location, case-insensitive, wildcards are literal
	assert.Equal(t, []string{soon}, ids(list(person{}, "?q="+"%E8%BF%91%E6%9C%9F")))
	assert.Equal(t, []string{last}, ids(list(person{}, "?q=%E8%8A%B1%E8%93%AE")), "location match")
	assert.Equal(t, []string{later}, ids(list(person{}, "?q=100%25")))
	assert.Equal(t, []string{later}, ids(list(person{}, "?q=%25")))
	assert.Equal(t, []string{later}, ids(list(person{}, "?q=_")))
	assert.Empty(t, ids(list(person{}, "?q=%5C")))

	// validation
	assert.Equal(t, 400, e.do("GET", "/group-events?scope=mine", "", nil).Code)
	assert.Equal(t, 400, e.do("GET", "/group-events?limit=51", "", nil).Code)
	assert.Equal(t, 400, e.do("GET", "/group-events?limit=0", "", nil).Code)
	assert.Equal(t, 400, e.do("GET", "/group-events?cursor=zzz", "", nil).Code)

	// joined / hosting need a token
	assert.Equal(t, 401, e.do("GET", "/group-events?scope=joined", "", nil).Code)
	assert.Equal(t, 401, e.do("GET", "/group-events?scope=hosting", "", nil).Code)
	for _, id := range []string{soon, later} {
		require.Equal(t, 200, e.do("POST", "/group-events/"+id+"/apply", alice.token, map[string]any{}).Code)
	}
	assert.Equal(t, 200, e.do("POST", "/group-events/"+last+"/apply", bob.token, nil).Code, "an empty body is fine")
	assert.ElementsMatch(t, []string{later, soon}, ids(list(alice, "?scope=joined")))
	assert.Equal(t, []string{last}, ids(list(bob, "?scope=joined")))
	// withdrawing drops it from joined
	require.Equal(t, 204, e.do("DELETE", "/group-events/"+soon+"/apply", alice.token, nil).Code)
	assert.Equal(t, []string{later}, ids(list(alice, "?scope=joined")))
	// hosting includes the cancelled one
	assert.ElementsMatch(t, []string{past, soon, later, last, cancelled}, ids(list(host, "?scope=hosting")))
	assert.Empty(t, ids(list(alice, "?scope=hosting")))

	// summary fields and per-viewer data
	items := list(alice, "")["items"].([]any)
	byID := map[string]map[string]any{}
	for _, it := range items {
		m := it.(map[string]any)
		byID[m["id"].(string)] = m
	}
	assert.Equal(t, "pending", byID[later]["my_status"])
	assert.Equal(t, "cancelled", byID[soon]["my_status"])
	assert.Nil(t, byID[last]["my_status"])
	assert.Equal(t, false, byID[last]["is_host"])
	// pending applications are counted for the host only
	assert.EqualValues(t, 0, byID[later]["pending_count"])
	hosted := map[string]any{}
	for _, it := range list(host, "?scope=hosting")["items"].([]any) {
		m := it.(map[string]any)
		hosted[m["id"].(string)] = m["pending_count"]
	}
	assert.EqualValues(t, 1, hosted[later])
	assert.EqualValues(t, 0, hosted[soon], "a withdrawn application no longer waits")
}

func TestApplyLifecycleAndTripMembers(t *testing.T) {
	e := newEnv(t)
	host, alice, bob := e.user(t, "host"), e.user(t, "alice"), e.user(t, "bob")
	trip := e.createTrip(t, host)
	b := eventBody("嘉明湖三日")
	b["linked_trip_id"] = trip
	ev := e.createEvent(t, host, b)
	path := "/group-events/" + ev["id"].(string)

	// host cannot apply; unknown event; auth needed
	rec := e.do("POST", path+"/apply", host.token, nil)
	assert.Equal(t, 409, rec.Code)
	assert.Equal(t, "host_cannot_apply", errCode(t, rec))
	assert.Equal(t, 401, e.do("POST", path+"/apply", "", nil).Code)
	assert.Equal(t, 404, e.do("POST", "/group-events/"+uuid.NewString()+"/apply", alice.token, nil).Code)
	assert.Equal(t, 400, e.do("POST", path+"/apply", alice.token, map[string]any{"message": strings.Repeat("字", 501)}).Code)

	// apply -> pending -> already_applied; pending applicants are not trip members
	rec = e.do("POST", path+"/apply", alice.token, map[string]any{"message": "我想去"})
	require.Equal(t, 200, rec.Code)
	rec = e.do("POST", path+"/apply", alice.token, nil)
	assert.Equal(t, 409, rec.Code)
	assert.Equal(t, "already_applied", errCode(t, rec))
	assert.Nil(t, e.memberRow(t, alice, trip, alice))

	// only the host sees and reviews applications; applications never carry an email
	assert.Equal(t, 403, e.do("GET", path+"/applications", alice.token, nil).Code)
	assert.Equal(t, 401, e.do("GET", path+"/applications", "", nil).Code)
	rec = e.do("GET", path+"/applications", host.token, nil)
	require.Equal(t, 200, rec.Code)
	assert.NotContains(t, rec.Body.String(), "@example.com")
	apps := decode(t, rec)["items"].([]any)
	require.Len(t, apps, 1)
	app := apps[0].(map[string]any)
	assert.Equal(t, "我想去", app["message"])
	assert.Equal(t, map[string]any{"id": alice.id.String(), "display_name": "alice", "avatar": "🐻"}, app["user"])
	appPath := path + "/applications/" + app["id"].(string)
	assert.Equal(t, 403, e.do("POST", appPath+"/review", alice.token, map[string]any{"approve": true}).Code)
	assert.Equal(t, 404, e.do("POST", path+"/applications/"+uuid.NewString()+"/review", host.token, map[string]any{"approve": true}).Code)
	assert.Equal(t, 409, e.do("DELETE", appPath, host.token, nil).Code, "only approved members can be removed")

	rec = e.do("POST", appPath+"/review", host.token, map[string]any{"approve": true})
	require.Equal(t, 200, rec.Code, rec.Body.String())
	assert.Equal(t, "approved", decode(t, rec)["status"])
	rec = e.do("POST", appPath+"/review", host.token, map[string]any{"approve": false})
	assert.Equal(t, 409, rec.Code)
	assert.Equal(t, "invalid_review", errCode(t, rec))

	// the approved applicant joined the trip as a member, visible through the sync pull
	row := e.memberRow(t, alice, trip, alice)
	require.NotNil(t, row)
	assert.Equal(t, "member", row["role"])
	assert.Nil(t, row["deleted_at"])
	assert.Equal(t, host.id.String(), row["created_by"])
	assert.Equal(t, host.id.String(), row["updated_by"])
	assert.Equal(t, "alice", row["display_name"])
	memberRowID := row["id"]
	// the host sees the same member in the trip
	assert.NotNil(t, e.memberRow(t, host, trip, alice))
	// default filter lists approved ones too
	assert.Len(t, decode(t, e.do("GET", path+"/applications", host.token, nil))["items"], 1)
	assert.Len(t, decode(t, e.do("GET", path+"/applications?status=pending", host.token, nil))["items"], 0)
	assert.Equal(t, 400, e.do("GET", path+"/applications?status=bogus", host.token, nil).Code)

	// leaving removes the member (soft delete, same row id)
	require.Equal(t, 204, e.do("DELETE", path+"/apply", alice.token, nil).Code)
	row = e.memberRow(t, alice, trip, alice)
	require.NotNil(t, row, "the removed member still receives the tombstone")
	assert.NotNil(t, row["deleted_at"])
	assert.Equal(t, memberRowID, row["id"])
	assert.Equal(t, 404, e.do("DELETE", path+"/apply", alice.token, nil).Code)
	assert.Equal(t, "application_not_found", errCode(t, e.do("DELETE", path+"/apply", alice.token, nil)))

	// apply again, approve: the same trip_members row is revived
	require.Equal(t, 200, e.do("POST", path+"/apply", alice.token, nil).Code)
	apps = decode(t, e.do("GET", path+"/applications", host.token, nil))["items"].([]any)
	require.Len(t, apps, 1, "the same application row is reused")
	require.Equal(t, 200, e.do("POST", path+"/applications/"+apps[0].(map[string]any)["id"].(string)+"/review", host.token,
		map[string]any{"approve": true}).Code)
	row = e.memberRow(t, alice, trip, alice)
	assert.Nil(t, row["deleted_at"])
	assert.Equal(t, memberRowID, row["id"])

	// the host removes the member
	rec = e.do("DELETE", path+"/applications/"+apps[0].(map[string]any)["id"].(string), alice.token, nil)
	assert.Equal(t, 403, rec.Code)
	require.Equal(t, 204, e.do("DELETE", path+"/applications/"+apps[0].(map[string]any)["id"].(string), host.token, nil).Code)
	assert.NotNil(t, e.memberRow(t, alice, trip, alice)["deleted_at"])
	d := decode(t, e.do("GET", path, alice.token, nil))
	assert.Equal(t, "cancelled", d["my_status"])
	assert.Equal(t, true, d["private_message_locked"])

	// bob is rejected, may apply again (updates the same row), and the owner role is never touched
	require.Equal(t, 200, e.do("POST", path+"/apply", bob.token, nil).Code)
	apps = decode(t, e.do("GET", path+"/applications?status=pending", host.token, nil))["items"].([]any)
	require.Len(t, apps, 1)
	bobApp := apps[0].(map[string]any)["id"].(string)
	require.Equal(t, 200, e.do("POST", path+"/applications/"+bobApp+"/review", host.token, map[string]any{"approve": false, "reason": "太遠"}).Code)
	assert.Nil(t, e.memberRow(t, bob, trip, bob))
	assert.Equal(t, "太遠", decode(t, e.do("GET", path, bob.token, nil))["my_rejection_reason"])
	rec = e.do("POST", path+"/apply", bob.token, nil)
	require.Equal(t, 200, rec.Code)
	assert.Equal(t, "pending", decode(t, rec)["my_status"])
	assert.Nil(t, decode(t, e.do("GET", path, bob.token, nil))["my_rejection_reason"])
	var owners int
	require.NoError(t, e.pool.QueryRow(context.Background(), `SELECT count(*) FROM trip_members WHERE trip_id = $1 AND role = 'owner' AND deleted_at IS NULL`, trip).Scan(&owners))
	assert.Equal(t, 1, owners)

	// closed events and expired events refuse applications; cancelling leaves trip members alone
	closed := e.createEvent(t, host, eventBody("關閉報名的活動"))["id"].(string)
	rec = e.do("PATCH", "/group-events/"+closed, host.token, map[string]any{"status": "closed"})
	require.Equal(t, 200, rec.Code, rec.Body.String())
	rec = e.do("POST", "/group-events/"+closed+"/apply", alice.token, nil)
	assert.Equal(t, 409, rec.Code)
	assert.Equal(t, "registration_closed", errCode(t, rec))
	b = eventBody("已經過期的活動")
	b["start_date"], b["end_date"] = "2026-11-21", nil
	expired := e.createEvent(t, host, b)["id"].(string)
	assert.Equal(t, "registration_closed", errCode(t, e.do("POST", "/group-events/"+expired+"/apply", alice.token, nil)))
	assert.Equal(t, 200, e.do("GET", "/group-events/"+expired, "", nil).Code, "expired events stay visible")

	// auto-approval joins the trip on apply
	b = eventBody("免審核的活動")
	b["approval_required"], b["linked_trip_id"] = false, trip
	auto := e.createEvent(t, host, b)["id"].(string)
	rec = e.do("POST", "/group-events/"+auto+"/apply", alice.token, nil)
	require.Equal(t, 200, rec.Code)
	assert.Equal(t, "approved", decode(t, rec)["my_status"])
	assert.Nil(t, e.memberRow(t, alice, trip, alice)["deleted_at"])
	assert.Equal(t, "集合暗號 SECRET-123", decode(t, e.do("GET", "/group-events/"+auto, alice.token, nil))["private_message"])
	require.Equal(t, 204, e.do("DELETE", "/group-events/"+auto, host.token, nil).Code)
	assert.Nil(t, e.memberRow(t, alice, trip, alice)["deleted_at"], "cancelling an event keeps trip members")
}

func TestCapacityRace(t *testing.T) {
	e := newEnv(t)
	host := e.user(t, "host")
	trip := e.createTrip(t, host)
	b := eventBody("人數上限的活動")
	b["max_members"], b["linked_trip_id"] = 2, trip
	ev := e.createEvent(t, host, b)
	path := "/group-events/" + ev["id"].(string)

	var users []person
	for i := 0; i < 6; i++ {
		u := e.user(t, fmt.Sprintf("racer%d", i))
		users = append(users, u)
		require.Equal(t, 200, e.do("POST", path+"/apply", u.token, nil).Code)
	}
	apps := decode(t, e.do("GET", path+"/applications", host.token, nil))["items"].([]any)
	require.Len(t, apps, 6)

	codes := make([]int, len(apps))
	var wg gosync.WaitGroup
	for i, a := range apps {
		wg.Add(1)
		go func() {
			defer wg.Done()
			codes[i] = e.do("POST", path+"/applications/"+a.(map[string]any)["id"].(string)+"/review", host.token,
				map[string]any{"approve": true}).Code
		}()
	}
	wg.Wait()
	ok, full := 0, 0
	for _, c := range codes {
		switch c {
		case 200:
			ok++
		case 409:
			full++
		default:
			t.Errorf("unexpected status %d", c)
		}
	}
	assert.Equal(t, 2, ok)
	assert.Equal(t, 4, full)
	var approved, members int
	require.NoError(t, e.pool.QueryRow(context.Background(), `SELECT count(*) FROM group_event_applications WHERE status = 'approved'`).Scan(&approved))
	require.NoError(t, e.pool.QueryRow(context.Background(), `SELECT count(*) FROM trip_members WHERE trip_id = $1 AND role = 'member' AND deleted_at IS NULL`, trip).Scan(&members))
	assert.Equal(t, 2, approved)
	assert.Equal(t, 2, members)

	// the same for auto-approved events: 6 simultaneous applications, 2 seats
	b = eventBody("免審核搶位的活動")
	b["max_members"], b["approval_required"] = 2, false
	auto := e.createEvent(t, host, b)["id"].(string)
	codes = make([]int, len(users))
	for i, u := range users {
		wg.Add(1)
		go func() {
			defer wg.Done()
			codes[i] = e.do("POST", "/group-events/"+auto+"/apply", u.token, nil).Code
		}()
	}
	wg.Wait()
	ok = 0
	for _, c := range codes {
		if c == 200 {
			ok++
		} else {
			assert.Equal(t, 409, c)
		}
	}
	assert.Equal(t, 2, ok)
	d := decode(t, e.do("GET", "/group-events/"+auto, "", nil))
	assert.EqualValues(t, 2, d["approved_count"])
}

func TestEditCancelAndVisibility(t *testing.T) {
	e := newEnv(t)
	host, alice, bob := e.user(t, "host"), e.user(t, "alice"), e.user(t, "bob")
	trip := e.createTrip(t, host)
	ev := e.createEvent(t, host, eventBody("可以編輯的活動"))
	id := ev["id"].(string)
	path := "/group-events/" + id

	// PATCH: host only, validated, null clears
	assert.Equal(t, 401, e.do("PATCH", path, "", map[string]any{"title": "新標題標題"}).Code)
	assert.Equal(t, 403, e.do("PATCH", path, alice.token, map[string]any{"title": "新標題標題"}).Code)
	assert.Equal(t, 404, e.do("PATCH", "/group-events/"+uuid.NewString(), host.token, map[string]any{"title": "新標題標題"}).Code)
	assert.Equal(t, 400, e.do("PATCH", path, host.token, map[string]any{"title": "新"}).Code)
	assert.Equal(t, 400, e.do("PATCH", path, host.token, map[string]any{"status": "cancelled"}).Code)
	assert.Equal(t, 400, e.do("PATCH", path, host.token, map[string]any{"end_date": "2026-12-01"}).Code)
	rec := e.do("PATCH", path, host.token, map[string]any{"title": "新的標題欄位", "end_date": nil, "max_members": 3})
	require.Equal(t, 200, rec.Code, rec.Body.String())
	d := decode(t, rec)
	assert.Equal(t, "新的標題欄位", d["title"])
	assert.Nil(t, d["end_date"])
	assert.EqualValues(t, 3, d["max_members"])
	assert.Equal(t, "三天兩夜", d["description"], "absent fields are unchanged")
	rec = e.do("PATCH", path, host.token, map[string]any{"linked_trip_id": trip, "trip_snapshot": map[string]any{"name": "x", "itinerary": []any{}}})
	require.Equal(t, 200, rec.Code, rec.Body.String())
	assert.Equal(t, trip, decode(t, rec)["linked_trip_id"])
	assert.NotNil(t, decode(t, rec)["snapshot_updated_at"])
	rec = e.do("PATCH", path, host.token, map[string]any{"linked_trip_id": nil, "trip_snapshot": nil})
	require.Equal(t, 200, rec.Code)
	assert.Nil(t, decode(t, rec)["linked_trip_id"])
	assert.Nil(t, decode(t, rec)["trip_snapshot"])
	assert.Equal(t, 403, e.do("PATCH", path, host.token, map[string]any{"linked_trip_id": e.createTrip(t, alice)}).Code)

	// max_members cannot drop below the approved count
	require.Equal(t, 200, e.do("POST", path+"/apply", alice.token, nil).Code)
	apps := decode(t, e.do("GET", path+"/applications", host.token, nil))["items"].([]any)
	appPath := path + "/applications/" + apps[0].(map[string]any)["id"].(string)
	require.Equal(t, 200, e.do("POST", appPath+"/review", host.token, map[string]any{"approve": true}).Code)
	require.Equal(t, 200, e.do("POST", path+"/apply", bob.token, nil).Code)
	rec = e.do("PATCH", path, host.token, map[string]any{"max_members": 2})
	assert.Equal(t, 200, rec.Code)
	// two seats, one used: ok. Below one is invalid by range already (min 2), so test the count rule with 3 approved
	// is covered by the service tests; here check the response of a bad range
	assert.Equal(t, 400, e.do("PATCH", path, host.token, map[string]any{"max_members": 1}).Code)

	// cancel: host only, 204, idempotent; event hidden from strangers but kept for host and applicants
	assert.Equal(t, 401, e.do("DELETE", path, "", nil).Code)
	assert.Equal(t, 403, e.do("DELETE", path, alice.token, nil).Code)
	assert.Equal(t, 204, e.do("DELETE", path, host.token, nil).Code)
	assert.Equal(t, 204, e.do("DELETE", path, host.token, nil).Code)
	carol := e.user(t, "carol")
	assert.Equal(t, 404, e.do("GET", path, "", nil).Code)
	assert.Equal(t, 404, e.do("GET", path, carol.token, nil).Code)
	assert.Equal(t, 404, e.do("DELETE", path, carol.token, nil).Code)
	assert.Equal(t, 404, e.do("GET", path+"/comments", "", nil).Code)
	assert.Equal(t, 404, e.do("POST", path+"/apply", carol.token, nil).Code)
	for _, p := range []person{host, alice, bob} {
		rec = e.do("GET", path, p.token, nil)
		require.Equal(t, 200, rec.Code, rec.Body.String())
		assert.Equal(t, "cancelled", decode(t, rec)["status"])
	}
	for _, scope := range []string{"all", "upcoming", "popular"} {
		assert.Empty(t, ids(decode(t, e.do("GET", "/group-events?scope="+scope, alice.token, nil))), scope)
	}
	assert.Equal(t, []string{id}, ids(decode(t, e.do("GET", "/group-events?scope=joined", alice.token, nil))))
	assert.Equal(t, []string{id}, ids(decode(t, e.do("GET", "/group-events?scope=hosting", host.token, nil))))
	rec = e.do("PATCH", path, host.token, map[string]any{"title": "取消後的標題"})
	assert.Equal(t, 409, rec.Code)
	assert.Equal(t, "event_cancelled", errCode(t, rec))
	var status string
	require.NoError(t, e.pool.QueryRow(context.Background(), `SELECT status FROM group_events WHERE id = $1`, id).Scan(&status))
	assert.Equal(t, "cancelled", status, "cancelling never deletes the row")
}

func TestCommentsLikesReports(t *testing.T) {
	e := newEnv(t)
	host, alice, bob := e.user(t, "host"), e.user(t, "alice"), e.user(t, "bob")
	id := e.createEvent(t, host, eventBody("留言與按讚的活動"))["id"].(string)
	path := "/group-events/" + id

	// comments
	assert.Equal(t, 401, e.do("POST", path+"/comments", "", map[string]any{"body": "hi"}).Code)
	assert.Equal(t, 400, e.do("POST", path+"/comments", alice.token, map[string]any{"body": "   "}).Code)
	assert.Equal(t, 400, e.do("POST", path+"/comments", alice.token, map[string]any{"body": strings.Repeat("字", 1001)}).Code)
	assert.Equal(t, 404, e.do("POST", "/group-events/"+uuid.NewString()+"/comments", alice.token, map[string]any{"body": "hi"}).Code)
	var cids []string
	for i, u := range []person{alice, bob, alice} {
		rec := e.do("POST", path+"/comments", u.token, map[string]any{"body": fmt.Sprintf("留言 %d", i+1)})
		require.Equal(t, 201, rec.Code, rec.Body.String())
		c := decode(t, rec)
		assert.Equal(t, true, c["mine"])
		assert.Equal(t, u.id.String(), c["user"].(map[string]any)["id"])
		cids = append(cids, c["id"].(string))
		time.Sleep(2 * time.Millisecond)
	}
	page := decode(t, e.do("GET", path+"/comments?limit=2", "", nil))
	assert.Equal(t, cids[:2], ids(page), "oldest first")
	assert.Equal(t, false, page["items"].([]any)[0].(map[string]any)["mine"])
	cur := page["next_cursor"].(string)
	page2 := decode(t, e.do("GET", path+"/comments?limit=2&cursor="+cur, alice.token, nil))
	assert.Equal(t, cids[2:], ids(page2))
	assert.Equal(t, true, page2["items"].([]any)[0].(map[string]any)["mine"])
	assert.NotContains(t, page2, "next_cursor")
	assert.Equal(t, 400, e.do("GET", path+"/comments?limit=51", "", nil).Code)
	assert.EqualValues(t, 3, decode(t, e.do("GET", path, "", nil))["comment_count"])

	// delete: author or host
	assert.Equal(t, 401, e.do("DELETE", path+"/comments/"+cids[0], "", nil).Code)
	assert.Equal(t, 403, e.do("DELETE", path+"/comments/"+cids[0], bob.token, nil).Code)
	assert.Equal(t, 204, e.do("DELETE", path+"/comments/"+cids[0], alice.token, nil).Code)
	assert.Equal(t, 404, e.do("DELETE", path+"/comments/"+cids[0], alice.token, nil).Code)
	assert.Equal(t, 204, e.do("DELETE", path+"/comments/"+cids[1], host.token, nil).Code)
	assert.Equal(t, []string{cids[2]}, ids(decode(t, e.do("GET", path+"/comments", "", nil))))
	assert.EqualValues(t, 1, decode(t, e.do("GET", path, "", nil))["comment_count"])
	var deleted int
	require.NoError(t, e.pool.QueryRow(context.Background(), `SELECT count(*) FROM group_event_comments WHERE deleted_at IS NOT NULL`).Scan(&deleted))
	assert.Equal(t, 2, deleted, "soft delete")

	// reports
	rep := func(p person, typ, target, reason string) *httptest.ResponseRecorder {
		return e.do("POST", "/reports", p.token, map[string]any{"target_type": typ, "target_id": target, "reason": reason})
	}
	assert.Equal(t, 401, rep(person{}, "group_event", id, "x").Code)
	assert.Equal(t, 400, rep(alice, "user", id, "x").Code)
	assert.Equal(t, 400, rep(alice, "group_event", id, "").Code)
	assert.Equal(t, 400, rep(alice, "group_event", id, strings.Repeat("字", 501)).Code)
	assert.Equal(t, 404, rep(alice, "group_event", uuid.NewString(), "x").Code)
	assert.Equal(t, 404, rep(alice, "group_event_comment", uuid.NewString(), "x").Code)
	assert.Equal(t, 404, rep(alice, "group_event_comment", cids[0], "x").Code, "deleted comments cannot be reported")
	rec := rep(alice, "group_event", id, "詐騙")
	assert.Equal(t, 201, rec.Code, rec.Body.String())
	first := decode(t, rec)
	rec = rep(alice, "group_event", id, "再報一次")
	assert.Equal(t, 200, rec.Code)
	assert.Equal(t, first["id"], decode(t, rec)["id"])
	assert.Equal(t, 201, rep(bob, "group_event", id, "x").Code)
	assert.Equal(t, 201, rep(alice, "group_event_comment", cids[2], "辱罵").Code)
	assert.Equal(t, 200, rep(alice, "group_event_comment", cids[2], "辱罵").Code)
	var n int
	require.NoError(t, e.pool.QueryRow(context.Background(), `SELECT count(*) FROM reports`).Scan(&n))
	assert.Equal(t, 3, n)
	var reason string
	require.NoError(t, e.pool.QueryRow(context.Background(), `SELECT reason FROM reports WHERE reporter_id = $1 AND target_type = 'group_event'`, alice.id).Scan(&reason))
	assert.Equal(t, "詐騙", reason, "a repeat report does not overwrite the first")

	// a hidden (cancelled) event cannot be reported by strangers
	hidden := e.createEvent(t, host, eventBody("被隱藏的活動"))["id"].(string)
	require.Equal(t, 204, e.do("DELETE", "/group-events/"+hidden, host.token, nil).Code)
	assert.Equal(t, 404, rep(alice, "group_event", hidden, "x").Code)
}
