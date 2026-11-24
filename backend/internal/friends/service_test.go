package friends

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"summitmate/internal/platform/apperror"
	"summitmate/internal/platform/ratelimit"
)

var ctx = context.Background()

type rig struct {
	repo *fakeRepo
	svc  *Service
}

func newRig(limit int) *rig {
	repo := newFake()
	now := time.Date(2026, 11, 22, 12, 0, 0, 0, time.UTC)
	svc := NewService(repo, Options{
		Requests: ratelimit.NewMemory(limit, time.Hour),
		Now:      func() time.Time { now = now.Add(time.Second); return now },
	})
	return &rig{repo: repo, svc: svc}
}

func (r *rig) user(name string) uuid.UUID {
	id := uuid.New()
	r.repo.users[id] = &Person{ID: id, DisplayName: name, Avatar: "🐻"}
	return id
}

func requireCode(t *testing.T, err error, status int, code string) {
	t.Helper()
	require.Error(t, err)
	ae, ok := apperror.As(err)
	require.True(t, ok, "not an apperror: %v", err)
	assert.Equal(t, status, ae.Status)
	assert.Equal(t, code, ae.Code)
}

func TestSendCreatesPendingAndListsBothSides(t *testing.T) {
	r := newRig(20)
	a, b := r.user("alice"), r.user("bob")
	res, err := r.svc.Send(ctx, a, b)
	require.NoError(t, err)
	assert.Equal(t, StatusPending, res.Status)
	assert.True(t, res.Created)

	la, _ := r.svc.List(ctx, a)
	require.Len(t, la.Outgoing, 1)
	assert.Equal(t, b, la.Outgoing[0].Person.ID)
	assert.Equal(t, res.RequestID, la.Outgoing[0].ID)
	assert.Empty(t, la.Incoming)
	assert.Empty(t, la.Friends)
	lb, _ := r.svc.List(ctx, b)
	require.Len(t, lb.Incoming, 1)
	assert.Equal(t, a, lb.Incoming[0].Person.ID)
	assert.Empty(t, lb.Outgoing)
}

func TestSendSelfAndUnknownUser(t *testing.T) {
	r := newRig(20)
	a := r.user("alice")
	_, err := r.svc.Send(ctx, a, a)
	requireCode(t, err, 400, "cannot_friend_self")
	_, err = r.svc.Send(ctx, a, uuid.New())
	requireCode(t, err, 404, "user_not_found")

	gone := r.user("gone")
	delete(r.repo.users, gone) // inactive or unverified users are not available
	_, err = r.svc.Send(ctx, a, gone)
	requireCode(t, err, 404, "user_not_found")
}

func TestCrossingRequestsAcceptAtOnce(t *testing.T) {
	r := newRig(20)
	a, b := r.user("alice"), r.user("bob")
	first, err := r.svc.Send(ctx, a, b)
	require.NoError(t, err)
	res, err := r.svc.Send(ctx, b, a)
	require.NoError(t, err)
	assert.Equal(t, StatusAccepted, res.Status)
	assert.True(t, res.Created)
	assert.Equal(t, first.RequestID, res.RequestID, "same row, no duplicate")
	assert.Len(t, r.repo.rows, 1)

	for _, u := range []uuid.UUID{a, b} {
		l, _ := r.svc.List(ctx, u)
		require.Len(t, l.Friends, 1)
		assert.Empty(t, l.Incoming)
		assert.Empty(t, l.Outgoing)
	}
}

func TestDuplicatesChangeNothing(t *testing.T) {
	r := newRig(20)
	a, b := r.user("alice"), r.user("bob")
	first, _ := r.svc.Send(ctx, a, b)
	again, err := r.svc.Send(ctx, a, b)
	require.NoError(t, err)
	assert.Equal(t, SendResult{Status: StatusPending, RequestID: first.RequestID}, again)

	require.NoError(t, r.svc.Accept(ctx, b, first.RequestID))
	for _, pair := range [][2]uuid.UUID{{a, b}, {b, a}} {
		res, err := r.svc.Send(ctx, pair[0], pair[1])
		require.NoError(t, err)
		assert.Equal(t, SendResult{Status: StatusAccepted, RequestID: first.RequestID}, res)
	}
	assert.Len(t, r.repo.rows, 1)
}

func TestAcceptOnlyByAddresseeWhilePending(t *testing.T) {
	r := newRig(20)
	a, b, c := r.user("alice"), r.user("bob"), r.user("carol")
	res, _ := r.svc.Send(ctx, a, b)

	requireCode(t, r.svc.Accept(ctx, a, res.RequestID), 403, "forbidden")
	requireCode(t, r.svc.Accept(ctx, c, res.RequestID), 403, "forbidden")
	requireCode(t, r.svc.Accept(ctx, b, uuid.New()), 404, "friend_request_not_found")

	require.NoError(t, r.svc.Accept(ctx, b, res.RequestID))
	requireCode(t, r.svc.Accept(ctx, b, res.RequestID), 404, "friend_request_not_found")

	l, _ := r.svc.List(ctx, a)
	require.Len(t, l.Friends, 1)
	assert.Equal(t, "bob", l.Friends[0].DisplayName)
	assert.False(t, l.Friends[0].Since.IsZero())
}

func TestDeclineCancelAndSendAgain(t *testing.T) {
	r := newRig(20)
	a, b, c := r.user("alice"), r.user("bob"), r.user("carol")

	res, _ := r.svc.Send(ctx, a, b)
	requireCode(t, r.svc.Remove(ctx, c, res.RequestID), 404, "friend_request_not_found")
	require.NoError(t, r.svc.Remove(ctx, b, res.RequestID), "addressee declines")
	assert.Empty(t, r.repo.rows)
	requireCode(t, r.svc.Remove(ctx, b, res.RequestID), 404, "friend_request_not_found")

	res, err := r.svc.Send(ctx, a, b) // can be sent again after a decline
	require.NoError(t, err)
	assert.True(t, res.Created)
	require.NoError(t, r.svc.Remove(ctx, a, res.RequestID), "requester cancels")
	assert.Empty(t, r.repo.rows)

	// an accepted friendship is not a request: it cannot be removed through the request endpoint
	res, _ = r.svc.Send(ctx, a, b)
	require.NoError(t, r.svc.Accept(ctx, b, res.RequestID))
	requireCode(t, r.svc.Remove(ctx, a, res.RequestID), 404, "friend_request_not_found")
	assert.Len(t, r.repo.rows, 1)
}

func TestUnfriendIsIdempotentAndKeepsPendingRequests(t *testing.T) {
	r := newRig(20)
	a, b, c := r.user("alice"), r.user("bob"), r.user("carol")
	res, _ := r.svc.Send(ctx, a, b)
	require.NoError(t, r.svc.Accept(ctx, b, res.RequestID))

	require.NoError(t, r.svc.Unfriend(ctx, b, a)) // either side may unfriend
	require.NoError(t, r.svc.Unfriend(ctx, b, a))
	require.NoError(t, r.svc.Unfriend(ctx, a, uuid.New()))
	assert.Empty(t, r.repo.rows)

	pending, _ := r.svc.Send(ctx, a, c)
	require.NoError(t, r.svc.Unfriend(ctx, a, c))
	assert.Contains(t, r.repo.rows, pending.RequestID, "unfriend does not cancel a pending request")
}

func TestListHidesUnavailableUsersAndSortsFriends(t *testing.T) {
	r := newRig(20)
	me, zed, amy, gone := r.user("me"), r.user("zed"), r.user("amy"), r.user("gone")
	for _, u := range []uuid.UUID{zed, amy, gone} {
		res, _ := r.svc.Send(ctx, u, me)
		require.NoError(t, r.svc.Accept(ctx, me, res.RequestID))
	}
	delete(r.repo.users, gone)
	l, err := r.svc.List(ctx, me)
	require.NoError(t, err)
	require.Len(t, l.Friends, 2)
	assert.Equal(t, "amy", l.Friends[0].DisplayName)
	assert.Equal(t, "zed", l.Friends[1].DisplayName)
}

func TestRateLimitCountsOnlyNewRequests(t *testing.T) {
	r := newRig(3)
	a := r.user("alice")
	var others []uuid.UUID
	for i := 0; i < 4; i++ {
		others = append(others, r.user("u"))
	}
	for _, o := range others[:3] {
		_, err := r.svc.Send(ctx, a, o)
		require.NoError(t, err)
	}
	_, err := r.svc.Send(ctx, a, others[3])
	requireCode(t, err, 429, "too_many_requests")
	assert.Len(t, r.repo.rows, 3, "a limited request stores nothing")

	// repeating an existing request is free, and so is accepting a crossing one
	_, err = r.svc.Send(ctx, a, others[0])
	require.NoError(t, err)
	res, err := r.svc.Send(ctx, others[3], a)
	require.NoError(t, err) // others[3] has its own budget
	require.True(t, res.Created)
	back, err := r.svc.Send(ctx, a, others[3])
	require.NoError(t, err)
	assert.Equal(t, StatusAccepted, back.Status)
}

func TestCrossingAcceptIsNotRateLimited(t *testing.T) {
	r := newRig(1)
	a, b, c := r.user("alice"), r.user("bob"), r.user("carol")
	_, err := r.svc.Send(ctx, a, b)
	require.NoError(t, err)
	_, err = r.svc.Send(ctx, c, a)
	require.NoError(t, err)
	res, err := r.svc.Send(ctx, a, c) // a is out of budget but this only accepts
	require.NoError(t, err)
	assert.Equal(t, StatusAccepted, res.Status)
}

func TestPendingOutgoingCap(t *testing.T) {
	r := newRig(1000)
	a := r.user("alice")
	for i := 0; i < MaxPendingOutgoing; i++ {
		_, err := r.svc.Send(ctx, a, r.user("u"))
		require.NoError(t, err)
	}
	_, err := r.svc.Send(ctx, a, r.user("one too many"))
	requireCode(t, err, 409, "too_many_pending_requests")
}
