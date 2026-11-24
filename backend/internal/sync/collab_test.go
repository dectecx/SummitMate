package sync

import (
	"strings"
	"testing"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

type crew struct {
	s                                       *Service
	pool                                    *pgxpool.Pool
	owner, guide, member, member2, outsider uuid.UUID
	removed                                 uuid.UUID
	trip                                    uuid.UUID
}

func newCrew(t *testing.T) crew {
	t.Helper()
	pool := testPool(t)
	s := NewService(pool)
	c := crew{s: s, pool: pool}
	c.owner = newUser(t, pool, "owner")
	c.guide = newUser(t, pool, "guide")
	c.member = newUser(t, pool, "member")
	c.member2 = newUser(t, pool, "member2")
	c.outsider = newUser(t, pool, "outsider")
	c.removed = newUser(t, pool, "removed")
	c.trip = createTrip(t, s, c.owner)
	addMember(t, s, c.owner, c.trip, c.guide, "guide")
	addMember(t, s, c.owner, c.trip, c.member, "member")
	addMember(t, s, c.owner, c.trip, c.member2, "member")
	addMember(t, s, c.owner, c.trip, c.removed, "member")
	require.Equal(t, StatusApplied, mustPush(t, s, c.owner, del("trip_members", MemberID(c.trip, c.removed)))[0].Status)
	return c
}

func (c crew) push(t *testing.T, user uuid.UUID, op Op) Result {
	t.Helper()
	return mustPush(t, c.s, user, op)[0]
}

func (c crew) status(t *testing.T, user uuid.UUID, op Op) string {
	t.Helper()
	return c.push(t, user, op).Status
}

func (c crew) message(t *testing.T, user uuid.UUID, parent *uuid.UUID, body string) uuid.UUID {
	t.Helper()
	id := uuid.New()
	patch := map[string]any{"trip_id": c.trip.String(), "body": body}
	if parent != nil {
		patch["parent_id"] = parent.String()
	}
	r := c.push(t, user, upsert("trip_messages", id, patch))
	require.Equal(t, StatusApplied, r.Status, r.Message)
	return id
}

func (c crew) poll(t *testing.T, patch map[string]any) uuid.UUID {
	t.Helper()
	id := uuid.New()
	p := map[string]any{"trip_id": c.trip.String(), "title": "哪天出發"}
	for k, v := range patch {
		p[k] = v
	}
	r := c.push(t, c.owner, upsert("polls", id, p))
	require.Equal(t, StatusApplied, r.Status, r.Message)
	return id
}

func (c crew) option(t *testing.T, user, poll uuid.UUID, text string) uuid.UUID {
	t.Helper()
	id := uuid.New()
	r := c.push(t, user, upsert("poll_options", id, map[string]any{"poll_id": poll.String(), "trip_id": c.trip.String(), "text": text}))
	require.Equal(t, StatusApplied, r.Status, r.Message)
	return id
}

func (c crew) votePatch(poll, option uuid.UUID) map[string]any {
	return map[string]any{"poll_id": poll.String(), "option_id": option.String(), "trip_id": c.trip.String()}
}

func TestVoteIDIsDeterministic(t *testing.T) {
	o, u := uuid.New(), uuid.New()
	assert.Equal(t, VoteID(o, u), VoteID(o, u))
	assert.NotEqual(t, VoteID(o, u), VoteID(u, o))
	assert.NotEqual(t, VoteID(o, u), MemberID(o, u))
	assert.Equal(t, "b3a7d1f4-2c58-4e0a-8f6b-5d1e9c3a7b42", voteNamespace.String())
}

func TestTripMessagesAccessRules(t *testing.T) {
	c := newCrew(t)
	msg := c.message(t, c.member, nil, "大家好")

	// Create: any active member, user_id forced; outsider and removed member are rejected.
	r := c.push(t, c.guide, upsert("trip_messages", uuid.New(), map[string]any{"trip_id": c.trip.String(), "body": "嚮導"}))
	require.Equal(t, StatusApplied, r.Status)
	assert.Equal(t, c.guide.String(), r.Row["user_id"])
	assert.Equal(t, StatusForbidden, c.status(t, c.outsider, upsert("trip_messages", uuid.New(), map[string]any{"trip_id": c.trip.String(), "body": "x"})))
	assert.Equal(t, StatusForbidden, c.status(t, c.removed, upsert("trip_messages", uuid.New(), map[string]any{"trip_id": c.trip.String(), "body": "x"})))
	assert.Equal(t, StatusInvalid, c.status(t, c.member, upsert("trip_messages", uuid.New(), map[string]any{"trip_id": c.trip.String(), "body": "x", "user_id": c.owner.String()})), "user_id is not client-settable")

	// Edit: author only, even the owner cannot.
	assert.Equal(t, StatusForbidden, c.status(t, c.owner, upsert("trip_messages", msg, map[string]any{"body": "改"})))
	assert.Equal(t, StatusForbidden, c.status(t, c.member2, upsert("trip_messages", msg, map[string]any{"body": "改"})))
	assert.Equal(t, StatusForbidden, c.status(t, c.outsider, upsert("trip_messages", msg, map[string]any{"body": "改"})))
	r = c.push(t, c.member, upsert("trip_messages", msg, map[string]any{"body": "改好了", "trip_id": uuid.NewString(), "parent_id": uuid.NewString()}))
	require.Equal(t, StatusApplied, r.Status, r.Message)
	assert.Equal(t, "改好了", r.Row["body"])
	assert.Equal(t, c.trip.String(), r.Row["trip_id"], "trip_id immutable")
	assert.Nil(t, r.Row["parent_id"], "parent_id immutable")

	// Delete: author or owner/guide; other members and outsiders cannot.
	assert.Equal(t, StatusForbidden, c.status(t, c.member2, del("trip_messages", msg)))
	assert.Equal(t, StatusForbidden, c.status(t, c.outsider, del("trip_messages", msg)))
	assert.Equal(t, StatusApplied, c.status(t, c.guide, del("trip_messages", msg)))
	assert.Equal(t, StatusGone, c.status(t, c.member, del("trip_messages", msg)))
	assert.Equal(t, StatusGone, c.status(t, c.member, upsert("trip_messages", msg, map[string]any{"body": "x"})))

	own := c.message(t, c.member2, nil, "自己的")
	assert.Equal(t, StatusApplied, c.status(t, c.member2, del("trip_messages", own)))
	byOwner := c.message(t, c.member2, nil, "團長刪")
	assert.Equal(t, StatusApplied, c.status(t, c.owner, del("trip_messages", byOwner)))
}

func TestTripMessagesValidationAndParentRule(t *testing.T) {
	c := newCrew(t)
	top := c.message(t, c.member, nil, "主留言")
	reply := c.message(t, c.member2, &top, "回覆")

	bad := func(patch map[string]any) {
		t.Helper()
		patch["trip_id"] = c.trip.String()
		r := c.push(t, c.member, upsert("trip_messages", uuid.New(), patch))
		assert.Equal(t, StatusInvalid, r.Status)
		assert.NotEmpty(t, r.Message)
	}
	bad(map[string]any{"body": ""})
	bad(map[string]any{"body": strings.Repeat("字", 1001)})
	bad(map[string]any{})
	bad(map[string]any{"body": 5.0})
	bad(map[string]any{"body": "x", "parent_id": reply.String()})   // reply to a reply
	bad(map[string]any{"body": "x", "parent_id": uuid.NewString()}) // unknown parent
	bad(map[string]any{"body": "x", "parent_id": "not-a-uuid"})     // malformed
	assert.Equal(t, StatusApplied, c.status(t, c.member, upsert("trip_messages", uuid.New(), map[string]any{"trip_id": c.trip.String(), "body": strings.Repeat("字", 1000)})))
	assert.Equal(t, StatusInvalid, c.status(t, c.member, upsert("trip_messages", top, map[string]any{"body": ""})), "empty edit")

	// A parent from another trip is rejected.
	other := createTrip(t, c.s, c.member)
	r := c.push(t, c.member, upsert("trip_messages", uuid.New(), map[string]any{"trip_id": other.String(), "body": "x", "parent_id": top.String()}))
	assert.Equal(t, StatusInvalid, r.Status)

	// Replying to a deleted top-level message is still allowed (offline replies must not be lost).
	require.Equal(t, StatusApplied, c.status(t, c.member, del("trip_messages", top)))
	c.message(t, c.member2, &top, "晚到的回覆")
}

func TestPollsEditorsOnly(t *testing.T) {
	c := newCrew(t)
	patch := func() map[string]any { return map[string]any{"trip_id": c.trip.String(), "title": "投票"} }

	for _, u := range []uuid.UUID{c.member, c.outsider, c.removed} {
		assert.Equal(t, StatusForbidden, c.status(t, u, upsert("polls", uuid.New(), patch())))
	}
	poll := uuid.New()
	p := patch()
	p["deadline"] = "2026-05-01T10:00:00Z"
	p["blind"] = true
	r := c.push(t, c.guide, upsert("polls", poll, p))
	require.Equal(t, StatusApplied, r.Status, r.Message)
	assert.Equal(t, "open", r.Row["status"])
	assert.Equal(t, true, r.Row["blind"])
	assert.NotNil(t, r.Row["deadline"])

	assert.Equal(t, StatusForbidden, c.status(t, c.member, upsert("polls", poll, map[string]any{"title": "改"})))
	assert.Equal(t, StatusForbidden, c.status(t, c.member, del("polls", poll)))
	r = c.push(t, c.owner, upsert("polls", poll, map[string]any{"status": "closed", "deadline": nil, "trip_id": uuid.NewString()}))
	require.Equal(t, StatusApplied, r.Status, r.Message)
	assert.Equal(t, "closed", r.Row["status"])
	assert.Nil(t, r.Row["deadline"])
	assert.Equal(t, c.trip.String(), r.Row["trip_id"])

	for name, patch := range map[string]map[string]any{
		"empty title":  {"title": ""},
		"long title":   {"title": strings.Repeat("a", 201)},
		"bad status":   {"status": "archived"},
		"bad deadline": {"deadline": "tomorrow"},
		"title null":   {"title": nil},
		"bad bool":     {"blind": "yes"},
	} {
		patch["trip_id"] = c.trip.String()
		if _, ok := patch["title"]; !ok {
			patch["title"] = "t"
		}
		r := c.push(t, c.owner, upsert("polls", uuid.New(), patch))
		assert.Equal(t, StatusInvalid, r.Status, name)
	}
	assert.Equal(t, StatusInvalid, c.status(t, c.owner, upsert("polls", uuid.New(), map[string]any{"trip_id": c.trip.String()})), "title required")

	assert.Equal(t, StatusApplied, c.status(t, c.guide, del("polls", poll)))
	assert.Equal(t, StatusGone, c.status(t, c.guide, upsert("polls", poll, map[string]any{"title": "x"})))
}

func TestPollOptionRules(t *testing.T) {
	c := newCrew(t)
	closedPoll := c.poll(t, map[string]any{"allow_add_option": true, "status": "closed"})
	locked := c.poll(t, nil) // allow_add_option=false
	open := c.poll(t, map[string]any{"allow_add_option": true})

	optPatch := func(poll uuid.UUID, text string) map[string]any {
		return map[string]any{"poll_id": poll.String(), "trip_id": c.trip.String(), "text": text}
	}
	// Editors may always create (even closed polls); members only on open polls that allow it.
	c.option(t, c.guide, locked, "A")
	c.option(t, c.owner, closedPoll, "B")
	assert.Equal(t, StatusForbidden, c.status(t, c.member, upsert("poll_options", uuid.New(), optPatch(locked, "x"))))
	assert.Equal(t, StatusForbidden, c.status(t, c.member, upsert("poll_options", uuid.New(), optPatch(closedPoll, "x"))))
	assert.Equal(t, StatusForbidden, c.status(t, c.outsider, upsert("poll_options", uuid.New(), optPatch(open, "x"))))
	assert.Equal(t, StatusForbidden, c.status(t, c.removed, upsert("poll_options", uuid.New(), optPatch(open, "x"))))

	mine := c.option(t, c.member, open, "我的選項")
	theirs := c.option(t, c.guide, open, "嚮導的選項")

	// Members edit/delete only their own; editors any.
	assert.Equal(t, StatusForbidden, c.status(t, c.member, upsert("poll_options", theirs, map[string]any{"text": "改"})))
	assert.Equal(t, StatusForbidden, c.status(t, c.member, del("poll_options", theirs)))
	assert.Equal(t, StatusForbidden, c.status(t, c.member2, upsert("poll_options", mine, map[string]any{"text": "改"})))
	assert.Equal(t, StatusForbidden, c.status(t, c.outsider, del("poll_options", mine)))
	r := c.push(t, c.member, upsert("poll_options", mine, map[string]any{"text": "改好", "sort_order": 3.0, "poll_id": locked.String(), "trip_id": uuid.NewString()}))
	require.Equal(t, StatusApplied, r.Status, r.Message)
	assert.Equal(t, "改好", r.Row["text"])
	assert.Equal(t, open.String(), r.Row["poll_id"], "poll_id immutable")
	assert.Equal(t, c.trip.String(), r.Row["trip_id"], "trip_id immutable")
	assert.Equal(t, StatusApplied, c.status(t, c.guide, upsert("poll_options", mine, map[string]any{"text": "嚮導改"})))
	assert.Equal(t, StatusApplied, c.status(t, c.owner, del("poll_options", theirs)))
	own := c.option(t, c.member2, open, "要刪的")
	assert.Equal(t, StatusApplied, c.status(t, c.member2, del("poll_options", own)))

	// Validation, and the poll must exist in the same trip.
	assert.Equal(t, StatusInvalid, c.status(t, c.owner, upsert("poll_options", uuid.New(), optPatch(open, ""))))
	assert.Equal(t, StatusInvalid, c.status(t, c.owner, upsert("poll_options", uuid.New(), optPatch(open, strings.Repeat("a", 101)))))
	assert.Equal(t, StatusInvalid, c.status(t, c.owner, upsert("poll_options", uuid.New(), optPatch(uuid.New(), "x"))))
	assert.Equal(t, StatusInvalid, c.status(t, c.owner, upsert("poll_options", uuid.New(), map[string]any{"poll_id": open.String(), "trip_id": c.trip.String()})), "text required")
	other := createTrip(t, c.s, c.owner)
	assert.Equal(t, StatusInvalid, c.status(t, c.owner, upsert("poll_options", uuid.New(), map[string]any{"poll_id": open.String(), "trip_id": other.String(), "text": "x"})))

	// A deleted poll accepts no new options.
	require.Equal(t, StatusApplied, c.status(t, c.owner, del("polls", locked)))
	assert.Equal(t, StatusInvalid, c.status(t, c.owner, upsert("poll_options", uuid.New(), optPatch(locked, "x"))))
}

func TestPollVotes(t *testing.T) {
	c := newCrew(t)
	poll := c.poll(t, nil)
	opt := c.option(t, c.owner, poll, "週六")
	opt2 := c.option(t, c.owner, poll, "週日")
	vid := VoteID(opt, c.member)

	// Wrong id is invalid; right id works with user_id forced.
	assert.Equal(t, StatusInvalid, c.status(t, c.member, upsert("poll_votes", uuid.New(), c.votePatch(poll, opt))))
	assert.Equal(t, StatusInvalid, c.status(t, c.member, upsert("poll_votes", VoteID(opt, c.member2), c.votePatch(poll, opt))), "someone else's deterministic id")
	assert.Equal(t, StatusInvalid, c.status(t, c.member, upsert("poll_votes", vid, map[string]any{"poll_id": poll.String(), "option_id": opt.String(), "trip_id": c.trip.String(), "user_id": c.member.String()})))
	r := c.push(t, c.member, upsert("poll_votes", vid, c.votePatch(poll, opt)))
	require.Equal(t, StatusApplied, r.Status, r.Message)
	assert.Equal(t, c.member.String(), r.Row["user_id"])
	assert.Nil(t, r.Row["deleted_at"])

	// Outsider and removed member cannot vote, even with their own correct id.
	assert.Equal(t, StatusForbidden, c.status(t, c.outsider, upsert("poll_votes", VoteID(opt, c.outsider), c.votePatch(poll, opt))))
	assert.Equal(t, StatusForbidden, c.status(t, c.removed, upsert("poll_votes", VoteID(opt, c.removed), c.votePatch(poll, opt))))
	// Editors vote like anyone.
	assert.Equal(t, StatusApplied, c.status(t, c.guide, upsert("poll_votes", VoteID(opt, c.guide), c.votePatch(poll, opt))))

	// Option/poll relations.
	otherPoll := c.poll(t, nil)
	otherOpt := c.option(t, c.owner, otherPoll, "別的")
	assert.Equal(t, StatusInvalid, c.status(t, c.member, upsert("poll_votes", VoteID(otherOpt, c.member), c.votePatch(poll, otherOpt))), "option of another poll")
	assert.Equal(t, StatusInvalid, c.status(t, c.member, upsert("poll_votes", VoteID(uuid.New(), c.member), c.votePatch(poll, uuid.New()))), "unknown option")
	otherTrip := createTrip(t, c.s, c.member)
	bad := c.votePatch(poll, opt)
	bad["trip_id"] = otherTrip.String()
	assert.Equal(t, StatusInvalid, c.status(t, c.member, upsert("poll_votes", VoteID(opt2, c.member), bad)), "trip mismatch")
	assert.Equal(t, StatusInvalid, c.status(t, c.member, upsert("poll_votes", VoteID(opt2, c.member), map[string]any{"poll_id": poll.String()})), "missing fields")

	// Nobody but the voter may retract or edit it.
	for _, u := range []uuid.UUID{c.owner, c.guide, c.member2, c.outsider} {
		assert.Equal(t, StatusForbidden, c.status(t, u, del("poll_votes", vid)))
		assert.Equal(t, StatusForbidden, c.status(t, u, upsert("poll_votes", vid, c.votePatch(poll, opt))))
	}
	// Immutable fields are ignored on update; replaying the same vote is a harmless no-op.
	r = c.push(t, c.member, upsert("poll_votes", vid, c.votePatch(poll, opt2)))
	require.Equal(t, StatusApplied, r.Status)
	assert.Equal(t, opt.String(), r.Row["option_id"])

	// Retract then revive by upserting the same id.
	r = c.push(t, c.member, del("poll_votes", vid))
	require.Equal(t, StatusApplied, r.Status)
	assert.NotNil(t, r.Row["deleted_at"])
	assert.Equal(t, StatusGone, c.status(t, c.member, del("poll_votes", vid)))
	assert.Equal(t, StatusForbidden, c.status(t, c.member2, upsert("poll_votes", vid, c.votePatch(poll, opt))), "others cannot revive")
	r = c.push(t, c.member, upsert("poll_votes", vid, c.votePatch(poll, opt)))
	require.Equal(t, StatusApplied, r.Status, r.Message)
	assert.Nil(t, r.Row["deleted_at"])

	var n int
	require.NoError(t, c.pool.QueryRow(t.Context(), `SELECT count(*) FROM poll_votes WHERE user_id = $1`, c.member).Scan(&n))
	assert.Equal(t, 1, n, "revive reuses the row")

	// A removed voter cannot revive; reviving needs the option to still exist.
	require.Equal(t, StatusApplied, c.status(t, c.member, del("poll_votes", vid)))
	require.Equal(t, StatusApplied, c.status(t, c.owner, del("poll_options", opt)))
	assert.Equal(t, StatusInvalid, c.status(t, c.member, upsert("poll_votes", vid, c.votePatch(poll, opt))))
	assert.Equal(t, StatusInvalid, c.status(t, c.member2, upsert("poll_votes", VoteID(opt, c.member2), c.votePatch(poll, opt))), "deleted option")
}

func TestFavoritesOwnerIsolation(t *testing.T) {
	pool := testPool(t)
	s := NewService(pool)
	alice, bob := newUser(t, pool, "alice"), newUser(t, pool, "bob")
	id := uuid.New()

	r := mustPush(t, s, alice, upsert("favorites", id, map[string]any{"kind": "mountain", "target_id": "beidawu"}))[0]
	require.Equal(t, StatusApplied, r.Status, r.Message)
	assert.Equal(t, alice.String(), r.Row["user_id"])

	// Immutable columns, isolation.
	r = mustPush(t, s, alice, upsert("favorites", id, map[string]any{"kind": "other", "target_id": "x"}))[0]
	require.Equal(t, StatusApplied, r.Status)
	assert.Equal(t, "mountain", r.Row["kind"])
	assert.Equal(t, "beidawu", r.Row["target_id"])
	assert.Equal(t, StatusForbidden, mustPush(t, s, bob, upsert("favorites", id, map[string]any{}))[0].Status)
	assert.Equal(t, StatusForbidden, mustPush(t, s, bob, del("favorites", id))[0].Status)
	assert.Empty(t, pullAll(t, s, bob, nil).Rows["favorites"])
	assert.Len(t, pullAll(t, s, alice, nil).Rows["favorites"], 1)

	ev := uuid.New()
	assert.Equal(t, StatusApplied, mustPush(t, s, alice, upsert("favorites", ev, map[string]any{"kind": "group_event", "target_id": uuid.NewString()}))[0].Status)

	res := mustPush(t, s, alice,
		upsert("favorites", uuid.New(), map[string]any{"kind": "trail", "target_id": "x"}),
		upsert("favorites", uuid.New(), map[string]any{"kind": "mountain"}),
		upsert("favorites", uuid.New(), map[string]any{"target_id": "x"}),
		upsert("favorites", uuid.New(), map[string]any{"kind": "mountain", "target_id": ""}),
		upsert("favorites", uuid.New(), map[string]any{"kind": "mountain", "target_id": strings.Repeat("a", 101)}),
		upsert("favorites", uuid.New(), map[string]any{"kind": "mountain", "target_id": "x", "user_id": bob.String()}),
	)
	for i, r := range res {
		assert.Equal(t, StatusInvalid, r.Status, i)
	}

	// Tombstone is pulled and final.
	assert.Equal(t, StatusApplied, mustPush(t, s, alice, del("favorites", id))[0].Status)
	rows := pullAll(t, s, alice, nil).Rows["favorites"]
	require.Len(t, rows, 1)
	assert.NotNil(t, rows[0]["deleted_at"])
	assert.Equal(t, StatusGone, mustPush(t, s, alice, upsert("favorites", id, map[string]any{}))[0].Status)
}

func TestCollabPullVisibilityOrderAndTripDeletion(t *testing.T) {
	c := newCrew(t)
	msg := c.message(t, c.member, nil, "hi")
	poll := c.poll(t, nil)
	opt := c.option(t, c.owner, poll, "A")
	require.Equal(t, StatusApplied, c.status(t, c.member, upsert("poll_votes", VoteID(opt, c.member), c.votePatch(poll, opt))))

	counts := func(u uuid.UUID) map[string]int {
		ch := pullAll(t, c.s, u, nil)
		m := map[string]int{}
		for _, k := range []string{"trip_messages", "polls", "poll_options", "poll_votes"} {
			m[k] = len(ch.Rows[k])
		}
		return m
	}
	all := map[string]int{"trip_messages": 1, "polls": 1, "poll_options": 1, "poll_votes": 1}
	for _, u := range []uuid.UUID{c.owner, c.guide, c.member, c.member2} {
		assert.Equal(t, all, counts(u))
	}
	none := map[string]int{"trip_messages": 0, "polls": 0, "poll_options": 0, "poll_votes": 0}
	assert.Equal(t, none, counts(c.outsider))
	assert.Equal(t, none, counts(c.removed))

	// Parents come before children in pullOrder.
	idx := map[string]int{}
	for i, n := range pullOrder {
		idx[n] = i
	}
	assert.Less(t, idx["trips"], idx["trip_messages"])
	assert.Less(t, idx["polls"], idx["poll_options"])
	assert.Less(t, idx["poll_options"], idx["poll_votes"])

	// Tombstones reach members.
	require.Equal(t, StatusApplied, c.status(t, c.member, del("trip_messages", msg)))
	rows := pullAll(t, c.s, c.member2, nil).Rows["trip_messages"]
	require.Len(t, rows, 1)
	assert.NotNil(t, rows[0]["deleted_at"])

	// A member removed later stops receiving them.
	require.Equal(t, StatusApplied, c.status(t, c.owner, del("trip_members", MemberID(c.trip, c.member2))))
	assert.Equal(t, none, counts(c.member2))

	// Deleting the trip hides everything and blocks writes.
	require.Equal(t, StatusApplied, c.status(t, c.owner, del("trips", c.trip)))
	for _, u := range []uuid.UUID{c.owner, c.guide, c.member} {
		assert.Equal(t, none, counts(u))
	}
	assert.Equal(t, StatusForbidden, c.status(t, c.member, upsert("trip_messages", uuid.New(), map[string]any{"trip_id": c.trip.String(), "body": "x"})))
	assert.Equal(t, StatusForbidden, c.status(t, c.member, del("poll_votes", VoteID(opt, c.member))))
}

func TestCollabIdempotentReplay(t *testing.T) {
	c := newCrew(t)
	poll := c.poll(t, nil)
	opt := c.option(t, c.owner, poll, "A")
	ops := []Op{
		upsert("trip_messages", uuid.New(), map[string]any{"trip_id": c.trip.String(), "body": "once"}),
		upsert("poll_votes", VoteID(opt, c.member), c.votePatch(poll, opt)),
	}
	first := mustPush(t, c.s, c.member, ops...)
	second := mustPush(t, c.s, c.member, ops...)
	assert.Equal(t, first, second)
	var n int
	require.NoError(t, c.pool.QueryRow(t.Context(), `SELECT (SELECT count(*) FROM trip_messages) + (SELECT count(*) FROM poll_votes)`).Scan(&n))
	assert.Equal(t, 2, n)
}
