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
			UserID:     "user-1",
			Visibility: VisibilityPublic,
		}
	
		createdGS, err := service.Create(context.Background(), gs)
	
		assert.NoError(t, err)
		assert.NotNil(t, createdGS)
	
		// Verify the mock was called
		mockRepo.AssertExpectations(t)
		mockAuth.AssertExpectations(t)
	
		// Verify the ID is a UUID v7
		assert.NotEqual(t, uuid.Nil, capturedGS.ID)
		assert.Equal(t, uuid.Version(7), capturedGS.ID.Version(), "UUID must be version 7")
	})
}
