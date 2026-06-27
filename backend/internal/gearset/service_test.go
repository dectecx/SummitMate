package gearset

import (
	"context"
	"log/slog"
	"testing"

	"summitmate/internal/auth"
	authmocks "summitmate/internal/auth/mocks"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

func TestGearSetService_Create_UUIDv7(t *testing.T) {
	t.Run("Given a request to create a gear set, When calling Create, Then it should generate a valid UUIDv7 ID", func(t *testing.T) {
		mockRepo := new(MockGearSetRepository)
		mockAuth := new(authmocks.MockAuthService)
		service := NewGearSetService(slog.Default(), mockRepo, mockAuth)

		// Expect the auth mock to return a user with a DisplayName
		mockAuth.On("GetUserByID", mock.Anything, "user-1").Return(&auth.User{
			ID:          "user-1",
			DisplayName: "Test User",
		}, nil).Once()

		// Expect the mock to be called with a GearSet
		// We capture the passed GearSet to verify its ID
		var capturedGS *GearSet
		mockRepo.On("Create", mock.Anything, mock.AnythingOfType("*gearset.GearSet")).Run(func(args mock.Arguments) {
			capturedGS = args.Get(1).(*GearSet)
		}).Return(nil)

		gs := &GearSet{
			Title:      "Test Gear Set",
			Visibility: VisibilityPublic,
		}

		createdGS, err := service.Create(context.Background(), gs, "user-1")

		assert.NoError(t, err)
		assert.NotNil(t, createdGS)

		// Verify the mock was called
		mockRepo.AssertExpectations(t)
		mockAuth.AssertExpectations(t)

		// Verify audit fields are set by service
		assert.Equal(t, "user-1", capturedGS.UserID)
		assert.Equal(t, "user-1", capturedGS.CreatedBy)
		assert.Equal(t, "user-1", capturedGS.UpdatedBy)

		// Verify the ID is a UUID v7
		assert.NotEqual(t, uuid.Nil, capturedGS.ID)
		assert.Equal(t, uuid.Version(7), capturedGS.ID.Version(), "UUID must be version 7")
	})
}

func TestGearSetService_Update(t *testing.T) {
	t.Run("Given valid owner update request, When calling Update, Then it updates successfully and recalculates weight", func(t *testing.T) {
		mockRepo := new(MockGearSetRepository)
		mockAuth := new(authmocks.MockAuthService)
		service := NewGearSetService(slog.Default(), mockRepo, mockAuth)

		gsID := uuid.Must(uuid.NewV7())
		existingGS := &GearSet{
			ID:         gsID,
			UserID:     "user-1",
			Visibility: VisibilityPublic,
		}

		mockRepo.On("GetByID", mock.Anything, gsID).Return(existingGS, nil).Once()
		mockAuth.On("GetUserByID", mock.Anything, "user-1").Return(&auth.User{
			ID:          "user-1",
			DisplayName: "Test User",
		}, nil).Once()

		updatedGS := &GearSet{
			ID:         gsID,
			Title:      "Updated Title",
			Visibility: VisibilityPublic,
			Items: []GearSetItem{
				{Weight: 1.5, Quantity: 2},
				{Weight: 2.0, Quantity: 1},
			},
		}

		mockRepo.On("Update", mock.Anything, mock.AnythingOfType("*gearset.GearSet")).Return(nil).Once()

		res, err := service.Update(context.Background(), updatedGS, "user-1")

		assert.NoError(t, err)
		assert.Equal(t, 5.0, res.TotalWeight) // 1.5*2 + 2.0*1 = 5.0
		assert.Equal(t, 2, res.ItemCount)
		assert.Equal(t, "Test User", res.Author)
		mockRepo.AssertExpectations(t)
		mockAuth.AssertExpectations(t)
	})

	t.Run("Given non-owner update request, When calling Update, Then it returns error", func(t *testing.T) {
		mockRepo := new(MockGearSetRepository)
		mockAuth := new(authmocks.MockAuthService)
		service := NewGearSetService(slog.Default(), mockRepo, mockAuth)

		gsID := uuid.Must(uuid.NewV7())
		existingGS := &GearSet{
			ID:     gsID,
			UserID: "user-1",
		}

		mockRepo.On("GetByID", mock.Anything, gsID).Return(existingGS, nil).Once()

		updatedGS := &GearSet{
			ID: gsID,
		}

		_, err := service.Update(context.Background(), updatedGS, "user-2")
		assert.ErrorContains(t, err, "only the owner can update this gear set")
	})

	t.Run("Given protected visibility and missing download key, When calling Update, Then it returns validation error", func(t *testing.T) {
		mockRepo := new(MockGearSetRepository)
		mockAuth := new(authmocks.MockAuthService)
		service := NewGearSetService(slog.Default(), mockRepo, mockAuth)

		gsID := uuid.Must(uuid.NewV7())
		existingGS := &GearSet{
			ID:         gsID,
			UserID:     "user-1",
			Visibility: VisibilityPublic,
		}

		mockRepo.On("GetByID", mock.Anything, gsID).Return(existingGS, nil).Once()
		mockAuth.On("GetUserByID", mock.Anything, "user-1").Return(&auth.User{
			ID:          "user-1",
			DisplayName: "Test User",
		}, nil).Once()

		updatedGS := &GearSet{
			ID:         gsID,
			Visibility: VisibilityProtected, // requires download key
		}

		_, err := service.Update(context.Background(), updatedGS, "user-1")
		assert.ErrorContains(t, err, "download_key is required for protected gear sets")
	})
}

func TestGearSetService_GetByID(t *testing.T) {
	t.Run("Given gear set is owned by requester, When calling GetByID, Then it returns success", func(t *testing.T) {
		mockRepo := new(MockGearSetRepository)
		mockAuth := new(authmocks.MockAuthService)
		service := NewGearSetService(slog.Default(), mockRepo, mockAuth)

		gsID := uuid.Must(uuid.NewV7())
		expected := &GearSet{
			ID:         gsID,
			UserID:     "user-1",
			Visibility: VisibilityPrivate,
		}

		mockRepo.On("GetByID", mock.Anything, gsID).Return(expected, nil).Once()

		res, err := service.GetByID(context.Background(), gsID, "user-1", nil)
		assert.NoError(t, err)
		assert.Equal(t, expected, res)
	})

	t.Run("Given gear set is private and requested by non-owner, When calling GetByID, Then it returns error", func(t *testing.T) {
		mockRepo := new(MockGearSetRepository)
		mockAuth := new(authmocks.MockAuthService)
		service := NewGearSetService(slog.Default(), mockRepo, mockAuth)

		gsID := uuid.Must(uuid.NewV7())
		expected := &GearSet{
			ID:         gsID,
			UserID:     "user-1",
			Visibility: VisibilityPrivate,
		}

		mockRepo.On("GetByID", mock.Anything, gsID).Return(expected, nil).Once()

		_, err := service.GetByID(context.Background(), gsID, "user-2", nil)
		assert.ErrorContains(t, err, "gear set is private")
	})

	t.Run("Given gear set is protected and requested with correct key, When calling GetByID, Then it returns success", func(t *testing.T) {
		mockRepo := new(MockGearSetRepository)
		mockAuth := new(authmocks.MockAuthService)
		service := NewGearSetService(slog.Default(), mockRepo, mockAuth)

		gsID := uuid.Must(uuid.NewV7())
		key := "secret-key"
		expected := &GearSet{
			ID:          gsID,
			UserID:      "user-1",
			Visibility:  VisibilityProtected,
			DownloadKey: &key,
		}

		mockRepo.On("GetByID", mock.Anything, gsID).Return(expected, nil).Once()

		res, err := service.GetByID(context.Background(), gsID, "user-2", &key)
		assert.NoError(t, err)
		assert.Equal(t, expected, res)
	})

	t.Run("Given gear set is protected and requested with incorrect key, When calling GetByID, Then it returns error", func(t *testing.T) {
		mockRepo := new(MockGearSetRepository)
		mockAuth := new(authmocks.MockAuthService)
		service := NewGearSetService(slog.Default(), mockRepo, mockAuth)

		gsID := uuid.Must(uuid.NewV7())
		key := "secret-key"
		wrongKey := "wrong-key"
		expected := &GearSet{
			ID:          gsID,
			UserID:      "user-1",
			Visibility:  VisibilityProtected,
			DownloadKey: &key,
		}

		mockRepo.On("GetByID", mock.Anything, gsID).Return(expected, nil).Once()

		_, err := service.GetByID(context.Background(), gsID, "user-2", &wrongKey)
		assert.ErrorContains(t, err, "invalid or missing download_key")
	})
}

func TestGearSetService_Delete(t *testing.T) {
	t.Run("Given owner deletes gear set, When calling Delete, Then it succeeds", func(t *testing.T) {
		mockRepo := new(MockGearSetRepository)
		mockAuth := new(authmocks.MockAuthService)
		service := NewGearSetService(slog.Default(), mockRepo, mockAuth)

		gsID := uuid.Must(uuid.NewV7())
		expected := &GearSet{
			ID:     gsID,
			UserID: "user-1",
		}

		mockRepo.On("GetByID", mock.Anything, gsID).Return(expected, nil).Once()
		mockRepo.On("Delete", mock.Anything, gsID).Return(nil).Once()

		err := service.Delete(context.Background(), gsID, "user-1")
		assert.NoError(t, err)
		mockRepo.AssertExpectations(t)
	})

	t.Run("Given non-owner deletes gear set, When calling Delete, Then it returns error", func(t *testing.T) {
		mockRepo := new(MockGearSetRepository)
		mockAuth := new(authmocks.MockAuthService)
		service := NewGearSetService(slog.Default(), mockRepo, mockAuth)

		gsID := uuid.Must(uuid.NewV7())
		expected := &GearSet{
			ID:     gsID,
			UserID: "user-1",
		}

		mockRepo.On("GetByID", mock.Anything, gsID).Return(expected, nil).Once()

		err := service.Delete(context.Background(), gsID, "user-2")
		assert.ErrorContains(t, err, "only the owner can delete this gear set")
	})
}

func TestGearSetService_List(t *testing.T) {
	t.Run("Given request list, When calling List, Then it passes params correctly", func(t *testing.T) {
		mockRepo := new(MockGearSetRepository)
		mockAuth := new(authmocks.MockAuthService)
		service := NewGearSetService(slog.Default(), mockRepo, mockAuth)

		userID := "user-1"
		expectedList := []*GearSet{
			{UserID: userID, Title: "Set 1"},
		}

		mockRepo.On("List", mock.Anything, 10, 0, "search", &userID).Return(expectedList, 1, nil).Once()

		res, total, err := service.List(context.Background(), 10, 0, "search", userID, true)
		assert.NoError(t, err)
		assert.Equal(t, expectedList, res)
		assert.Equal(t, 1, total)
		mockRepo.AssertExpectations(t)
	})

	t.Run("Given request list without myUploadedOnly, When calling List, Then it passes nil filterUserID", func(t *testing.T) {
		mockRepo := new(MockGearSetRepository)
		mockAuth := new(authmocks.MockAuthService)
		service := NewGearSetService(slog.Default(), mockRepo, mockAuth)

		expectedList := []*GearSet{
			{UserID: "user-1", Title: "Set 1"},
		}

		mockRepo.On("List", mock.Anything, 10, 0, "search", (*string)(nil)).Return(expectedList, 1, nil).Once()

		res, total, err := service.List(context.Background(), 10, 0, "search", "user-1", false)
		assert.NoError(t, err)
		assert.Equal(t, expectedList, res)
		assert.Equal(t, 1, total)
		mockRepo.AssertExpectations(t)
	})
}
