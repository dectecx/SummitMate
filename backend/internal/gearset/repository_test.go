package gearset_test

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"
	pgxmock "github.com/pashagolub/pgxmock/v4"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"summitmate/internal/gearset"
)

// gearSetColumns mirrors the column order in the gear_sets SELECT clause.
var gearSetColumns = []string{
	"id", "title", "author", "total_weight", "item_count",
	"visibility", "download_key", "user_id",
	"created_at", "created_by", "updated_at", "updated_by",
}

var itemColumns = []string{"id", "gear_set_id", "name", "category", "weight", "quantity", "order_index"}
var mealColumns = []string{"id", "gear_set_id", "day", "meal_type", "name", "calories", "note"}

func newGearSetRepoMock(t *testing.T) (gearset.GearSetRepository, pgxmock.PgxConnIface) {
	t.Helper()
	mock, err := pgxmock.NewConn()
	require.NoError(t, err)
	return gearset.NewGearSetRepository(mock), mock
}

func anyArgs(n int) []any {
	args := make([]any, n)
	for i := range args {
		args[i] = pgxmock.AnyArg()
	}
	return args
}

func sampleGearSetID() uuid.UUID {
	return uuid.MustParse("11111111-1111-1111-1111-111111111111")
}

func sampleGearSetRow(id uuid.UUID, now time.Time) []any {
	key := "key-abc"
	return []any{
		id, "My GearSet", "Author", 3.14, 2,
		gearset.VisibilityPublic, &key, "user-1",
		now, "user-1", now, "user-1",
	}
}

// ---------------------------------------------------------------------------
// Create (with transaction)
// ---------------------------------------------------------------------------

func TestGearSetRepository_Create(t *testing.T) {
	t.Run("Given valid gear set with items and meals, When creating, Then transaction is committed", func(t *testing.T) {
		repo, mock := newGearSetRepoMock(t)
		defer func() { assert.NoError(t, mock.ExpectationsWereMet()) }()

		gsID := sampleGearSetID()
		itemID := uuid.MustParse("22222222-2222-2222-2222-222222222222")
		mealID := uuid.MustParse("33333333-3333-3333-3333-333333333333")

		mock.ExpectBegin()
		mock.ExpectExec(`INSERT INTO gear_sets`).
			WithArgs(anyArgs(12)...).
			WillReturnResult(pgxmock.NewResult("INSERT", 1))
		mock.ExpectExec(`INSERT INTO gear_set_items`).
			WithArgs(anyArgs(7)...).
			WillReturnResult(pgxmock.NewResult("INSERT", 1))
		mock.ExpectExec(`INSERT INTO gear_set_meals`).
			WithArgs(anyArgs(7)...).
			WillReturnResult(pgxmock.NewResult("INSERT", 1))
		mock.ExpectCommit()

		gs := &gearset.GearSet{
			ID: gsID, Title: "My GearSet", Author: "Author",
			UserID: "user-1", Visibility: gearset.VisibilityPublic,
			CreatedBy: "user-1", UpdatedBy: "user-1",
			Items: []gearset.GearSetItem{
				{ID: itemID, Name: "Tent", Category: "Shelter", Weight: 1.5, Quantity: 1},
			},
			Meals: []gearset.GearSetMeal{
				{ID: mealID, Day: "Day 1", MealType: "breakfast", Name: "Oatmeal", Calories: 350},
			},
		}

		err := repo.Create(context.Background(), gs)
		assert.NoError(t, err)
	})

	t.Run("Given DB error on gear set insert, When creating, Then transaction is rolled back", func(t *testing.T) {
		repo, mock := newGearSetRepoMock(t)
		defer func() { assert.NoError(t, mock.ExpectationsWereMet()) }()

		dbErr := errors.New("insert failed")
		mock.ExpectBegin()
		mock.ExpectExec(`INSERT INTO gear_sets`).WithArgs(anyArgs(12)...).WillReturnError(dbErr)
		mock.ExpectRollback()

		err := repo.Create(context.Background(), &gearset.GearSet{ID: sampleGearSetID()})

		require.Error(t, err)
		assert.ErrorIs(t, err, dbErr)
	})
}

// ---------------------------------------------------------------------------
// GetByID – main scan + child queries
// ---------------------------------------------------------------------------

func TestGearSetRepository_GetByID(t *testing.T) {
	t.Run("Given existing gear set ID, When fetching, Then gear set with items and meals is returned", func(t *testing.T) {
		repo, mock := newGearSetRepoMock(t)
		defer func() { assert.NoError(t, mock.ExpectationsWereMet()) }()

		now := time.Now()
		gsID := sampleGearSetID()
		itemID := uuid.MustParse("22222222-2222-2222-2222-222222222222")
		mealID := uuid.MustParse("33333333-3333-3333-3333-333333333333")

		// Main query (1 arg: id)
		mock.ExpectQuery(`SELECT .* FROM gear_sets`).
			WithArgs(pgxmock.AnyArg()).
			WillReturnRows(pgxmock.NewRows(gearSetColumns).AddRow(sampleGearSetRow(gsID, now)...))

		// Items child query (1 arg: id)
		mock.ExpectQuery(`SELECT .* FROM gear_set_items`).
			WithArgs(pgxmock.AnyArg()).
			WillReturnRows(pgxmock.NewRows(itemColumns).AddRow(
				itemID, gsID, "Tent", "Shelter", 1.5, 1, 0,
			))

		// Meals child query (1 arg: id)
		mock.ExpectQuery(`SELECT .* FROM gear_set_meals`).
			WithArgs(pgxmock.AnyArg()).
			WillReturnRows(pgxmock.NewRows(mealColumns).AddRow(
				mealID, gsID, "Day 1", "breakfast", "Oatmeal", 350.0, (*string)(nil),
			))

		gs, err := repo.GetByID(context.Background(), gsID)

		require.NoError(t, err)
		assert.Equal(t, gsID, gs.ID)
		assert.Equal(t, "My GearSet", gs.Title)
		assert.Len(t, gs.Items, 1)
		assert.Equal(t, "Tent", gs.Items[0].Name)
		assert.Len(t, gs.Meals, 1)
		assert.Equal(t, "Oatmeal", gs.Meals[0].Name)
	})

	t.Run("Given DB error on main query, When fetching, Then error is returned", func(t *testing.T) {
		repo, mock := newGearSetRepoMock(t)
		defer func() { assert.NoError(t, mock.ExpectationsWereMet()) }()

		dbErr := errors.New("table not found")
		mock.ExpectQuery(`SELECT .* FROM gear_sets`).WithArgs(pgxmock.AnyArg()).WillReturnError(dbErr)

		_, err := repo.GetByID(context.Background(), sampleGearSetID())

		require.Error(t, err)
		assert.ErrorIs(t, err, dbErr)
	})
}

// ---------------------------------------------------------------------------
// Delete – RowsAffected check
// ---------------------------------------------------------------------------

func TestGearSetRepository_Delete(t *testing.T) {
	t.Run("Given existing gear set, When deleting, Then no error", func(t *testing.T) {
		repo, mock := newGearSetRepoMock(t)
		defer func() { assert.NoError(t, mock.ExpectationsWereMet()) }()

		mock.ExpectExec(`DELETE FROM gear_sets`).
			WithArgs(pgxmock.AnyArg()).
			WillReturnResult(pgxmock.NewResult("DELETE", 1))

		err := repo.Delete(context.Background(), sampleGearSetID())
		assert.NoError(t, err)
	})

	t.Run("Given nonexistent gear set, When deleting, Then 'not found' error is returned", func(t *testing.T) {
		repo, mock := newGearSetRepoMock(t)
		defer func() { assert.NoError(t, mock.ExpectationsWereMet()) }()

		// RowsAffected = 0 → "gear set not found"
		mock.ExpectExec(`DELETE FROM gear_sets`).
			WithArgs(pgxmock.AnyArg()).
			WillReturnResult(pgxmock.NewResult("DELETE", 0))

		err := repo.Delete(context.Background(), sampleGearSetID())

		require.Error(t, err)
		assert.Contains(t, err.Error(), "not found")
	})
}

// ---------------------------------------------------------------------------
// List – filter logic (OwnerID vs. Visibilities)
// ---------------------------------------------------------------------------

func TestGearSetRepository_List(t *testing.T) {
	t.Run("Given visibility filter (public+protected), When listing, Then only matching sets are returned", func(t *testing.T) {
		repo, mock := newGearSetRepoMock(t)
		defer func() { assert.NoError(t, mock.ExpectationsWereMet()) }()

		now := time.Now()
		gsID := sampleGearSetID()

		// COUNT query: 2 args (VisibilityPublic, VisibilityProtected)
		mock.ExpectQuery(`SELECT COUNT`).
			WithArgs(anyArgs(2)...).
			WillReturnRows(pgxmock.NewRows([]string{"count"}).AddRow(1))

		// Main SELECT query: visibility args + limit + offset = 4 args
		mock.ExpectQuery(`SELECT`).
			WithArgs(anyArgs(4)...).
			WillReturnRows(pgxmock.NewRows(gearSetColumns).AddRow(sampleGearSetRow(gsID, now)...))

		// Batch items query (1 arg: array of set IDs)
		mock.ExpectQuery(`SELECT .* FROM gear_set_items`).
			WithArgs(pgxmock.AnyArg()).
			WillReturnRows(pgxmock.NewRows(itemColumns))

		// Batch meals query (1 arg: array of set IDs)
		mock.ExpectQuery(`SELECT .* FROM gear_set_meals`).
			WithArgs(pgxmock.AnyArg()).
			WillReturnRows(pgxmock.NewRows(mealColumns))

		filter := gearset.GearSetListFilter{
			Visibilities: []gearset.GearSetVisibility{gearset.VisibilityPublic, gearset.VisibilityProtected},
		}
		sets, total, err := repo.List(context.Background(), 10, 0, "", filter)

		require.NoError(t, err)
		assert.Equal(t, 1, total)
		assert.Len(t, sets, 1)
	})

	t.Run("Given ownerID filter, When listing, Then only that user's sets are returned", func(t *testing.T) {
		repo, mock := newGearSetRepoMock(t)
		defer func() { assert.NoError(t, mock.ExpectationsWereMet()) }()

		now := time.Now()
		gsID := sampleGearSetID()
		userID := "user-1"

		// COUNT query: 1 arg (userID)
		mock.ExpectQuery(`SELECT COUNT`).
			WithArgs(pgxmock.AnyArg()).
			WillReturnRows(pgxmock.NewRows([]string{"count"}).AddRow(1))

		// Main SELECT: userID + limit + offset = 3 args
		mock.ExpectQuery(`SELECT`).
			WithArgs(anyArgs(3)...).
			WillReturnRows(pgxmock.NewRows(gearSetColumns).AddRow(sampleGearSetRow(gsID, now)...))

		mock.ExpectQuery(`SELECT .* FROM gear_set_items`).
			WithArgs(pgxmock.AnyArg()).
			WillReturnRows(pgxmock.NewRows(itemColumns))

		mock.ExpectQuery(`SELECT .* FROM gear_set_meals`).
			WithArgs(pgxmock.AnyArg()).
			WillReturnRows(pgxmock.NewRows(mealColumns))

		filter := gearset.GearSetListFilter{OwnerID: &userID}
		sets, total, err := repo.List(context.Background(), 10, 0, "", filter)

		require.NoError(t, err)
		assert.Equal(t, 1, total)
		assert.Len(t, sets, 1)
	})

	t.Run("Given search keyword with visibility filter, When listing, Then count and data queries are executed", func(t *testing.T) {
		repo, mock := newGearSetRepoMock(t)
		defer func() { assert.NoError(t, mock.ExpectationsWereMet()) }()

		// COUNT query: 3 args (VisibilityPublic, VisibilityProtected, searchPattern)
		mock.ExpectQuery(`SELECT COUNT`).
			WithArgs(anyArgs(3)...).
			WillReturnRows(pgxmock.NewRows([]string{"count"}).AddRow(0))

		// Empty result set → skip child queries. 5 args: visibility×2 + searchPattern + limit + offset
		mock.ExpectQuery(`SELECT`).
			WithArgs(anyArgs(5)...).
			WillReturnRows(pgxmock.NewRows(gearSetColumns))

		filter := gearset.GearSetListFilter{
			Visibilities: []gearset.GearSetVisibility{gearset.VisibilityPublic, gearset.VisibilityProtected},
		}
		sets, total, err := repo.List(context.Background(), 10, 0, "tent", filter)

		require.NoError(t, err)
		assert.Equal(t, 0, total)
		assert.Empty(t, sets)
	})
}
