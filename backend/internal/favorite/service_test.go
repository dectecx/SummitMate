package favorite

import (
	"context"
	"errors"
	"log/slog"
	"os"
	"testing"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

type MockBeginner struct {
	mock.Mock
}

func (m *MockBeginner) Begin(ctx context.Context) (pgx.Tx, error) {
	args := m.Called(ctx)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(pgx.Tx), args.Error(1)
}

type MockTx struct {
	mock.Mock
}

func (m *MockTx) Begin(ctx context.Context) (pgx.Tx, error) { return nil, nil }
func (m *MockTx) Commit(ctx context.Context) error          { return m.Called(ctx).Error(0) }
func (m *MockTx) Rollback(ctx context.Context) error        { return m.Called(ctx).Error(0) }
func (m *MockTx) CopyFrom(ctx context.Context, tableName pgx.Identifier, columnNames []string, rowSrc pgx.CopyFromSource) (int64, error) {
	return 0, nil
}
func (m *MockTx) SendBatch(ctx context.Context, b *pgx.Batch) pgx.BatchResults { return nil }
func (m *MockTx) LargeObjects() pgx.LargeObjects                               { return pgx.LargeObjects{} }
func (m *MockTx) Prepare(ctx context.Context, name, sql string) (*pgconn.StatementDescription, error) {
	return nil, nil
}
func (m *MockTx) Exec(ctx context.Context, sql string, arguments ...any) (pgconn.CommandTag, error) {
	return pgconn.CommandTag{}, nil
}
func (m *MockTx) Query(ctx context.Context, sql string, args ...any) (pgx.Rows, error) {
	return nil, nil
}
func (m *MockTx) QueryRow(ctx context.Context, sql string, args ...any) pgx.Row {
	return nil
}
func (m *MockTx) Conn() *pgx.Conn { return nil }

func TestFavoriteService_AddFavorite(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
	mockRepo := new(MockFavoriteRepository)
	mockDB := new(MockBeginner)
	svc := NewFavoriteService(logger, mockDB, mockRepo)

	t.Run("Given valid setup, When calling FavoriteService AddFavorite, Then it returns success without error", func(t *testing.T) {
		userID := "user-1"
		targetID := "target-1"
		favType := TypeMountain

		mockRepo.On("Create", mock.Anything, mock.AnythingOfType("*favorite.Favorite")).Return(nil).Once()

		result, err := svc.AddFavorite(context.Background(), userID, targetID, favType)

		assert.NoError(t, err)
		assert.NotNil(t, result)
		assert.Equal(t, userID, result.UserID)
		assert.Equal(t, targetID, result.TargetID)
		mockRepo.AssertExpectations(t)
	})
}

func TestFavoriteService_RemoveFavorite(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
	mockRepo := new(MockFavoriteRepository)
	mockDB := new(MockBeginner)
	svc := NewFavoriteService(logger, mockDB, mockRepo)

	t.Run("Given valid setup, When calling FavoriteService RemoveFavorite, Then it returns success without error", func(t *testing.T) {
		userID := "user-1"
		targetID := "target-1"
		favType := TypeMountain

		mockRepo.On("DeleteByTargetAndUser", mock.Anything, targetID, userID, favType).Return(nil).Once()

		err := svc.RemoveFavorite(context.Background(), targetID, userID, favType)

		assert.NoError(t, err)
		mockRepo.AssertExpectations(t)
	})
}

func TestFavoriteService_ListFavorites(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
	mockRepo := new(MockFavoriteRepository)
	mockDB := new(MockBeginner)
	svc := NewFavoriteService(logger, mockDB, mockRepo)

	t.Run("Given valid setup, When calling ListFavorites, Then it returns lists from repository", func(t *testing.T) {
		userID := "user-1"
		page := 1
		limit := 10
		expectedList := []*Favorite{
			{UserID: userID, TargetID: "t1", Type: TypeMountain},
		}

		mockRepo.On("ListByUserID", mock.Anything, userID, page, limit).Return(expectedList, 1, false, nil).Once()

		res, count, hasMore, err := svc.ListFavorites(context.Background(), userID, page, limit)

		assert.NoError(t, err)
		assert.Equal(t, expectedList, res)
		assert.Equal(t, 1, count)
		assert.False(t, hasMore)
		mockRepo.AssertExpectations(t)
	})
}

func TestFavoriteService_BatchUpdateFavorites(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
	mockRepo := new(MockFavoriteRepository)

	t.Run("Given transaction succeeds, When calling BatchUpdateFavorites, Then it executes batch update and commits", func(t *testing.T) {
		mockDB := new(MockBeginner)
		mockTx := new(MockTx)
		svc := NewFavoriteService(logger, mockDB, mockRepo)
		userID := "user-1"
		items := []BatchFavoriteItem{
			{TargetID: "t1", Type: TypeMountain, IsFavorite: true},
		}

		mockDB.On("Begin", mock.Anything).Return(mockTx, nil).Once()
		mockRepo.On("BatchUpdate", mock.Anything, userID, items).Return(nil).Once()
		mockTx.On("Commit", mock.Anything).Return(nil).Once()

		err := svc.BatchUpdateFavorites(context.Background(), userID, items)

		assert.NoError(t, err)
		mockDB.AssertExpectations(t)
		mockTx.AssertExpectations(t)
		mockRepo.AssertExpectations(t)
	})

	t.Run("Given batch update fails, When calling BatchUpdateFavorites, Then it rolls back and returns error", func(t *testing.T) {
		mockDB := new(MockBeginner)
		mockTx := new(MockTx)
		svc := NewFavoriteService(logger, mockDB, mockRepo)
		userID := "user-1"
		items := []BatchFavoriteItem{
			{TargetID: "t1", Type: TypeMountain, IsFavorite: true},
		}
		expectedErr := errors.New("batch error")

		mockDB.On("Begin", mock.Anything).Return(mockTx, nil).Once()
		mockRepo.On("BatchUpdate", mock.Anything, userID, items).Return(expectedErr).Once()
		mockTx.On("Rollback", mock.Anything).Return(nil).Once()

		err := svc.BatchUpdateFavorites(context.Background(), userID, items)

		assert.ErrorIs(t, err, expectedErr)
		mockDB.AssertExpectations(t)
		mockTx.AssertExpectations(t)
		mockRepo.AssertExpectations(t)
	})
}

