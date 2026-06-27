package auth_test

import (
	"context"
	"errors"
	"testing"
	"time"

	pgxmock "github.com/pashagolub/pgxmock/v4"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"summitmate/internal/auth"
)

// userColumns mirrors the exact column order in repository RETURNING / SELECT clauses.
var userColumns = []string{
	"id", "email", "password_hash", "display_name", "avatar",
	"role_id", "role_code", "is_active", "is_verified",
	"created_at", "created_by", "updated_at", "updated_by",
}

func newUserRepoMock(t *testing.T) (auth.UserRepository, pgxmock.PgxConnIface) {
	t.Helper()
	mock, err := pgxmock.NewConn()
	require.NoError(t, err)
	return auth.NewUserRepository(mock), mock
}

// anyArgs returns a slice of n pgxmock.AnyArg() matchers for argument-agnostic expectations.
func anyArgs(n int) []any {
	args := make([]any, n)
	for i := range args {
		args[i] = pgxmock.AnyArg()
	}
	return args
}

func sampleUserRow(now time.Time, roleID *string) []any {
	return []any{
		"user-1", "test@example.com", "hash", "Tester", "🐻",
		roleID, "MEMBER", true, false,
		now, (*string)(nil), now, (*string)(nil),
	}
}

// ---------------------------------------------------------------------------
// Create
// ---------------------------------------------------------------------------

func TestUserRepository_Create(t *testing.T) {
	t.Run("Given valid user, When creating, Then all RETURNING columns are scanned correctly", func(t *testing.T) {
		repo, mock := newUserRepoMock(t)
		defer func() { assert.NoError(t, mock.ExpectationsWereMet()) }()

		now := time.Now()
		roleID := "role-1"

		mock.ExpectQuery(`INSERT INTO users`).
			WithArgs(anyArgs(6)...).
			WillReturnRows(pgxmock.NewRows(userColumns).AddRow(sampleUserRow(now, &roleID)...))

		user, err := repo.Create(context.Background(), &auth.User{
			Email: "test@example.com", PasswordHash: "hash", DisplayName: "Tester", RoleID: &roleID,
		})

		require.NoError(t, err)
		assert.Equal(t, "user-1", user.ID)
		assert.Equal(t, "test@example.com", user.Email)
		assert.Equal(t, "MEMBER", user.RoleCode)
		assert.True(t, user.IsActive)
		assert.False(t, user.IsVerified)
	})

	t.Run("Given DB error, When creating, Then error is wrapped and returned", func(t *testing.T) {
		repo, mock := newUserRepoMock(t)
		defer func() { assert.NoError(t, mock.ExpectationsWereMet()) }()

		dbErr := errors.New("connection refused")
		mock.ExpectQuery(`INSERT INTO users`).WithArgs(anyArgs(6)...).WillReturnError(dbErr)

		_, err := repo.Create(context.Background(), &auth.User{Email: "x@x.com"})

		require.Error(t, err)
		assert.ErrorIs(t, err, dbErr)
	})
}

// ---------------------------------------------------------------------------
// GetByEmail / GetByID (via getOneUser)
// ---------------------------------------------------------------------------

func TestUserRepository_GetByEmail(t *testing.T) {
	t.Run("Given existing email, When fetching, Then all columns are scanned into User", func(t *testing.T) {
		repo, mock := newUserRepoMock(t)
		defer func() { assert.NoError(t, mock.ExpectationsWereMet()) }()

		now := time.Now()
		roleID := "role-1"

		mock.ExpectQuery(`SELECT`).
			WithArgs(pgxmock.AnyArg()).
			WillReturnRows(pgxmock.NewRows(userColumns).AddRow(sampleUserRow(now, &roleID)...))

		user, err := repo.GetByEmail(context.Background(), "test@example.com")

		require.NoError(t, err)
		assert.Equal(t, "user-1", user.ID)
		assert.Equal(t, "test@example.com", user.Email)
	})

	t.Run("Given unknown email, When fetching, Then ErrNotFound is returned", func(t *testing.T) {
		repo, mock := newUserRepoMock(t)
		defer func() { assert.NoError(t, mock.ExpectationsWereMet()) }()

		// Empty rows → row.Scan returns pgx.ErrNoRows
		mock.ExpectQuery(`SELECT`).
			WithArgs(pgxmock.AnyArg()).
			WillReturnRows(pgxmock.NewRows(userColumns))

		_, err := repo.GetByEmail(context.Background(), "nobody@example.com")

		require.Error(t, err)
		assert.ErrorIs(t, err, auth.ErrNotFound)
	})
}

func TestUserRepository_GetByID(t *testing.T) {
	t.Run("Given unknown ID, When fetching, Then ErrNotFound is returned", func(t *testing.T) {
		repo, mock := newUserRepoMock(t)
		defer func() { assert.NoError(t, mock.ExpectationsWereMet()) }()

		mock.ExpectQuery(`SELECT`).
			WithArgs(pgxmock.AnyArg()).
			WillReturnRows(pgxmock.NewRows(userColumns))

		_, err := repo.GetByID(context.Background(), "no-such-id")

		require.Error(t, err)
		assert.ErrorIs(t, err, auth.ErrNotFound)
	})
}

// ---------------------------------------------------------------------------
// SoftDelete – RowsAffected check
// ---------------------------------------------------------------------------

func TestUserRepository_SoftDelete(t *testing.T) {
	t.Run("Given existing user, When soft-deleting, Then no error", func(t *testing.T) {
		repo, mock := newUserRepoMock(t)
		defer func() { assert.NoError(t, mock.ExpectationsWereMet()) }()

		mock.ExpectExec(`UPDATE users`).
			WithArgs(pgxmock.AnyArg()).
			WillReturnResult(pgxmock.NewResult("UPDATE", 1))

		err := repo.SoftDelete(context.Background(), "user-1")
		assert.NoError(t, err)
	})

	t.Run("Given nonexistent ID, When soft-deleting, Then ErrNotFound is returned", func(t *testing.T) {
		repo, mock := newUserRepoMock(t)
		defer func() { assert.NoError(t, mock.ExpectationsWereMet()) }()

		mock.ExpectExec(`UPDATE users`).
			WithArgs(pgxmock.AnyArg()).
			WillReturnResult(pgxmock.NewResult("UPDATE", 0))

		err := repo.SoftDelete(context.Background(), "ghost-id")

		require.Error(t, err)
		assert.ErrorIs(t, err, auth.ErrNotFound)
	})
}

// ---------------------------------------------------------------------------
// SetVerified – RowsAffected check
// ---------------------------------------------------------------------------

func TestUserRepository_SetVerified(t *testing.T) {
	t.Run("Given existing user, When verifying, Then no error", func(t *testing.T) {
		repo, mock := newUserRepoMock(t)
		defer func() { assert.NoError(t, mock.ExpectationsWereMet()) }()

		mock.ExpectExec(`UPDATE users`).
			WithArgs(pgxmock.AnyArg()).
			WillReturnResult(pgxmock.NewResult("UPDATE", 1))

		assert.NoError(t, repo.SetVerified(context.Background(), "user-1"))
	})

	t.Run("Given nonexistent ID, When verifying, Then ErrNotFound is returned", func(t *testing.T) {
		repo, mock := newUserRepoMock(t)
		defer func() { assert.NoError(t, mock.ExpectationsWereMet()) }()

		mock.ExpectExec(`UPDATE users`).
			WithArgs(pgxmock.AnyArg()).
			WillReturnResult(pgxmock.NewResult("UPDATE", 0))

		err := repo.SetVerified(context.Background(), "ghost-id")

		require.Error(t, err)
		assert.ErrorIs(t, err, auth.ErrNotFound)
	})
}

// ---------------------------------------------------------------------------
// UpdatePassword – RowsAffected check
// ---------------------------------------------------------------------------

func TestUserRepository_UpdatePassword(t *testing.T) {
	t.Run("Given existing user, When updating password, Then no error", func(t *testing.T) {
		repo, mock := newUserRepoMock(t)
		defer func() { assert.NoError(t, mock.ExpectationsWereMet()) }()

		mock.ExpectExec(`UPDATE users`).
			WithArgs(anyArgs(2)...).
			WillReturnResult(pgxmock.NewResult("UPDATE", 1))

		assert.NoError(t, repo.UpdatePassword(context.Background(), "user-1", "newhash"))
	})

	t.Run("Given nonexistent ID, When updating password, Then ErrNotFound is returned", func(t *testing.T) {
		repo, mock := newUserRepoMock(t)
		defer func() { assert.NoError(t, mock.ExpectationsWereMet()) }()

		mock.ExpectExec(`UPDATE users`).
			WithArgs(anyArgs(2)...).
			WillReturnResult(pgxmock.NewResult("UPDATE", 0))

		err := repo.UpdatePassword(context.Background(), "ghost-id", "newhash")

		require.Error(t, err)
		assert.ErrorIs(t, err, auth.ErrNotFound)
	})
}

// ---------------------------------------------------------------------------
// GetRoleIDByCode
// ---------------------------------------------------------------------------

func TestUserRepository_GetRoleIDByCode(t *testing.T) {
	t.Run("Given known role code, When fetching, Then role ID is returned", func(t *testing.T) {
		repo, mock := newUserRepoMock(t)
		defer func() { assert.NoError(t, mock.ExpectationsWereMet()) }()

		mock.ExpectQuery(`SELECT id FROM roles`).
			WithArgs(pgxmock.AnyArg()).
			WillReturnRows(pgxmock.NewRows([]string{"id"}).AddRow("role-1"))

		id, err := repo.GetRoleIDByCode(context.Background(), "MEMBER")

		require.NoError(t, err)
		assert.Equal(t, "role-1", id)
	})

	t.Run("Given unknown role code, When fetching, Then ErrNotFound is returned", func(t *testing.T) {
		repo, mock := newUserRepoMock(t)
		defer func() { assert.NoError(t, mock.ExpectationsWereMet()) }()

		mock.ExpectQuery(`SELECT id FROM roles`).
			WithArgs(pgxmock.AnyArg()).
			WillReturnRows(pgxmock.NewRows([]string{"id"}))

		_, err := repo.GetRoleIDByCode(context.Background(), "UNKNOWN_ROLE")

		require.Error(t, err)
		assert.ErrorIs(t, err, auth.ErrNotFound)
	})
}

// ---------------------------------------------------------------------------
// Update
// ---------------------------------------------------------------------------

func TestUserRepository_Update(t *testing.T) {
	t.Run("Given valid update, When updating, Then updated user is returned", func(t *testing.T) {
		repo, mock := newUserRepoMock(t)
		defer func() { assert.NoError(t, mock.ExpectationsWereMet()) }()

		now := time.Now()
		roleID := "role-1"
		newName := "Updated Name"

		mock.ExpectQuery(`UPDATE users`).
			WithArgs(anyArgs(3)...).
			WillReturnRows(pgxmock.NewRows(userColumns).AddRow(
				"user-1", "test@example.com", "hash", "Updated Name", "🐻",
				&roleID, "MEMBER", true, false,
				now, (*string)(nil), now, (*string)(nil),
			))

		user, err := repo.Update(context.Background(), "user-1", &newName, nil)

		require.NoError(t, err)
		assert.Equal(t, "Updated Name", user.DisplayName)
	})

	t.Run("Given nonexistent ID, When updating, Then ErrNotFound is returned", func(t *testing.T) {
		repo, mock := newUserRepoMock(t)
		defer func() { assert.NoError(t, mock.ExpectationsWereMet()) }()

		mock.ExpectQuery(`UPDATE users`).
			WithArgs(anyArgs(3)...).
			WillReturnRows(pgxmock.NewRows(userColumns))

		_, err := repo.Update(context.Background(), "ghost-id", nil, nil)

		require.Error(t, err)
		assert.ErrorIs(t, err, auth.ErrNotFound)
	})
}
