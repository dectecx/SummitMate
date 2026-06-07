package trip_test

import (
	"context"
	"errors"
	"log/slog"
	"os"
	"testing"
	"time"

	"summitmate/internal/apperror"
	"summitmate/internal/auth"
	authmocks "summitmate/internal/auth/mocks"
	"summitmate/internal/trip"
	tripmocks "summitmate/internal/trip/mocks"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

func TestTripService_CreateTrip(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))

	t.Run("Given valid setup, When calling TripService CreateTrip, Then it returns success without error", func(t *testing.T) {
		mockTripRepo := new(tripmocks.MockTripRepository)
		mockMemberRepo := new(tripmocks.MockTripMemberRepository)
		mockBeginner := new(MockBeginner)
		mockTx := new(MockTx)
		mockMealDayRepo := new(tripmocks.MockTripMealPlanDayRepository)

		svc := trip.NewTripService(logger, mockBeginner, mockTripRepo, mockMemberRepo, nil, mockMealDayRepo, nil)

		userID := "user-1"
		req := &trip.TripCreateRequest{
			Name:      "Test Trip",
			StartDate: time.Now(),
		}

		mockBeginner.On("Begin", mock.Anything).Return(mockTx, nil)
		mockTx.On("Commit", mock.Anything).Return(nil)

		mockTripRepo.On("Create", mock.Anything, mock.AnythingOfType("*trip.Trip")).Return(&trip.Trip{
			ID:     "trip-1",
			Name:   req.Name,
			UserID: userID,
		}, nil)

		mockMemberRepo.On("AddMember", mock.Anything, "trip-1", userID, trip.RoleLeader).Return(nil)
		mockMealDayRepo.On("Create", mock.Anything, mock.Anything).Return(&trip.MealPlanDay{ID: "day-1"}, nil)

		tTrip, err := svc.CreateTrip(context.Background(), userID, req)

		assert.NoError(t, err)
		assert.NotNil(t, tTrip)
		assert.Equal(t, "trip-1", tTrip.ID)
		mockTripRepo.AssertExpectations(t)
		mockMemberRepo.AssertExpectations(t)
	})

	t.Run("Given database error, When calling TripService CreateTrip, Then it returns corresponding database error", func(t *testing.T) {
		mockTripRepo := new(tripmocks.MockTripRepository)
		mockBeginner := new(MockBeginner)
		mockTx := new(MockTx)
		mockMealDayRepo := new(tripmocks.MockTripMealPlanDayRepository)

		svc := trip.NewTripService(logger, mockBeginner, mockTripRepo, nil, nil, mockMealDayRepo, nil)

		mockBeginner.On("Begin", mock.Anything).Return(mockTx, nil)
		mockTx.On("Rollback", mock.Anything).Return(nil)

		mockTripRepo.On("Create", mock.Anything, mock.Anything).Return(nil, errors.New("db error"))

		tTrip, err := svc.CreateTrip(context.Background(), "u1", &trip.TripCreateRequest{Name: "Fail"})

		assert.Error(t, err)
		assert.Nil(t, tTrip)
	})
}

func TestTripService_GetTrip(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))

	t.Run("Given Success AsCreator, When calling TripService GetTrip, Then it behaves as expected", func(t *testing.T) {
		mockTripRepo := new(tripmocks.MockTripRepository)
		mockMealDayRepo := new(tripmocks.MockTripMealPlanDayRepository)
		svc := trip.NewTripService(logger, nil, mockTripRepo, nil, nil, mockMealDayRepo, nil)

		tripID := "trip-1"
		userID := "user-creator"
		mockTrip := &trip.Trip{ID: tripID, UserID: userID}
		mockMealDayRepo.On("ListByTripID", mock.Anything, tripID).Return([]*trip.MealPlanDay{}, nil)

		mockTripRepo.On("GetByID", mock.Anything, tripID).Return(mockTrip, nil)

		tTrip, err := svc.GetTrip(context.Background(), tripID, userID)

		assert.NoError(t, err)
		assert.Equal(t, mockTrip, tTrip)
	})

	t.Run("Given resource is not found, When calling TripService GetTrip, Then it returns not found error", func(t *testing.T) {
		mockTripRepo := new(tripmocks.MockTripRepository)
		mockMealDayRepo := new(tripmocks.MockTripMealPlanDayRepository)
		svc := trip.NewTripService(logger, nil, mockTripRepo, nil, nil, mockMealDayRepo, nil)

		mockTripRepo.On("GetByID", mock.Anything, "none").Return(nil, trip.ErrNotFound)

		tTrip, err := svc.GetTrip(context.Background(), "none", "any")

		assert.Error(t, err)
		assert.Equal(t, apperror.ErrTripNotFound, err)
		assert.Nil(t, tTrip)
	})
}

func TestTripService_AddMember(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))

	t.Run("Given valid setup, When calling TripService AddMember, Then it returns success without error", func(t *testing.T) {
		mockTripRepo := new(tripmocks.MockTripRepository)
		mockMemberRepo := new(tripmocks.MockTripMemberRepository)
		mockMealDayRepo := new(tripmocks.MockTripMealPlanDayRepository)
		svc := trip.NewTripService(logger, nil, mockTripRepo, mockMemberRepo, nil, mockMealDayRepo, nil)

		tripID := "trip-1"
		requesterID := "creator"
		targetUserID := "user-new"
		targetEmail := "new@example.com"

		mockTrip := &trip.Trip{ID: tripID, UserID: requesterID}
		mockTargetUser := &auth.User{ID: targetUserID, Email: targetEmail}

		mockTripRepo.On("GetByID", mock.Anything, tripID).Return(mockTrip, nil)
		mockMemberRepo.On("IsMember", mock.Anything, tripID, targetUserID).Return(false, nil)
		mockMemberRepo.On("AddMember", mock.Anything, tripID, targetUserID, trip.RoleMember).Return(nil)
		mockMemberRepo.On("ListByTripID", mock.Anything, tripID).Return([]*trip.TripMember{
			{UserID: targetUserID, UserDisplayName: mockTargetUser.DisplayName, UserEmail: mockTargetUser.Email},
		}, nil)

		member, err := svc.AddMember(context.Background(), tripID, requesterID, targetUserID)

		assert.NoError(t, err)
		assert.NotNil(t, member)
		assert.Equal(t, targetUserID, member.UserID)
	})
}

func TestTripService_DeleteMealPlanDay(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))

	t.Run("Given Success Unlinked, When calling TripService DeleteMealPlanDay, Then it behaves as expected", func(t *testing.T) {
		mockTripRepo := new(tripmocks.MockTripRepository)
		mockMemberRepo := new(tripmocks.MockTripMemberRepository)
		mockMealDayRepo := new(tripmocks.MockTripMealPlanDayRepository)
		svc := trip.NewTripService(logger, nil, mockTripRepo, mockMemberRepo, nil, mockMealDayRepo, nil)

		tripID := "trip-1"
		dayID := "day-1"
		userID := "user-1"

		mockTripRepo.On("GetByID", mock.Anything, tripID).Return(&trip.Trip{ID: tripID, UserID: "other"}, nil)
		mockMemberRepo.On("IsMember", mock.Anything, tripID, userID).Return(true, nil)
		mockMealDayRepo.On("GetByID", mock.Anything, dayID, tripID).Return(&trip.MealPlanDay{
			ID:     dayID,
			TripID: tripID,
			Name:   "Unlinked Day",
		}, nil)
		mockMealDayRepo.On("Delete", mock.Anything, dayID, tripID).Return(nil)

		err := svc.DeleteMealPlanDay(context.Background(), tripID, dayID, userID)

		assert.NoError(t, err)
		mockMealDayRepo.AssertExpectations(t)
	})

	t.Run("Given Fail Linked, When calling TripService DeleteMealPlanDay, Then it behaves as expected", func(t *testing.T) {
		mockTripRepo := new(tripmocks.MockTripRepository)
		mockMemberRepo := new(tripmocks.MockTripMemberRepository)
		mockMealDayRepo := new(tripmocks.MockTripMealPlanDayRepository)
		svc := trip.NewTripService(logger, nil, mockTripRepo, mockMemberRepo, nil, mockMealDayRepo, nil)

		tripID := "trip-1"
		dayID := "day-1"
		userID := "user-1"
		linked := "D1"

		mockTripRepo.On("GetByID", mock.Anything, tripID).Return(&trip.Trip{ID: tripID, UserID: "other"}, nil)
		mockMemberRepo.On("IsMember", mock.Anything, tripID, userID).Return(true, nil)
		mockMealDayRepo.On("GetByID", mock.Anything, dayID, tripID).Return(&trip.MealPlanDay{
			ID:                 dayID,
			TripID:             tripID,
			Name:               "D1",
			LinkedItineraryDay: &linked,
		}, nil)

		err := svc.DeleteMealPlanDay(context.Background(), tripID, dayID, userID)

		assert.Error(t, err)
		assert.Contains(t, err.Error(), "已綁定行程")
	})
}

func TestTripService_InviteMemberByEmail(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))

	t.Run("Given valid setup, When calling InviteMemberByEmail, Then it returns success", func(t *testing.T) {
		mockTripRepo := new(tripmocks.MockTripRepository)
		mockMemberRepo := new(tripmocks.MockTripMemberRepository)
		mockAuthService := new(authmocks.MockAuthService)
		mockMealDayRepo := new(tripmocks.MockTripMealPlanDayRepository)
		svc := trip.NewTripService(logger, nil, mockTripRepo, mockMemberRepo, nil, mockMealDayRepo, mockAuthService)

		tripID := "trip-1"
		requesterID := "creator"
		targetEmail := "new@example.com"
		targetUserID := "user-new"

		mockTrip := &trip.Trip{ID: tripID, UserID: requesterID}
		mockTargetUser := &auth.User{ID: targetUserID, Email: targetEmail}

		mockTripRepo.On("GetByID", mock.Anything, tripID).Return(mockTrip, nil)
		mockAuthService.On("SearchUserByEmail", mock.Anything, targetEmail).Return(mockTargetUser, nil)
		mockMemberRepo.On("AddMember", mock.Anything, tripID, targetUserID, trip.RoleMember).Return(nil)
		mockMemberRepo.On("ListByTripID", mock.Anything, tripID).Return([]*trip.TripMember{
			{UserID: targetUserID, UserEmail: targetEmail},
		}, nil)

		member, err := svc.InviteMemberByEmail(context.Background(), tripID, requesterID, targetEmail)

		assert.NoError(t, err)
		assert.NotNil(t, member)
		assert.Equal(t, targetUserID, member.UserID)
		mockAuthService.AssertExpectations(t)
		mockMemberRepo.AssertExpectations(t)
	})
}

func TestTripService_MealPlanDayACs(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))

	t.Run("AC-2: AddMealPlanDay with valid link forces name to linked day name", func(t *testing.T) {
		mockTripRepo := new(tripmocks.MockTripRepository)
		mockMemberRepo := new(tripmocks.MockTripMemberRepository)
		mockMealDayRepo := new(tripmocks.MockTripMealPlanDayRepository)
		svc := trip.NewTripService(logger, nil, mockTripRepo, mockMemberRepo, nil, mockMealDayRepo, nil)

		tripID := "trip-1"
		userID := "user-1"
		linkedDay := "D2"

		mockTripRepo.On("GetByID", mock.Anything, tripID).Return(&trip.Trip{
			ID:       tripID,
			UserID:   userID,
			DayNames: []string{"D1", "D2"},
		}, nil)
		mockMemberRepo.On("IsMember", mock.Anything, tripID, userID).Return(true, nil)

		mockMealDayRepo.On("Create", mock.Anything, mock.MatchedBy(func(d *trip.MealPlanDay) bool {
			return d.TripID == tripID && d.Name == "D2" && d.LinkedItineraryDay != nil && *d.LinkedItineraryDay == "D2"
		})).Return(&trip.MealPlanDay{ID: "day-1", TripID: tripID, Name: "D2", LinkedItineraryDay: &linkedDay}, nil)

		res, err := svc.AddMealPlanDay(context.Background(), tripID, userID, "Custom Name", &linkedDay)
		assert.NoError(t, err)
		assert.NotNil(t, res)
		assert.Equal(t, "D2", res.Name)
	})

	t.Run("AC-3: AddMealPlanDay with non-existent link returns ErrLinkedDayNotFound", func(t *testing.T) {
		mockTripRepo := new(tripmocks.MockTripRepository)
		mockMemberRepo := new(tripmocks.MockTripMemberRepository)
		svc := trip.NewTripService(logger, nil, mockTripRepo, mockMemberRepo, nil, nil, nil)

		tripID := "trip-1"
		userID := "user-1"
		linkedDay := "D3"

		mockTripRepo.On("GetByID", mock.Anything, tripID).Return(&trip.Trip{
			ID:       tripID,
			UserID:   userID,
			DayNames: []string{"D1", "D2"},
		}, nil)
		mockMemberRepo.On("IsMember", mock.Anything, tripID, userID).Return(true, nil)

		res, err := svc.AddMealPlanDay(context.Background(), tripID, userID, "Custom Name", &linkedDay)
		assert.ErrorIs(t, err, apperror.ErrLinkedDayNotFound)
		assert.Nil(t, res)
	})

	t.Run("AC-4: UpdateMealPlanDay link D1 to D2 forces name to D2", func(t *testing.T) {
		mockTripRepo := new(tripmocks.MockTripRepository)
		mockMemberRepo := new(tripmocks.MockTripMemberRepository)
		mockMealDayRepo := new(tripmocks.MockTripMealPlanDayRepository)
		svc := trip.NewTripService(logger, nil, mockTripRepo, mockMemberRepo, nil, mockMealDayRepo, nil)

		tripID := "trip-1"
		userID := "user-1"
		dayID := "day-1"
		linkedDay := "D2"

		mockTripRepo.On("GetByID", mock.Anything, tripID).Return(&trip.Trip{
			ID:       tripID,
			UserID:   userID,
			DayNames: []string{"D1", "D2"},
		}, nil)
		mockMemberRepo.On("IsMember", mock.Anything, tripID, userID).Return(true, nil)

		mockMealDayRepo.On("GetByID", mock.Anything, dayID, tripID).Return(&trip.MealPlanDay{
			ID:                 dayID,
			TripID:             tripID,
			Name:               "D1",
			LinkedItineraryDay: ptr("D1"),
		}, nil)

		mockMealDayRepo.On("Update", mock.Anything, mock.MatchedBy(func(d *trip.MealPlanDay) bool {
			return d.ID == dayID && d.Name == "D2" && d.LinkedItineraryDay != nil && *d.LinkedItineraryDay == "D2"
		})).Return(&trip.MealPlanDay{ID: dayID, TripID: tripID, Name: "D2", LinkedItineraryDay: &linkedDay}, nil)

		res, err := svc.UpdateMealPlanDay(context.Background(), tripID, dayID, userID, "Custom Name", &linkedDay)
		assert.NoError(t, err)
		assert.NotNil(t, res)
		assert.Equal(t, "D2", res.Name)
	})

	t.Run("AC-5: UpdateMealPlanDay remove link preserves custom name", func(t *testing.T) {
		mockTripRepo := new(tripmocks.MockTripRepository)
		mockMemberRepo := new(tripmocks.MockTripMemberRepository)
		mockMealDayRepo := new(tripmocks.MockTripMealPlanDayRepository)
		svc := trip.NewTripService(logger, nil, mockTripRepo, mockMemberRepo, nil, mockMealDayRepo, nil)

		tripID := "trip-1"
		userID := "user-1"
		dayID := "day-1"

		mockTripRepo.On("GetByID", mock.Anything, tripID).Return(&trip.Trip{
			ID:       tripID,
			UserID:   userID,
			DayNames: []string{"D1", "D2"},
		}, nil)
		mockMemberRepo.On("IsMember", mock.Anything, tripID, userID).Return(true, nil)

		mockMealDayRepo.On("GetByID", mock.Anything, dayID, tripID).Return(&trip.MealPlanDay{
			ID:                 dayID,
			TripID:             tripID,
			Name:               "D1",
			LinkedItineraryDay: ptr("D1"),
		}, nil)

		mockMealDayRepo.On("Update", mock.Anything, mock.MatchedBy(func(d *trip.MealPlanDay) bool {
			return d.ID == dayID && d.Name == "Preserved Name" && d.LinkedItineraryDay == nil
		})).Return(&trip.MealPlanDay{ID: dayID, TripID: tripID, Name: "Preserved Name", LinkedItineraryDay: nil}, nil)

		res, err := svc.UpdateMealPlanDay(context.Background(), tripID, dayID, userID, "Preserved Name", nil)
		assert.NoError(t, err)
		assert.NotNil(t, res)
		assert.Equal(t, "Preserved Name", res.Name)
	})

	t.Run("AC-8: UpdateTrip removes D1 from day_names auto-unlinks D1 meal plan days", func(t *testing.T) {
		mockTripRepo := new(tripmocks.MockTripRepository)
		mockMemberRepo := new(tripmocks.MockTripMemberRepository)
		mockMealDayRepo := new(tripmocks.MockTripMealPlanDayRepository)
		mockBeginner := new(MockBeginner)
		mockTx := new(MockTx)
		svc := trip.NewTripService(logger, mockBeginner, mockTripRepo, mockMemberRepo, nil, mockMealDayRepo, nil)

		tripID := "trip-1"
		userID := "user-1"

		mockBeginner.On("Begin", mock.Anything).Return(mockTx, nil)
		mockTx.On("Commit", mock.Anything).Return(nil)

		mockTripRepo.On("GetByID", mock.Anything, tripID).Return(&trip.Trip{
			ID:       tripID,
			UserID:   userID,
			DayNames: []string{"D1", "D2"},
		}, nil)
		mockMemberRepo.On("GetRole", mock.Anything, tripID, userID).Return(trip.RoleLeader, nil)

		newDayNames := []string{"D2"}
		mockTripRepo.On("Update", mock.Anything, mock.Anything, mock.Anything).Return(&trip.Trip{
			ID:       tripID,
			UserID:   userID,
			DayNames: newDayNames,
		}, nil)

		mockMealDayRepo.On("ListByTripID", mock.Anything, tripID).Return([]*trip.MealPlanDay{
			{ID: "day-1", TripID: tripID, Name: "D1", LinkedItineraryDay: ptr("D1")},
			{ID: "day-2", TripID: tripID, Name: "D2", LinkedItineraryDay: ptr("D2")},
		}, nil)

		mockMealDayRepo.On("Update", mock.Anything, mock.MatchedBy(func(d *trip.MealPlanDay) bool {
			return d.ID == "day-1" && d.LinkedItineraryDay == nil
		})).Return(&trip.MealPlanDay{}, nil)

		_, err := svc.UpdateTrip(context.Background(), tripID, userID, &trip.TripUpdateRequest{
			DayNames: &newDayNames,
		})
		assert.NoError(t, err)
	})

	t.Run("AC-9: GetTrip with orphaned link returns null for linked_itinerary_day", func(t *testing.T) {
		mockTripRepo := new(tripmocks.MockTripRepository)
		mockMemberRepo := new(tripmocks.MockTripMemberRepository)
		mockMealDayRepo := new(tripmocks.MockTripMealPlanDayRepository)
		svc := trip.NewTripService(logger, nil, mockTripRepo, mockMemberRepo, nil, mockMealDayRepo, nil)

		tripID := "trip-1"
		userID := "user-1"

		mockTripRepo.On("GetByID", mock.Anything, tripID).Return(&trip.Trip{
			ID:       tripID,
			UserID:   userID,
			DayNames: []string{"D1", "D2"},
		}, nil)
		mockMemberRepo.On("IsMember", mock.Anything, tripID, userID).Return(true, nil)

		mockMealDayRepo.On("ListByTripID", mock.Anything, tripID).Return([]*trip.MealPlanDay{
			{ID: "day-1", TripID: tripID, Name: "D3", LinkedItineraryDay: ptr("D3")},
		}, nil)

		tTrip, err := svc.GetTrip(context.Background(), tripID, userID)
		assert.NoError(t, err)
		assert.NotNil(t, tTrip)
		assert.Nil(t, tTrip.MealPlanDays[0].LinkedItineraryDay)
	})
}

func TestTripService_Permissions(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))

	t.Run("Guide can UpdateTrip but Member cannot", func(t *testing.T) {
		mockTripRepo := new(tripmocks.MockTripRepository)
		mockMemberRepo := new(tripmocks.MockTripMemberRepository)
		mockBeginner := new(MockBeginner)
		mockTx := new(MockTx)
		svc := trip.NewTripService(logger, mockBeginner, mockTripRepo, mockMemberRepo, nil, nil, nil)

		tripID := "trip-1"
		ownerID := "owner"
		guideID := "guide"
		memberID := "member"

		tripObj := &trip.Trip{ID: tripID, UserID: ownerID}

		// Mock guide request
		mockTripRepo.On("GetByID", mock.Anything, tripID).Return(tripObj, nil).Once()
		mockMemberRepo.On("GetRole", mock.Anything, tripID, guideID).Return(trip.RoleGuide, nil).Once()
		mockBeginner.On("Begin", mock.Anything).Return(mockTx, nil).Once()
		mockTx.On("Commit", mock.Anything).Return(nil).Once()
		mockTripRepo.On("Update", mock.Anything, mock.Anything, mock.Anything).Return(tripObj, nil).Once()

		_, err := svc.UpdateTrip(context.Background(), tripID, guideID, &trip.TripUpdateRequest{})
		assert.NoError(t, err)

		// Mock member request
		mockTripRepo.On("GetByID", mock.Anything, tripID).Return(tripObj, nil).Once()
		mockMemberRepo.On("GetRole", mock.Anything, tripID, memberID).Return(trip.RoleMember, nil).Once()

		_, err = svc.UpdateTrip(context.Background(), tripID, memberID, &trip.TripUpdateRequest{})
		assert.ErrorIs(t, err, apperror.ErrAccessDenied)
	})

	t.Run("Only Owner can DeleteTrip", func(t *testing.T) {
		mockTripRepo := new(tripmocks.MockTripRepository)
		mockMemberRepo := new(tripmocks.MockTripMemberRepository)
		svc := trip.NewTripService(logger, nil, mockTripRepo, mockMemberRepo, nil, nil, nil)

		tripID := "trip-1"
		ownerID := "owner"
		leaderID := "leader"

		tripObj := &trip.Trip{ID: tripID, UserID: ownerID}

		// Leader (who is not owner) tries to delete
		mockTripRepo.On("GetByID", mock.Anything, tripID).Return(tripObj, nil).Once()
		err := svc.DeleteTrip(context.Background(), tripID, leaderID)
		assert.ErrorIs(t, err, apperror.ErrAccessDenied)

		// Owner deletes
		mockTripRepo.On("GetByID", mock.Anything, tripID).Return(tripObj, nil).Once()
		mockTripRepo.On("DeleteByID", mock.Anything, tripID).Return(nil).Once()
		err = svc.DeleteTrip(context.Background(), tripID, ownerID)
		assert.NoError(t, err)
	})
}

func ptr[T any](v T) *T {
	return &v
}

