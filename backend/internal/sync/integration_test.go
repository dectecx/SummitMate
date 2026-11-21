package sync

import (
	"context"
	"fmt"
	"math/rand"
	"os"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// These tests need a real PostgreSQL 18+ (uuidv7). Set TEST_DATABASE_URL to run them, e.g.
//   TEST_DATABASE_URL=postgres://dev:pass@localhost:5432/postgres?sslmode=disable go test ./internal/sync
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

func newUser(t *testing.T, pool *pgxpool.Pool, name string) uuid.UUID {
	t.Helper()
	var id uuid.UUID
	err := pool.QueryRow(context.Background(), `INSERT INTO users (email, password_hash, display_name, is_verified)
		VALUES ($1, 'x', $2, TRUE) RETURNING id`, name+"@example.com", name).Scan(&id)
	require.NoError(t, err)
	return id
}

func upsert(entity string, id uuid.UUID, patch map[string]any) Op {
	return Op{OpID: uuid.New(), Entity: entity, EntityID: id, Patch: patch}
}

func del(entity string, id uuid.UUID) Op {
	return Op{OpID: uuid.New(), Entity: entity, EntityID: id, Delete: true}
}

func mustPush(t *testing.T, s *Service, user uuid.UUID, ops ...Op) []Result {
	t.Helper()
	res, err := s.Push(context.Background(), user, ops)
	require.NoError(t, err)
	require.Len(t, res, len(ops))
	return res
}

func createTrip(t *testing.T, s *Service, owner uuid.UUID) uuid.UUID {
	t.Helper()
	id := uuid.New()
	res := mustPush(t, s, owner, upsert("trips", id, map[string]any{"name": "嘉明湖", "start_date": "2026-05-01"}))
	require.Equal(t, StatusApplied, res[0].Status, res[0].Message)
	return id
}

func addMember(t *testing.T, s *Service, owner, trip, user uuid.UUID, role string) {
	t.Helper()
	res := mustPush(t, s, owner, upsert("trip_members", MemberID(trip, user), map[string]any{
		"trip_id": trip.String(), "user_id": user.String(), "role": role,
	}))
	require.Equal(t, StatusApplied, res[0].Status, res[0].Message)
}

func pullAll(t *testing.T, s *Service, user uuid.UUID, since *time.Time) Changes {
	t.Helper()
	ch, err := s.Pull(context.Background(), user, since, 0)
	require.NoError(t, err)
	return ch
}

func TestCreateTripMakesCreatorOwnerAndPullReturnsIt(t *testing.T) {
	pool := testPool(t)
	s := NewService(pool)
	owner := newUser(t, pool, "owner")
	trip := createTrip(t, s, owner)

	ch := pullAll(t, s, owner, nil)
	require.Len(t, ch.Rows["trips"], 1)
	assert.Equal(t, trip.String(), ch.Rows["trips"][0]["id"])
	require.Len(t, ch.Rows["trip_members"], 1)
	assert.Equal(t, "owner", ch.Rows["trip_members"][0]["role"])
	assert.Equal(t, "owner", ch.Rows["trip_members"][0]["display_name"])
	assert.False(t, ch.HasMore)
}

func TestPushIsIdempotentByOpID(t *testing.T) {
	pool := testPool(t)
	s := NewService(pool)
	owner := newUser(t, pool, "owner")
	trip := createTrip(t, s, owner)

	op := upsert("itinerary_items", uuid.New(), map[string]any{"trip_id": trip.String(), "name": "黑水塘"})
	first := mustPush(t, s, owner, op)
	second := mustPush(t, s, owner, op)
	assert.Equal(t, StatusApplied, first[0].Status)
	assert.Equal(t, first[0], second[0])

	var n int
	require.NoError(t, pool.QueryRow(context.Background(), `SELECT count(*) FROM itinerary_items`).Scan(&n))
	assert.Equal(t, 1, n)
}

func TestFieldLevelLastWriteWins(t *testing.T) {
	pool := testPool(t)
	s := NewService(pool)
	owner := newUser(t, pool, "owner")
	guide := newUser(t, pool, "guide")
	trip := createTrip(t, s, owner)
	addMember(t, s, owner, trip, guide, "guide")

	item := uuid.New()
	mustPush(t, s, owner, upsert("itinerary_items", item, map[string]any{"trip_id": trip.String(), "name": "A", "altitude": 100.0}))
	// Two devices edit different fields; both edits survive.
	mustPush(t, s, owner, upsert("itinerary_items", item, map[string]any{"name": "B"}))
	mustPush(t, s, guide, upsert("itinerary_items", item, map[string]any{"altitude": 200.0}))

	var name string
	var alt int
	require.NoError(t, pool.QueryRow(context.Background(), `SELECT name, altitude FROM itinerary_items WHERE id = $1`, item).Scan(&name, &alt))
	assert.Equal(t, "B", name)
	assert.Equal(t, 200, alt)
}

func TestPermissions(t *testing.T) {
	pool := testPool(t)
	s := NewService(pool)
	owner := newUser(t, pool, "owner")
	member := newUser(t, pool, "member")
	outsider := newUser(t, pool, "outsider")
	trip := createTrip(t, s, owner)
	addMember(t, s, owner, trip, member, "member")

	shared := map[string]any{"trip_id": trip.String(), "name": "x"}
	assert.Equal(t, StatusForbidden, mustPush(t, s, member, upsert("itinerary_items", uuid.New(), shared))[0].Status, "member cannot edit shared data")
	assert.Equal(t, StatusForbidden, mustPush(t, s, outsider, upsert("itinerary_items", uuid.New(), shared))[0].Status, "outsider")
	assert.Equal(t, StatusForbidden, mustPush(t, s, member, upsert("trips", trip, map[string]any{"name": "hijack"}))[0].Status, "member cannot rename trip")
	assert.Equal(t, StatusForbidden, mustPush(t, s, member, del("trips", trip))[0].Status, "member cannot delete trip")

	// Personal data: a member edits their own, and nobody else's.
	gear := uuid.New()
	assert.Equal(t, StatusApplied, mustPush(t, s, member, upsert("gear_items", gear, map[string]any{"trip_id": trip.String(), "name": "睡袋", "weight": 0.8}))[0].Status)
	assert.Equal(t, StatusForbidden, mustPush(t, s, owner, upsert("gear_items", gear, map[string]any{"name": "改名"}))[0].Status, "even the owner cannot edit someone's gear")
	assert.Equal(t, StatusForbidden, mustPush(t, s, owner, del("gear_items", gear))[0].Status)
	assert.Equal(t, StatusForbidden, mustPush(t, s, outsider, upsert("gear_items", uuid.New(), map[string]any{"trip_id": trip.String(), "name": "x"}))[0].Status)

	// Personal data stays private on pull.
	assert.Empty(t, pullAll(t, s, owner, nil).Rows["gear_items"])
	assert.Len(t, pullAll(t, s, member, nil).Rows["gear_items"], 1)

	// The owner's membership cannot be removed or demoted.
	ownerMember := MemberID(trip, owner)
	assert.Equal(t, StatusForbidden, mustPush(t, s, owner, del("trip_members", ownerMember))[0].Status)
}

func TestInvalidOpDoesNotAffectOthersInBatch(t *testing.T) {
	pool := testPool(t)
	s := NewService(pool)
	owner := newUser(t, pool, "owner")
	trip := createTrip(t, s, owner)

	ok1 := upsert("gear_items", uuid.New(), map[string]any{"trip_id": trip.String(), "name": "ok1"})
	bad := upsert("gear_items", uuid.New(), map[string]any{"trip_id": trip.String(), "name": "bad", "weight": -5.0})
	unknownField := upsert("gear_items", uuid.New(), map[string]any{"trip_id": trip.String(), "user_id": owner.String()})
	ok2 := upsert("gear_items", uuid.New(), map[string]any{"trip_id": trip.String(), "name": "ok2"})
	res := mustPush(t, s, owner, ok1, bad, unknownField, ok2)

	assert.Equal(t, []string{StatusApplied, StatusInvalid, StatusInvalid, StatusApplied}, []string{res[0].Status, res[1].Status, res[2].Status, res[3].Status})
	var n int
	require.NoError(t, pool.QueryRow(context.Background(), `SELECT count(*) FROM gear_items`).Scan(&n))
	assert.Equal(t, 2, n)
}

func TestDeleteThenUpsertIsGoneAndTombstonePulled(t *testing.T) {
	pool := testPool(t)
	s := NewService(pool)
	owner := newUser(t, pool, "owner")
	guide := newUser(t, pool, "guide")
	trip := createTrip(t, s, owner)
	addMember(t, s, owner, trip, guide, "guide")

	item := uuid.New()
	mustPush(t, s, owner, upsert("itinerary_items", item, map[string]any{"trip_id": trip.String(), "name": "A"}))
	before := pullAll(t, s, guide, nil).ServerTime

	assert.Equal(t, StatusApplied, mustPush(t, s, owner, del("itinerary_items", item))[0].Status)
	assert.Equal(t, StatusGone, mustPush(t, s, guide, upsert("itinerary_items", item, map[string]any{"name": "late edit"}))[0].Status)
	assert.Equal(t, StatusGone, mustPush(t, s, owner, del("itinerary_items", item))[0].Status)

	since := before.Add(-5 * time.Second)
	rows := pullAll(t, s, guide, &since).Rows["itinerary_items"]
	require.Len(t, rows, 1)
	assert.NotNil(t, rows[0]["deleted_at"], "tombstone is delivered")
}

func TestRemovedMemberGetsOwnTombstoneAndStopsSeeingTrip(t *testing.T) {
	pool := testPool(t)
	s := NewService(pool)
	owner := newUser(t, pool, "owner")
	member := newUser(t, pool, "member")
	trip := createTrip(t, s, owner)
	addMember(t, s, owner, trip, member, "member")
	require.Len(t, pullAll(t, s, member, nil).Rows["trips"], 1)

	res := mustPush(t, s, owner, del("trip_members", MemberID(trip, member)))
	assert.Equal(t, StatusApplied, res[0].Status)

	ch := pullAll(t, s, member, nil)
	assert.Empty(t, ch.Rows["trips"], "trip no longer visible")
	require.Len(t, ch.Rows["trip_members"], 1)
	assert.NotNil(t, ch.Rows["trip_members"][0]["deleted_at"], "member learns they were removed")

	// Re-inviting revives the same row.
	addMember(t, s, owner, trip, member, "guide")
	rows := pullAll(t, s, member, nil).Rows["trip_members"]
	require.Len(t, rows, 2)
}

func TestDeletedTripTombstoneReachesMembers(t *testing.T) {
	pool := testPool(t)
	s := NewService(pool)
	owner := newUser(t, pool, "owner")
	member := newUser(t, pool, "member")
	trip := createTrip(t, s, owner)
	addMember(t, s, owner, trip, member, "member")
	mustPush(t, s, owner, upsert("itinerary_items", uuid.New(), map[string]any{"trip_id": trip.String(), "name": "A"}))

	assert.Equal(t, StatusApplied, mustPush(t, s, owner, del("trips", trip))[0].Status)
	ch := pullAll(t, s, member, nil)
	require.Len(t, ch.Rows["trips"], 1)
	assert.NotNil(t, ch.Rows["trips"][0]["deleted_at"])
	assert.Empty(t, ch.Rows["itinerary_items"], "children of a deleted trip are not sent")
}

func TestMemberIDRuleIsEnforced(t *testing.T) {
	pool := testPool(t)
	s := NewService(pool)
	owner := newUser(t, pool, "owner")
	other := newUser(t, pool, "other")
	trip := createTrip(t, s, owner)

	res := mustPush(t, s, owner, upsert("trip_members", uuid.New(), map[string]any{"trip_id": trip.String(), "user_id": other.String()}))
	assert.Equal(t, StatusInvalid, res[0].Status)
	res = mustPush(t, s, owner, upsert("trip_members", MemberID(trip, uuid.New()), map[string]any{"trip_id": trip.String(), "user_id": uuid.NewString()}))
	assert.Equal(t, StatusInvalid, res[0].Status, "unknown user")
	res = mustPush(t, s, owner, upsert("trip_members", MemberID(trip, other), map[string]any{"trip_id": trip.String(), "user_id": other.String(), "role": "owner"}))
	assert.Equal(t, StatusInvalid, res[0].Status, "cannot grant owner")
}

func TestPullPaginationEventuallyReturnsEverything(t *testing.T) {
	pool := testPool(t)
	s := NewService(pool)
	owner := newUser(t, pool, "owner")
	trip := createTrip(t, s, owner)
	for i := 0; i < 5; i++ {
		mustPush(t, s, owner, upsert("itinerary_items", uuid.New(), map[string]any{"trip_id": trip.String(), "name": fmt.Sprint(i)}))
	}

	seen := map[any]bool{}
	var since *time.Time
	for page := 0; page < 20; page++ {
		ch, err := s.Pull(context.Background(), owner, since, 2)
		require.NoError(t, err)
		for _, r := range ch.Rows["itinerary_items"] {
			seen[r["id"]] = true
		}
		if !ch.HasMore {
			break
		}
		n := ch.NextSince
		since = &n
	}
	assert.Len(t, seen, 5)
}
