package groupevents

import (
	"context"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"summitmate/internal/platform/apperror"
	"summitmate/internal/platform/ratelimit"
)

var ctx = context.Background()

func date(s string) time.Time {
	t, err := time.Parse("2006-01-02", s)
	if err != nil {
		panic(err)
	}
	return t
}

type rig struct {
	t    *testing.T
	repo *fakeRepo
	svc  *Service
	host uuid.UUID
}

func newRig(t *testing.T) *rig {
	repo := newFake()
	svc := NewService(repo, Options{
		Comments:     ratelimit.NewMemory(3, time.Minute),
		Applications: ratelimit.NewMemory(100, time.Minute),
		Now:          func() time.Time { return time.Date(2026, 11, 22, 12, 0, 0, 0, time.UTC) },
	})
	r := &rig{t: t, repo: repo, svc: svc, host: uuid.New()}
	repo.names[r.host] = "host"
	return r
}

func (r *rig) user(name string) uuid.UUID {
	id := uuid.New()
	r.repo.names[id] = name
	return id
}

func baseCreate() CreateInput {
	return CreateInput{
		Title: "嘉明湖三日", Category: "hiking", Location: "台東", StartDate: date("2026-12-05"),
		MaxMembers: 8, ApprovalRequired: true, Description: "說明", PrivateMessage: "集合暗號 123",
	}
}

func (r *rig) create(mod func(*CreateInput)) Event {
	in := baseCreate()
	if mod != nil {
		mod(&in)
	}
	e, err := r.svc.Create(ctx, r.host, in)
	require.NoError(r.t, err)
	return e
}

func code(err error) string {
	if ae, ok := apperror.As(err); ok {
		return ae.Code
	}
	if err == nil {
		return ""
	}
	return err.Error()
}

func TestCreateValidation(t *testing.T) {
	r := newRig(t)
	bad := func(want string, mod func(*CreateInput)) {
		t.Helper()
		in := baseCreate()
		mod(&in)
		_, err := r.svc.Create(ctx, r.host, in)
		assert.Equal(t, want, code(err), want)
	}
	bad("invalid_title", func(i *CreateInput) { i.Title = "短短" })
	bad("invalid_title", func(i *CreateInput) { i.Title = "    ab   " })
	bad("invalid_title", func(i *CreateInput) { i.Title = strings.Repeat("山", 201) })
	bad("invalid_category", func(i *CreateInput) { i.Category = "swim" })
	bad("invalid_location", func(i *CreateInput) { i.Location = strings.Repeat("a", 201) })
	bad("invalid_dates", func(i *CreateInput) { e := date("2026-12-04"); i.EndDate = &e })
	bad("invalid_max_members", func(i *CreateInput) { i.MaxMembers = 1 })
	bad("invalid_max_members", func(i *CreateInput) { i.MaxMembers = 101 })
	bad("invalid_description", func(i *CreateInput) { i.Description = strings.Repeat("字", 4001) })
	bad("invalid_private_message", func(i *CreateInput) { i.PrivateMessage = strings.Repeat("字", 2001) })

	ok := baseCreate()
	ok.Title = strings.Repeat("山", 5)
	ok.Description = strings.Repeat("字", 4000)
	ok.PrivateMessage = strings.Repeat("字", 2000)
	ok.MaxMembers = 100
	same := date("2026-12-05")
	ok.EndDate = &same
	e, err := r.svc.Create(ctx, r.host, ok)
	require.NoError(t, err)
	assert.Equal(t, StatusOpen, e.Status)
	assert.True(t, e.IsHost)
}

func TestLinkedTripOwnership(t *testing.T) {
	r := newRig(t)
	trip := uuid.New()
	_, err := r.svc.Create(ctx, r.host, func() CreateInput { i := baseCreate(); i.LinkedTripID = &trip; return i }())
	assert.Equal(t, "not_trip_owner", code(err))

	r.repo.owners[[2]uuid.UUID{trip, r.host}] = true
	e := r.create(func(i *CreateInput) { i.LinkedTripID = &trip })
	require.NotNil(t, e.LinkedTripID, "host sees the link")

	// anyone else never sees it
	other := r.user("other")
	got, err := r.svc.Get(ctx, &other, e.ID)
	require.NoError(t, err)
	assert.Nil(t, got.LinkedTripID)
	got, err = r.svc.Get(ctx, nil, e.ID)
	require.NoError(t, err)
	assert.Nil(t, got.LinkedTripID)

	// changing the link to someone else's trip is refused, keeping the same link is fine
	foreign := uuid.New()
	_, err = r.svc.Update(ctx, r.host, e.ID, UpdateInput{LinkedTripID: Opt[*uuid.UUID]{Set: true, Value: &foreign}})
	assert.Equal(t, "not_trip_owner", code(err))
	_, err = r.svc.Update(ctx, r.host, e.ID, UpdateInput{LinkedTripID: Opt[*uuid.UUID]{Set: true, Value: &trip}})
	assert.NoError(t, err)
	// clearing is allowed
	got, err = r.svc.Update(ctx, r.host, e.ID, UpdateInput{LinkedTripID: Opt[*uuid.UUID]{Set: true}})
	require.NoError(t, err)
	assert.Nil(t, got.LinkedTripID)
}

func TestSnapshotLimits(t *testing.T) {
	r := newRig(t)
	node := func(day int, name string) SnapshotNode { return SnapshotNode{Day: day, Name: name, Altitude: 2300} }
	nodes := func(n int) []SnapshotNode {
		out := make([]SnapshotNode, n)
		for i := range out {
			out[i] = node(1, "點")
		}
		return out
	}
	try := func(sn *Snapshot) error {
		in := baseCreate()
		in.TripSnapshot = sn
		_, err := r.svc.Create(ctx, r.host, in)
		return err
	}
	assert.Equal(t, "invalid_snapshot", code(try(&Snapshot{Name: "x", Itinerary: nodes(201)})))
	assert.Equal(t, "invalid_snapshot", code(try(&Snapshot{Name: "x", Itinerary: []SnapshotNode{node(0, "a")}})))
	assert.Equal(t, "invalid_snapshot", code(try(&Snapshot{Name: "x", Itinerary: []SnapshotNode{node(1, strings.Repeat("山", 201))}})))
	assert.Equal(t, "invalid_snapshot", code(try(&Snapshot{Name: strings.Repeat("山", 201)})))
	lat := 91.0
	assert.Equal(t, "invalid_snapshot", code(try(&Snapshot{Name: "x", Itinerary: []SnapshotNode{{Day: 1, Name: "a", Lat: &lat}}})))
	bad := "2026-13-01"
	assert.Equal(t, "invalid_snapshot", code(try(&Snapshot{Name: "x", StartDate: &bad})))
	// 200 nodes of 200 three-byte characters is about 120 KB
	big := make([]SnapshotNode, 200)
	for i := range big {
		big[i] = node(1, strings.Repeat("山", 200))
	}
	assert.Equal(t, "invalid_snapshot", code(try(&Snapshot{Name: "x", Itinerary: big})))

	assert.NoError(t, try(&Snapshot{Name: "x", Itinerary: nodes(200)}))

	// stored with a timestamp; replaced and cleared on update
	in := baseCreate()
	in.TripSnapshot = &Snapshot{Name: "嘉明湖", Itinerary: []SnapshotNode{node(1, "向陽")}}
	e, err := r.svc.Create(ctx, r.host, in)
	require.NoError(t, err)
	require.NotNil(t, e.SnapshotAt)
	sn, err := SnapshotOf(e.TripSnapshot)
	require.NoError(t, err)
	assert.Equal(t, "向陽", sn.Itinerary[0].Name)
	e, err = r.svc.Update(ctx, r.host, e.ID, UpdateInput{TripSnapshot: Opt[*Snapshot]{Set: true}})
	require.NoError(t, err)
	assert.Nil(t, e.TripSnapshot)
	assert.Nil(t, e.SnapshotAt)
	_, err = r.svc.Update(ctx, r.host, e.ID, UpdateInput{TripSnapshot: Opt[*Snapshot]{Set: true, Value: &Snapshot{Name: "x", Itinerary: nodes(201)}}})
	assert.Equal(t, "invalid_snapshot", code(err))
}

func TestPrivateMessageGating(t *testing.T) {
	r := newRig(t)
	e := r.create(nil)
	approved, pending, rejected, stranger := r.user("a"), r.user("p"), r.user("r"), r.user("s")
	for _, u := range []uuid.UUID{approved, pending, rejected} {
		_, err := r.svc.Apply(ctx, u, e.ID, "")
		require.NoError(t, err)
	}
	apps, err := r.svc.ListApplications(ctx, r.host, e.ID, "")
	require.NoError(t, err)
	require.Len(t, apps, 3)
	_, err = r.svc.Review(ctx, r.host, e.ID, apps[0].ID, true, "")
	require.NoError(t, err)
	_, err = r.svc.Review(ctx, r.host, e.ID, apps[2].ID, false, "人太多")
	require.NoError(t, err)

	see := func(viewer *uuid.UUID) (bool, Event) {
		got, err := r.svc.Get(ctx, viewer, e.ID)
		require.NoError(t, err)
		return got.PrivateMessageVisible, got
	}
	vis, got := see(&r.host)
	assert.True(t, vis)
	assert.Equal(t, "集合暗號 123", got.PrivateMessage)
	vis, got = see(&approved)
	assert.True(t, vis)
	assert.Equal(t, "集合暗號 123", got.PrivateMessage)
	for _, v := range []*uuid.UUID{&pending, &rejected, &stranger, nil} {
		vis, got = see(v)
		assert.False(t, vis)
		assert.Empty(t, got.PrivateMessage, "text is blanked in the service, not only hidden by the handler")
	}
	// the rejection reason is only for the rejected applicant
	_, got = see(&rejected)
	assert.Equal(t, "人太多", got.MyRejection)
	_, got = see(&stranger)
	assert.Empty(t, got.MyRejection)

	// lists never carry it
	page, err := r.svc.List(ctx, &approved, ListInput{})
	require.NoError(t, err)
	require.Len(t, page.Events, 1)
	assert.Empty(t, page.Events[0].PrivateMessage)
	assert.Equal(t, AppApproved, page.Events[0].MyStatus)
}

func TestCancelledVisibility(t *testing.T) {
	r := newRig(t)
	e := r.create(nil)
	applicant, stranger := r.user("a"), r.user("s")
	_, err := r.svc.Apply(ctx, applicant, e.ID, "hi")
	require.NoError(t, err)
	require.NoError(t, r.svc.Cancel(ctx, r.host, e.ID))
	require.NoError(t, r.svc.Cancel(ctx, r.host, e.ID), "idempotent")

	_, err = r.svc.Get(ctx, nil, e.ID)
	assert.Equal(t, "group_event_not_found", code(err))
	_, err = r.svc.Get(ctx, &stranger, e.ID)
	assert.Equal(t, "group_event_not_found", code(err))
	got, err := r.svc.Get(ctx, &applicant, e.ID)
	require.NoError(t, err)
	assert.Equal(t, StatusCancelled, got.Status)
	_, err = r.svc.Get(ctx, &r.host, e.ID)
	assert.NoError(t, err)

	// hidden from the open lists, listed for the host and the applicant
	for _, scope := range []string{ScopeAll, ScopeUpcoming, ScopePopular} {
		page, err := r.svc.List(ctx, &applicant, ListInput{Scope: scope})
		require.NoError(t, err)
		assert.Empty(t, page.Events, scope)
	}
	page, err := r.svc.List(ctx, &r.host, ListInput{Scope: ScopeHosting})
	require.NoError(t, err)
	assert.Len(t, page.Events, 1)
	page, err = r.svc.List(ctx, &applicant, ListInput{Scope: ScopeJoined})
	require.NoError(t, err)
	assert.Len(t, page.Events, 1)

	// other users cannot even act on it
	_, err = r.svc.Apply(ctx, stranger, e.ID, "")
	assert.Equal(t, "group_event_not_found", code(err))
	_, err = r.svc.CreateComment(ctx, stranger, e.ID, "hi")
	assert.Equal(t, "group_event_not_found", code(err))
	// a non-host cannot cancel; a cancelled event cannot be edited or applied to
	assert.Equal(t, "forbidden", code(r.svc.Cancel(ctx, applicant, e.ID)))
	title := "新的標題欄位"
	_, err = r.svc.Update(ctx, r.host, e.ID, UpdateInput{Title: &title})
	assert.Equal(t, "event_cancelled", code(err))
	_, err = r.svc.Apply(ctx, applicant, e.ID, "")
	assert.Equal(t, "already_applied", code(err))
}

func TestApplicationStateMachine(t *testing.T) {
	r := newRig(t)
	e := r.create(nil)
	u := r.user("u")

	_, err := r.svc.Apply(ctx, r.host, e.ID, "")
	assert.Equal(t, "host_cannot_apply", code(err))
	_, err = r.svc.Apply(ctx, u, e.ID, strings.Repeat("字", 501))
	assert.Equal(t, "invalid_message", code(err))
	_, err = r.svc.Apply(ctx, u, uuid.New(), "")
	assert.Equal(t, "group_event_not_found", code(err))

	st, err := r.svc.Apply(ctx, u, e.ID, "帶我去")
	require.NoError(t, err)
	assert.Equal(t, AppPending, st)
	_, err = r.svc.Apply(ctx, u, e.ID, "")
	assert.Equal(t, "already_applied", code(err))

	// cancel, then apply again (same row)
	require.NoError(t, r.svc.Withdraw(ctx, u, e.ID))
	assert.Equal(t, "application_not_found", code(r.svc.Withdraw(ctx, u, e.ID)))
	st, err = r.svc.Apply(ctx, u, e.ID, "再試一次")
	require.NoError(t, err)
	assert.Equal(t, AppPending, st)
	assert.Len(t, r.repo.apps, 1)

	// reject with a reason, apply again
	apps, _ := r.svc.ListApplications(ctx, r.host, e.ID, "")
	require.Len(t, apps, 1)
	assert.Equal(t, "再試一次", apps[0].Message)
	got, err := r.svc.Review(ctx, r.host, e.ID, apps[0].ID, false, "  名額保留  ")
	require.NoError(t, err)
	assert.Equal(t, AppRejected, got.Status)
	assert.Equal(t, "名額保留", got.RejectionReason)
	_, err = r.svc.Review(ctx, r.host, e.ID, apps[0].ID, true, "")
	assert.Equal(t, "invalid_review", code(err), "only pending applications can be reviewed")
	assert.Equal(t, "application_not_found", code(r.svc.Withdraw(ctx, u, e.ID)), "a rejected application cannot be withdrawn")
	st, err = r.svc.Apply(ctx, u, e.ID, "")
	require.NoError(t, err)
	assert.Equal(t, AppPending, st)
	assert.Empty(t, r.repo.apps[0].RejectionReason, "re-applying clears the old reason")

	// approve, then leave
	apps, _ = r.svc.ListApplications(ctx, r.host, e.ID, "")
	_, err = r.svc.Review(ctx, r.host, e.ID, apps[0].ID, true, "")
	require.NoError(t, err)
	_, err = r.svc.Apply(ctx, u, e.ID, "")
	assert.Equal(t, "already_applied", code(err))
	require.NoError(t, r.svc.Withdraw(ctx, u, e.ID))
	assert.Equal(t, AppCancelled, r.repo.apps[0].Status)

	// listing: default pending+approved, filter by status
	apps, _ = r.svc.ListApplications(ctx, r.host, e.ID, "")
	assert.Empty(t, apps)
	apps, _ = r.svc.ListApplications(ctx, r.host, e.ID, AppCancelled)
	assert.Len(t, apps, 1)
	_, err = r.svc.ListApplications(ctx, r.host, e.ID, "bogus")
	assert.Equal(t, "invalid_status", code(err))
	_, err = r.svc.ListApplications(ctx, u, e.ID, "")
	assert.Equal(t, "forbidden", code(err))
	_, err = r.svc.Review(ctx, u, e.ID, uuid.New(), true, "")
	assert.Equal(t, "forbidden", code(err))
	_, err = r.svc.Review(ctx, r.host, e.ID, uuid.New(), true, "")
	assert.Equal(t, "application_not_found", code(err))
	_, err = r.svc.Review(ctx, r.host, e.ID, apps[0].ID, false, strings.Repeat("字", 501))
	assert.Equal(t, "invalid_reason", code(err))
}

func TestRegistrationClosedAndExpired(t *testing.T) {
	r := newRig(t)
	u := r.user("u")

	closed := r.create(nil)
	st := StatusClosed
	_, err := r.svc.Update(ctx, r.host, closed.ID, UpdateInput{Status: &st})
	require.NoError(t, err)
	_, err = r.svc.Apply(ctx, u, closed.ID, "")
	assert.Equal(t, "registration_closed", code(err))
	// reopen
	open := StatusOpen
	_, err = r.svc.Update(ctx, r.host, closed.ID, UpdateInput{Status: &open})
	require.NoError(t, err)
	_, err = r.svc.Apply(ctx, u, closed.ID, "")
	assert.NoError(t, err)

	// started yesterday: viewable, not applicable; starting today is still fine
	past := r.create(func(i *CreateInput) { i.StartDate = date("2026-11-21") })
	_, err = r.svc.Get(ctx, nil, past.ID)
	assert.NoError(t, err)
	_, err = r.svc.Apply(ctx, u, past.ID, "")
	assert.Equal(t, "registration_closed", code(err))
	today := r.create(func(i *CreateInput) { i.StartDate = date("2026-11-22") })
	_, err = r.svc.Apply(ctx, u, today.ID, "")
	assert.NoError(t, err)
	page, err := r.svc.List(ctx, nil, ListInput{Scope: ScopeUpcoming})
	require.NoError(t, err)
	assert.Len(t, page.Events, 2, "the expired event is not upcoming")

	// cancelled status cannot be set through PATCH
	bad := StatusCancelled
	_, err = r.svc.Update(ctx, r.host, past.ID, UpdateInput{Status: &bad})
	assert.Equal(t, "invalid_status", code(err))
}

func TestAutoApprovalAndCapacity(t *testing.T) {
	r := newRig(t)
	e := r.create(func(i *CreateInput) { i.ApprovalRequired = false; i.MaxMembers = 2 })
	a, b, c := r.user("a"), r.user("b"), r.user("c")
	st, err := r.svc.Apply(ctx, a, e.ID, "")
	require.NoError(t, err)
	assert.Equal(t, AppApproved, st)
	_, err = r.svc.Apply(ctx, b, e.ID, "")
	require.NoError(t, err)
	_, err = r.svc.Apply(ctx, c, e.ID, "")
	assert.Equal(t, "event_full", code(err))
	got, _ := r.svc.Get(ctx, &c, e.ID)
	assert.Equal(t, 2, got.ApprovedCount)
	assert.Empty(t, got.MyStatus, "nothing was stored for the refused applicant")

	// a member leaves, the seat is free again
	require.NoError(t, r.svc.Withdraw(ctx, a, e.ID))
	st, err = r.svc.Apply(ctx, c, e.ID, "")
	require.NoError(t, err)
	assert.Equal(t, AppApproved, st)

	// approval flow: full event refuses approvals, host can lower max only down to the approved count
	e2 := r.create(func(i *CreateInput) { i.MaxMembers = 2 })
	var ids []uuid.UUID
	for _, n := range []string{"x", "y", "z"} {
		u := r.user(n)
		_, err := r.svc.Apply(ctx, u, e2.ID, "")
		require.NoError(t, err)
	}
	apps, _ := r.svc.ListApplications(ctx, r.host, e2.ID, "")
	for _, a := range apps {
		ids = append(ids, a.ID)
	}
	_, err = r.svc.Review(ctx, r.host, e2.ID, ids[0], true, "")
	require.NoError(t, err)
	_, err = r.svc.Review(ctx, r.host, e2.ID, ids[1], true, "")
	require.NoError(t, err)
	_, err = r.svc.Review(ctx, r.host, e2.ID, ids[2], true, "")
	assert.Equal(t, "event_full", code(err))
	one := 1
	_, err = r.svc.Update(ctx, r.host, e2.ID, UpdateInput{MaxMembers: &one})
	assert.Equal(t, "invalid_max_members", code(err))
	// removing a member frees a seat for the third applicant
	require.NoError(t, r.svc.RemoveMember(ctx, r.host, e2.ID, ids[0]))
	_, err = r.svc.Review(ctx, r.host, e2.ID, ids[2], true, "")
	assert.NoError(t, err)
	assert.Equal(t, "invalid_review", code(r.svc.RemoveMember(ctx, r.host, e2.ID, ids[0])), "already removed")
	assert.Equal(t, "forbidden", code(r.svc.RemoveMember(ctx, a, e2.ID, ids[1])))
}

func TestCapacityRaceNeverExceedsMax(t *testing.T) {
	r := newRig(t)
	e := r.create(func(i *CreateInput) { i.MaxMembers = 2 })
	var ids []uuid.UUID
	for i := 0; i < 6; i++ {
		_, err := r.svc.Apply(ctx, r.user("u"), e.ID, "")
		require.NoError(t, err)
	}
	apps, _ := r.svc.ListApplications(ctx, r.host, e.ID, "")
	for _, a := range apps {
		ids = append(ids, a.ID)
	}
	var wg sync.WaitGroup
	for _, id := range ids {
		wg.Add(1)
		go func() {
			defer wg.Done()
			_, _ = r.svc.Review(ctx, r.host, e.ID, id, true, "")
		}()
	}
	wg.Wait()
	n, _ := r.repo.ApprovedCount(ctx, e.ID)
	assert.Equal(t, 2, n)
}

func TestLinkedTripMembership(t *testing.T) {
	r := newRig(t)
	trip := uuid.New()
	r.repo.owners[[2]uuid.UUID{trip, r.host}] = true
	r.repo.members[[2]uuid.UUID{trip, r.host}] = true
	e := r.create(func(i *CreateInput) { i.LinkedTripID = &trip })
	u, v, w := r.user("u"), r.user("v"), r.user("w")
	member := func(x uuid.UUID) bool { return r.repo.members[[2]uuid.UUID{trip, x}] }

	_, err := r.svc.Apply(ctx, u, e.ID, "")
	require.NoError(t, err)
	assert.False(t, member(u), "pending applicants are not members")
	apps, _ := r.svc.ListApplications(ctx, r.host, e.ID, "")
	_, err = r.svc.Review(ctx, r.host, e.ID, apps[0].ID, true, "")
	require.NoError(t, err)
	assert.True(t, member(u))
	require.NoError(t, r.svc.Withdraw(ctx, u, e.ID))
	assert.False(t, member(u), "leaving removes the member")
	assert.True(t, member(r.host), "the owner stays")

	// rejected applicants never join; removal by the host removes too
	_, _ = r.svc.Apply(ctx, v, e.ID, "")
	apps, _ = r.svc.ListApplications(ctx, r.host, e.ID, AppPending)
	_, err = r.svc.Review(ctx, r.host, e.ID, apps[0].ID, false, "")
	require.NoError(t, err)
	assert.False(t, member(v))
	_, _ = r.svc.Apply(ctx, w, e.ID, "")
	apps, _ = r.svc.ListApplications(ctx, r.host, e.ID, AppPending)
	_, err = r.svc.Review(ctx, r.host, e.ID, apps[0].ID, true, "")
	require.NoError(t, err)
	require.True(t, member(w))
	require.NoError(t, r.svc.RemoveMember(ctx, r.host, e.ID, apps[0].ID))
	assert.False(t, member(w))

	// cancelling the event leaves trip members alone
	_, _ = r.svc.Apply(ctx, u, e.ID, "")
	apps, _ = r.svc.ListApplications(ctx, r.host, e.ID, AppPending)
	_, _ = r.svc.Review(ctx, r.host, e.ID, apps[0].ID, true, "")
	require.NoError(t, r.svc.Cancel(ctx, r.host, e.ID))
	assert.True(t, member(u))
	_, err = r.svc.Review(ctx, r.host, e.ID, apps[0].ID, true, "")
	assert.Equal(t, "invalid_review", code(err))

	// auto-approval joins the trip right away
	e2 := r.create(func(i *CreateInput) { i.LinkedTripID = &trip; i.ApprovalRequired = false })
	_, err = r.svc.Apply(ctx, v, e2.ID, "")
	require.NoError(t, err)
	assert.True(t, member(v))
}

func TestUpdateRules(t *testing.T) {
	r := newRig(t)
	e := r.create(nil)
	other := r.user("o")
	title := "新的標題欄位"
	_, err := r.svc.Update(ctx, other, e.ID, UpdateInput{Title: &title})
	assert.Equal(t, "forbidden", code(err))
	_, err = r.svc.Update(ctx, other, uuid.New(), UpdateInput{Title: &title})
	assert.Equal(t, "group_event_not_found", code(err))

	short := "ab"
	_, err = r.svc.Update(ctx, r.host, e.ID, UpdateInput{Title: &short})
	assert.Equal(t, "invalid_title", code(err))
	cat := "x"
	_, err = r.svc.Update(ctx, r.host, e.ID, UpdateInput{Category: &cat})
	assert.Equal(t, "invalid_category", code(err))
	end := date("2026-12-01")
	_, err = r.svc.Update(ctx, r.host, e.ID, UpdateInput{EndDate: Opt[*time.Time]{Set: true, Value: &end}})
	assert.Equal(t, "invalid_dates", code(err), "end before the stored start")
	start := date("2026-11-30")
	_, err = r.svc.Update(ctx, r.host, e.ID, UpdateInput{StartDate: &start, EndDate: Opt[*time.Time]{Set: true, Value: &end}})
	require.NoError(t, err)
	got, err := r.svc.Update(ctx, r.host, e.ID, UpdateInput{EndDate: Opt[*time.Time]{Set: true}})
	require.NoError(t, err)
	assert.Nil(t, got.EndDate)
	assert.Equal(t, title, func() string { g, _ := r.svc.Update(ctx, r.host, e.ID, UpdateInput{Title: &title}); return g.Title }())
	big := 101
	_, err = r.svc.Update(ctx, r.host, e.ID, UpdateInput{MaxMembers: &big})
	assert.Equal(t, "invalid_max_members", code(err))
	pm := "新的暗號"
	got, err = r.svc.Update(ctx, r.host, e.ID, UpdateInput{PrivateMessage: &pm})
	require.NoError(t, err)
	assert.Equal(t, pm, got.PrivateMessage)
}

func TestListValidationAndPaging(t *testing.T) {
	r := newRig(t)
	for i := 0; i < 5; i++ {
		r.create(nil)
	}
	_, err := r.svc.List(ctx, nil, ListInput{Scope: "mine"})
	assert.Equal(t, "invalid_scope", code(err))
	for _, s := range []string{ScopeJoined, ScopeHosting} {
		_, err = r.svc.List(ctx, nil, ListInput{Scope: s})
		assert.Equal(t, "unauthorized", code(err), s)
	}
	_, err = r.svc.List(ctx, nil, ListInput{Limit: 51})
	assert.Equal(t, "invalid_limit", code(err))
	_, err = r.svc.List(ctx, nil, ListInput{Limit: -1})
	assert.Equal(t, "invalid_limit", code(err))
	_, err = r.svc.List(ctx, nil, ListInput{Q: strings.Repeat("a", 101)})
	assert.Equal(t, "invalid_query", code(err))
	_, err = r.svc.List(ctx, nil, ListInput{Cursor: "garbage!"})
	assert.Equal(t, "invalid_cursor", code(err))

	page, err := r.svc.List(ctx, nil, ListInput{Limit: 2})
	require.NoError(t, err)
	require.Len(t, page.Events, 2)
	require.NotEmpty(t, page.NextCursor)
	// a cursor belongs to its scope
	_, err = r.svc.List(ctx, nil, ListInput{Scope: ScopeUpcoming, Cursor: page.NextCursor})
	assert.Equal(t, "invalid_cursor", code(err))
	c, err := decodeCursor(ScopeAll, page.NextCursor)
	require.NoError(t, err)
	assert.Equal(t, page.Events[1].ID, c.ID)

	pc := encodeCursor(ScopePopular, Cursor{Offset: 40})
	d, err := decodeCursor(ScopePopular, pc)
	require.NoError(t, err)
	assert.Equal(t, 40, d.Offset)
}

func TestCommentsLikesReports(t *testing.T) {
	r := newRig(t)
	e := r.create(nil)
	a, b := r.user("a"), r.user("b")

	_, err := r.svc.CreateComment(ctx, a, e.ID, "   ")
	assert.Equal(t, "invalid_comment", code(err))
	_, err = r.svc.CreateComment(ctx, a, e.ID, strings.Repeat("字", 1001))
	assert.Equal(t, "invalid_comment", code(err))
	_, err = r.svc.CreateComment(ctx, a, uuid.New(), "hi")
	assert.Equal(t, "group_event_not_found", code(err))
	c1, err := r.svc.CreateComment(ctx, a, e.ID, " 第一則 ")
	require.NoError(t, err)
	assert.Equal(t, "第一則", c1.Body)
	assert.True(t, c1.Mine)
	c2, err := r.svc.CreateComment(ctx, b, e.ID, "第二則")
	require.NoError(t, err)
	_, err = r.svc.CreateComment(ctx, a, e.ID, "第三則")
	require.NoError(t, err)
	_, err = r.svc.CreateComment(ctx, a, e.ID, "第三點五則")
	require.NoError(t, err)
	_, err = r.svc.CreateComment(ctx, a, e.ID, "第四則")
	assert.Equal(t, "too_many_requests", code(err), "limiter allows 3 per window")

	page, err := r.svc.ListComments(ctx, &a, e.ID, 2, "")
	require.NoError(t, err)
	require.Len(t, page.Comments, 2)
	assert.Equal(t, "第一則", page.Comments[0].Body, "oldest first")
	assert.True(t, page.Comments[0].Mine)
	assert.False(t, page.Comments[1].Mine)
	require.NotEmpty(t, page.NextCursor)
	page2, err := r.svc.ListComments(ctx, nil, e.ID, 2, page.NextCursor)
	require.NoError(t, err)
	assert.Len(t, page2.Comments, 2)
	assert.Empty(t, page2.NextCursor)
	_, err = r.svc.ListComments(ctx, nil, e.ID, 99, "")
	assert.Equal(t, "invalid_limit", code(err))

	// delete: author or host, nobody else
	assert.Equal(t, "forbidden", code(r.svc.DeleteComment(ctx, a, e.ID, c2.ID)))
	assert.NoError(t, r.svc.DeleteComment(ctx, b, e.ID, c2.ID))
	assert.Equal(t, "comment_not_found", code(r.svc.DeleteComment(ctx, b, e.ID, c2.ID)))
	assert.NoError(t, r.svc.DeleteComment(ctx, r.host, e.ID, c1.ID), "the host can remove any comment")
	otherEvent := r.create(nil)
	assert.Equal(t, "comment_not_found", code(r.svc.DeleteComment(ctx, a, otherEvent.ID, c1.ID)), "wrong event")
	got, _ := r.svc.Get(ctx, nil, e.ID)
	assert.Equal(t, 2, got.CommentCount)

	// reports
	_, _, err = r.svc.CreateReport(ctx, a, ReportInput{TargetType: "user", TargetID: e.ID, Reason: "x"})
	assert.Equal(t, "invalid_target_type", code(err))
	_, _, err = r.svc.CreateReport(ctx, a, ReportInput{TargetType: TargetEvent, TargetID: e.ID, Reason: "  "})
	assert.Equal(t, "invalid_reason", code(err))
	_, _, err = r.svc.CreateReport(ctx, a, ReportInput{TargetType: TargetEvent, TargetID: e.ID, Reason: strings.Repeat("字", 501)})
	assert.Equal(t, "invalid_reason", code(err))
	_, _, err = r.svc.CreateReport(ctx, a, ReportInput{TargetType: TargetEvent, TargetID: uuid.New(), Reason: "x"})
	assert.Equal(t, "group_event_not_found", code(err))
	_, _, err = r.svc.CreateReport(ctx, a, ReportInput{TargetType: TargetComment, TargetID: uuid.New(), Reason: "x"})
	assert.Equal(t, "comment_not_found", code(err))
	rp, created, err := r.svc.CreateReport(ctx, a, ReportInput{TargetType: TargetEvent, TargetID: e.ID, Reason: "詐騙"})
	require.NoError(t, err)
	assert.True(t, created)
	rp2, created, err := r.svc.CreateReport(ctx, a, ReportInput{TargetType: TargetEvent, TargetID: e.ID, Reason: "again"})
	require.NoError(t, err)
	assert.False(t, created)
	assert.Equal(t, rp.ID, rp2.ID)
	_, created, _ = r.svc.CreateReport(ctx, b, ReportInput{TargetType: TargetEvent, TargetID: e.ID, Reason: "x"})
	assert.True(t, created, "another reporter, another row")
	third, _ := r.svc.CreateComment(ctx, r.user("z"), e.ID, "壞留言")
	_, created, err = r.svc.CreateReport(ctx, a, ReportInput{TargetType: TargetComment, TargetID: third.ID, Reason: "x"})
	require.NoError(t, err)
	assert.True(t, created)
}

func TestCursorRoundTrip(t *testing.T) {
	id := uuid.New()
	ts := time.Date(2026, 11, 22, 1, 2, 3, 456789000, time.UTC)
	s := encodeCursor(ScopeAll, Cursor{Time: ts, ID: id})
	c, err := decodeCursor(ScopeAll, s)
	require.NoError(t, err)
	assert.True(t, c.Time.Equal(ts))
	assert.Equal(t, id, c.ID)
	_, err = decodeCursor(ScopeHosting, s)
	assert.Error(t, err)
	_, err = decodeCursor(ScopePopular, s)
	assert.Error(t, err)
}
