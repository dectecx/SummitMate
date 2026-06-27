package trip_test

import (
	"context"
	"errors"
	"testing"
	"time"

	pgxmock "github.com/pashagolub/pgxmock/v4"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"summitmate/internal/trip"
)

// tripColumns mirrors the exact column order selected in trip queries.
// scanTrip uses FieldDescriptions() to match by name, so order is flexible,
// but these names must match the case-labels in the switch statement.
var tripColumns = []string{
	"id", "user_id", "name", "description", "start_date", "end_date",
	"cover_image", "is_active", "linked_event_id", "day_names",
	"created_at", "created_by", "updated_at", "updated_by",
}

func newTripRepoMock(t *testing.T) (trip.TripRepository, pgxmock.PgxConnIface) {
	t.Helper()
	mock, err := pgxmock.NewConn()
	require.NoError(t, err)
	return trip.NewTripRepository(mock), mock
}

func anyArgs(n int) []any {
	args := make([]any, n)
	for i := range args {
		args[i] = pgxmock.AnyArg()
	}
	return args
}

func sampleTripRow(now time.Time) []any {
	return []any{
		"trip-1", "user-1", "My Trip", (*string)(nil),
		now, (*time.Time)(nil), (*string)(nil), true, (*string)(nil), []string{"Day 1"},
		now, "user-1", now, "user-1",
	}
}

// ---------------------------------------------------------------------------
// Create
// ---------------------------------------------------------------------------

func TestTripRepository_Create(t *testing.T) {
	t.Run("Given valid trip, When creating, Then all fields are scanned via FieldDescriptions", func(t *testing.T) {
		repo, mock := newTripRepoMock(t)
		defer func() { assert.NoError(t, mock.ExpectationsWereMet()) }()

		now := time.Now()

		mock.ExpectQuery(`INSERT INTO trips`).
			WithArgs(anyArgs(10)...).
			WillReturnRows(pgxmock.NewRows(tripColumns).AddRow(sampleTripRow(now)...))

		created, err := repo.Create(context.Background(), &trip.Trip{
			UserID:    "user-1",
			Name:      "My Trip",
			StartDate: now,
			IsActive:  true,
			DayNames:  []string{"Day 1"},
			CreatedBy: "user-1",
			UpdatedBy: "user-1",
		})

		require.NoError(t, err)
		assert.Equal(t, "trip-1", created.ID)
		assert.Equal(t, "My Trip", created.Name)
		assert.Equal(t, []string{"Day 1"}, created.DayNames)
	})

	t.Run("Given DB error, When creating, Then error is wrapped", func(t *testing.T) {
		repo, mock := newTripRepoMock(t)
		defer func() { assert.NoError(t, mock.ExpectationsWereMet()) }()

		dbErr := errors.New("insert failed")
		mock.ExpectQuery(`INSERT INTO trips`).WithArgs(anyArgs(10)...).WillReturnError(dbErr)

		_, err := repo.Create(context.Background(), &trip.Trip{Name: "Fail"})

		require.Error(t, err)
		assert.ErrorIs(t, err, dbErr)
	})
}

// ---------------------------------------------------------------------------
// GetByID
// ---------------------------------------------------------------------------

func TestTripRepository_GetByID(t *testing.T) {
	t.Run("Given existing trip ID, When fetching, Then trip is returned with all fields", func(t *testing.T) {
		repo, mock := newTripRepoMock(t)
		defer func() { assert.NoError(t, mock.ExpectationsWereMet()) }()

		now := time.Now()

		mock.ExpectQuery(`SELECT`).
			WithArgs(pgxmock.AnyArg()).
			WillReturnRows(pgxmock.NewRows(tripColumns).AddRow(sampleTripRow(now)...))

		t2, err := repo.GetByID(context.Background(), "trip-1")

		require.NoError(t, err)
		assert.Equal(t, "trip-1", t2.ID)
		assert.Equal(t, "user-1", t2.UserID)
	})

	t.Run("Given nonexistent trip ID, When fetching, Then ErrNotFound is returned", func(t *testing.T) {
		repo, mock := newTripRepoMock(t)
		defer func() { assert.NoError(t, mock.ExpectationsWereMet()) }()

		// Empty rows → rows.Next() == false → ErrNotFound
		mock.ExpectQuery(`SELECT`).
			WithArgs(pgxmock.AnyArg()).
			WillReturnRows(pgxmock.NewRows(tripColumns))

		_, err := repo.GetByID(context.Background(), "no-such-trip")

		require.Error(t, err)
		assert.ErrorIs(t, err, trip.ErrNotFound)
	})
}

// ---------------------------------------------------------------------------
// ListByUserID – pagination and COUNT query
// ---------------------------------------------------------------------------

func TestTripRepository_ListByUserID(t *testing.T) {
	t.Run("Given 5 total trips and page size 2, When listing page 1, Then hasMore is true", func(t *testing.T) {
		repo, mock := newTripRepoMock(t)
		defer func() { assert.NoError(t, mock.ExpectationsWereMet()) }()

		now := time.Now()

		// COUNT query (1 arg: userID)
		mock.ExpectQuery(`SELECT COUNT`).
			WithArgs(pgxmock.AnyArg()).
			WillReturnRows(pgxmock.NewRows([]string{"count"}).AddRow(5))

		// Main data query: userID, limit+1, offset = 3 args
		mock.ExpectQuery(`SELECT`).
			WithArgs(anyArgs(3)...).
			WillReturnRows(pgxmock.NewRows(tripColumns).
				AddRow(sampleTripRow(now)...).
				AddRow("trip-2", "user-1", "Trip 2", (*string)(nil),
					now, (*time.Time)(nil), (*string)(nil), true, (*string)(nil), []string{},
					now, "user-1", now, "user-1"),
			)

		trips, total, hasMore, err := repo.ListByUserID(context.Background(), "user-1", 1, 2, "")

		require.NoError(t, err)
		assert.Equal(t, 5, total)
		assert.Len(t, trips, 2)
		assert.True(t, hasMore) // page(1) * limit(2) = 2 < total(5)
	})

	t.Run("Given 2 total trips and page size 10, When listing page 1, Then hasMore is false", func(t *testing.T) {
		repo, mock := newTripRepoMock(t)
		defer func() { assert.NoError(t, mock.ExpectationsWereMet()) }()

		now := time.Now()

		mock.ExpectQuery(`SELECT COUNT`).
			WithArgs(pgxmock.AnyArg()).
			WillReturnRows(pgxmock.NewRows([]string{"count"}).AddRow(2))

		mock.ExpectQuery(`SELECT`).
			WithArgs(anyArgs(3)...).
			WillReturnRows(pgxmock.NewRows(tripColumns).AddRow(sampleTripRow(now)...))

		_, total, hasMore, err := repo.ListByUserID(context.Background(), "user-1", 1, 10, "")

		require.NoError(t, err)
		assert.Equal(t, 2, total)
		assert.False(t, hasMore) // page(1) * limit(10) = 10 >= total(2)
	})
}

// ---------------------------------------------------------------------------
// Update
// ---------------------------------------------------------------------------

func TestTripRepository_Update(t *testing.T) {
	t.Run("Given valid update, When updating, Then updated trip is returned", func(t *testing.T) {
		repo, mock := newTripRepoMock(t)
		defer func() { assert.NoError(t, mock.ExpectationsWereMet()) }()

		now := time.Now()

		// Update without lastUpdatedAt: 9 args (name, desc, startDate, endDate, coverImage, isActive, dayNames, updatedBy, id)
		mock.ExpectQuery(`UPDATE trips`).
			WithArgs(anyArgs(9)...).
			WillReturnRows(pgxmock.NewRows(tripColumns).AddRow(sampleTripRow(now)...))

		updated, err := repo.Update(context.Background(), &trip.Trip{
			ID: "trip-1", Name: "Updated", UpdatedBy: "user-1", StartDate: now, IsActive: true,
		}, nil)

		require.NoError(t, err)
		assert.Equal(t, "trip-1", updated.ID)
	})

	t.Run("Given nonexistent trip, When updating, Then ErrNotFound is returned", func(t *testing.T) {
		repo, mock := newTripRepoMock(t)
		defer func() { assert.NoError(t, mock.ExpectationsWereMet()) }()

		// No rows returned → ErrNotFound
		mock.ExpectQuery(`UPDATE trips`).
			WithArgs(anyArgs(9)...).
			WillReturnRows(pgxmock.NewRows(tripColumns))

		_, err := repo.Update(context.Background(), &trip.Trip{ID: "ghost"}, nil)

		require.Error(t, err)
		assert.ErrorIs(t, err, trip.ErrNotFound)
	})
}

// ---------------------------------------------------------------------------
// DeleteByID
// ---------------------------------------------------------------------------

func TestTripRepository_DeleteByID(t *testing.T) {
	t.Run("Given valid trip ID, When deleting, Then no error", func(t *testing.T) {
		repo, mock := newTripRepoMock(t)
		defer func() { assert.NoError(t, mock.ExpectationsWereMet()) }()

		mock.ExpectExec(`DELETE FROM trips`).
			WithArgs(pgxmock.AnyArg()).
			WillReturnResult(pgxmock.NewResult("DELETE", 1))

		err := repo.DeleteByID(context.Background(), "trip-1")
		assert.NoError(t, err)
	})

	t.Run("Given DB error, When deleting, Then error is wrapped and returned", func(t *testing.T) {
		repo, mock := newTripRepoMock(t)
		defer func() { assert.NoError(t, mock.ExpectationsWereMet()) }()

		dbErr := errors.New("constraint violation")
		mock.ExpectExec(`DELETE FROM trips`).WithArgs(pgxmock.AnyArg()).WillReturnError(dbErr)

		err := repo.DeleteByID(context.Background(), "trip-1")

		require.Error(t, err)
		assert.ErrorIs(t, err, dbErr)
	})
}
