package groupevent_test

import (
	"context"
	"errors"
	"testing"
	"time"

	pgxmock "github.com/pashagolub/pgxmock/v4"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"summitmate/internal/groupevent"
)

// groupEventColumns mirrors the SELECT column order in GetEventByID / ListEvents scan.
var groupEventColumns = []string{
	"id", "host_id", "host_name", "host_avatar",
	"title", "description", "category", "location", "start_date", "end_date",
	"status", "max_members", "approval_required", "private_message", "linked_trip_id",
	"trip_snapshot", "snapshot_updated_at",
	"like_count", "comment_count", "created_at", "created_by", "updated_at", "updated_by",
	"application_count", "is_liked", "my_application_id", "my_application_status", "my_application_reason",
}

// createEventReturnColumns mirrors the RETURNING clause in CreateEvent.
var createEventReturnColumns = []string{"id", "status", "like_count", "comment_count", "created_at", "updated_at"}

var applicationColumns = []string{
	"id", "event_id", "user_id", "status", "message", "rejection_reason",
	"created_at", "created_by", "updated_at", "updated_by",
}

var commentColumns = []string{
	"id", "event_id", "user_id", "content",
	"created_at", "created_by", "updated_at", "updated_by",
	"display_name", "avatar",
}

func newGroupEventRepoMock(t *testing.T) (groupevent.GroupEventRepository, pgxmock.PgxConnIface) {
	t.Helper()
	mock, err := pgxmock.NewConn()
	require.NoError(t, err)
	return groupevent.NewGroupEventRepository(mock), mock
}

func anyArgs(n int) []any {
	args := make([]any, n)
	for i := range args {
		args[i] = pgxmock.AnyArg()
	}
	return args
}

func sampleGroupEventRow(now time.Time) []any {
	return []any{
		"event-1", "host-1", "Alice", "🐻",
		"My Hike", "A fun hike", groupevent.CategoryHiking, "Taipei",
		now, (*time.Time)(nil),
		"active", 10, false, "private note", (*string)(nil),
		(*groupevent.TripSnapshot)(nil), (*time.Time)(nil),
		0, 0, now, "host-1", now, "host-1",
		0, false, (*string)(nil), (*string)(nil), (*string)(nil),
	}
}

// ---------------------------------------------------------------------------
// CreateEvent – RETURNING scan
// ---------------------------------------------------------------------------

func TestGroupEventRepository_CreateEvent(t *testing.T) {
	t.Run("Given valid event, When creating, Then RETURNING fields are scanned into event", func(t *testing.T) {
		repo, mock := newGroupEventRepoMock(t)
		defer func() { assert.NoError(t, mock.ExpectationsWereMet()) }()

		now := time.Now()

		// 15 args: host_id, host_name, host_avatar, title, description, category, location,
		// start_date, end_date, max_members, approval_required, private_message, linked_trip_id,
		// created_by, updated_by
		mock.ExpectQuery(`INSERT INTO group_events`).
			WithArgs(anyArgs(15)...).
			WillReturnRows(pgxmock.NewRows(createEventReturnColumns).AddRow(
				"event-1", "active", 0, 0, now, now,
			))

		event := &groupevent.GroupEvent{
			HostID: "host-1", HostName: "Alice", HostAvatar: "🐻",
			Title: "My Hike", Description: "Fun", Category: groupevent.CategoryHiking,
			Location: "Taipei", StartDate: now, MaxMembers: 10,
			CreatedBy: "host-1", UpdatedBy: "host-1",
		}

		err := repo.CreateEvent(context.Background(), event)

		require.NoError(t, err)
		assert.Equal(t, "event-1", event.ID)
		assert.Equal(t, "active", event.Status)
		assert.Equal(t, 0, event.LikeCount)
	})

	t.Run("Given DB error, When creating, Then error is wrapped", func(t *testing.T) {
		repo, mock := newGroupEventRepoMock(t)
		defer func() { assert.NoError(t, mock.ExpectationsWereMet()) }()

		dbErr := errors.New("constraint violation")
		mock.ExpectQuery(`INSERT INTO group_events`).WithArgs(anyArgs(15)...).WillReturnError(dbErr)

		err := repo.CreateEvent(context.Background(), &groupevent.GroupEvent{HostID: "host-1"})

		require.Error(t, err)
		assert.ErrorIs(t, err, dbErr)
	})
}

// ---------------------------------------------------------------------------
// GetEventByID – nil,nil on not found
// ---------------------------------------------------------------------------

func TestGroupEventRepository_GetEventByID(t *testing.T) {
	t.Run("Given existing event ID, When fetching, Then all 28 columns are scanned", func(t *testing.T) {
		repo, mock := newGroupEventRepoMock(t)
		defer func() { assert.NoError(t, mock.ExpectationsWereMet()) }()

		now := time.Now()

		mock.ExpectQuery(`SELECT`).
			WithArgs(anyArgs(2)...).
			WillReturnRows(pgxmock.NewRows(groupEventColumns).AddRow(sampleGroupEventRow(now)...))

		event, err := repo.GetEventByID(context.Background(), "event-1", "user-1")

		require.NoError(t, err)
		require.NotNil(t, event)
		assert.Equal(t, "event-1", event.ID)
		assert.Equal(t, groupevent.CategoryHiking, event.Category)
	})

	t.Run("Given nonexistent event ID, When fetching, Then nil, nil is returned", func(t *testing.T) {
		repo, mock := newGroupEventRepoMock(t)
		defer func() { assert.NoError(t, mock.ExpectationsWereMet()) }()

		mock.ExpectQuery(`SELECT`).
			WithArgs(anyArgs(2)...).
			WillReturnRows(pgxmock.NewRows(groupEventColumns))

		event, err := repo.GetEventByID(context.Background(), "no-such-event", "")

		assert.NoError(t, err)
		assert.Nil(t, event)
	})
}

// ---------------------------------------------------------------------------
// ApplyToEvent – RETURNING id, created_at, updated_at
// ---------------------------------------------------------------------------

func TestGroupEventRepository_ApplyToEvent(t *testing.T) {
	t.Run("Given valid application, When applying, Then application ID and timestamps are populated", func(t *testing.T) {
		repo, mock := newGroupEventRepoMock(t)
		defer func() { assert.NoError(t, mock.ExpectationsWereMet()) }()

		now := time.Now()

		// 6 args: event_id, user_id, status, message, created_by, updated_by
		mock.ExpectQuery(`INSERT INTO group_event_applications`).
			WithArgs(anyArgs(6)...).
			WillReturnRows(pgxmock.NewRows([]string{"id", "created_at", "updated_at"}).AddRow(
				"app-1", now, now,
			))

		app := &groupevent.GroupEventApplication{
			EventID: "event-1", UserID: "user-1", Status: groupevent.ApplicationStatusPending,
			CreatedBy: "user-1", UpdatedBy: "user-1",
		}

		err := repo.ApplyToEvent(context.Background(), app)

		require.NoError(t, err)
		assert.Equal(t, "app-1", app.ID)
		assert.WithinDuration(t, now, app.CreatedAt, time.Second)
	})
}

// ---------------------------------------------------------------------------
// UpdateApplicationStatus – Exec call
// ---------------------------------------------------------------------------

func TestGroupEventRepository_UpdateApplicationStatus(t *testing.T) {
	t.Run("Given valid application ID, When updating status, Then Exec is called with correct fields", func(t *testing.T) {
		repo, mock := newGroupEventRepoMock(t)
		defer func() { assert.NoError(t, mock.ExpectationsWereMet()) }()

		// 4 args: status, rejection_reason, updated_by, id
		mock.ExpectExec(`UPDATE group_event_applications`).
			WithArgs(anyArgs(4)...).
			WillReturnResult(pgxmock.NewResult("UPDATE", 1))

		err := repo.UpdateApplicationStatus(
			context.Background(),
			"app-1",
			groupevent.ApplicationStatusApproved,
			"",
			"admin-1",
		)

		assert.NoError(t, err)
	})
}

// ---------------------------------------------------------------------------
// AddComment – insert comment + increment comment_count
// ---------------------------------------------------------------------------

func TestGroupEventRepository_AddComment(t *testing.T) {
	t.Run("Given valid comment, When adding, Then comment is inserted and comment_count is incremented", func(t *testing.T) {
		repo, mock := newGroupEventRepoMock(t)
		defer func() { assert.NoError(t, mock.ExpectationsWereMet()) }()

		now := time.Now()

		// INSERT comment RETURNING id, created_at, updated_at (5 args: event_id, user_id, content, created_by, updated_by)
		mock.ExpectQuery(`INSERT INTO group_event_comments`).
			WithArgs(anyArgs(5)...).
			WillReturnRows(pgxmock.NewRows([]string{"id", "created_at", "updated_at"}).AddRow(
				"comment-1", now, now,
			))

		// UPDATE group_events SET comment_count = comment_count + 1 (1 arg: event_id)
		mock.ExpectExec(`UPDATE group_events`).
			WithArgs(pgxmock.AnyArg()).
			WillReturnResult(pgxmock.NewResult("UPDATE", 1))

		comment := &groupevent.GroupEventComment{
			EventID: "event-1", UserID: "user-1", Content: "Great hike!",
			CreatedBy: "user-1", UpdatedBy: "user-1",
		}

		err := repo.AddComment(context.Background(), comment)

		require.NoError(t, err)
		assert.Equal(t, "comment-1", comment.ID)
	})

	t.Run("Given DB error on insert, When adding, Then error is returned", func(t *testing.T) {
		repo, mock := newGroupEventRepoMock(t)
		defer func() { assert.NoError(t, mock.ExpectationsWereMet()) }()

		dbErr := errors.New("FK violation")
		mock.ExpectQuery(`INSERT INTO group_event_comments`).WithArgs(anyArgs(5)...).WillReturnError(dbErr)

		err := repo.AddComment(context.Background(), &groupevent.GroupEventComment{EventID: "event-1"})

		require.Error(t, err)
		assert.ErrorIs(t, err, dbErr)
	})
}

// ---------------------------------------------------------------------------
// ToggleLike – EXISTS check + conditional insert/delete + count update
// ---------------------------------------------------------------------------

func TestGroupEventRepository_ToggleLike(t *testing.T) {
	t.Run("Given event not yet liked, When toggling, Then like is inserted and count incremented", func(t *testing.T) {
		repo, mock := newGroupEventRepoMock(t)
		defer func() { assert.NoError(t, mock.ExpectationsWereMet()) }()

		// EXISTS check → false (2 args: event_id, user_id)
		mock.ExpectQuery(`SELECT EXISTS`).
			WithArgs(anyArgs(2)...).
			WillReturnRows(pgxmock.NewRows([]string{"exists"}).AddRow(false))
		// INSERT like (2 args: event_id, user_id)
		mock.ExpectExec(`INSERT INTO group_event_likes`).
			WithArgs(anyArgs(2)...).
			WillReturnResult(pgxmock.NewResult("INSERT", 1))
		// UPDATE like_count + 1 (1 arg: event_id)
		mock.ExpectExec(`UPDATE group_events`).
			WithArgs(pgxmock.AnyArg()).
			WillReturnResult(pgxmock.NewResult("UPDATE", 1))

		isLiked, err := repo.ToggleLike(context.Background(), "event-1", "user-1")

		require.NoError(t, err)
		assert.True(t, isLiked)
	})

	t.Run("Given already liked event, When toggling, Then like is deleted and count decremented", func(t *testing.T) {
		repo, mock := newGroupEventRepoMock(t)
		defer func() { assert.NoError(t, mock.ExpectationsWereMet()) }()

		// EXISTS check → true (2 args: event_id, user_id)
		mock.ExpectQuery(`SELECT EXISTS`).
			WithArgs(anyArgs(2)...).
			WillReturnRows(pgxmock.NewRows([]string{"exists"}).AddRow(true))
		// DELETE like (2 args: event_id, user_id)
		mock.ExpectExec(`DELETE FROM group_event_likes`).
			WithArgs(anyArgs(2)...).
			WillReturnResult(pgxmock.NewResult("DELETE", 1))
		// UPDATE like_count - 1 (1 arg: event_id)
		mock.ExpectExec(`UPDATE group_events`).
			WithArgs(pgxmock.AnyArg()).
			WillReturnResult(pgxmock.NewResult("UPDATE", 1))

		isLiked, err := repo.ToggleLike(context.Background(), "event-1", "user-1")

		require.NoError(t, err)
		assert.False(t, isLiked)
	})
}
