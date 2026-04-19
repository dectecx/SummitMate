package trip

import (
	"context"
	"log/slog"
	"os"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

func TestTripGearService_ListItems(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
	mockRepo := new(MockTripGearRepository)
	mockTripRepo := new(MockTripRepository)
	mockMemberRepo := new(MockTripMemberRepository)
	svc := NewTripGearService(logger, mockRepo, mockTripRepo, mockMemberRepo)
	t.Run("Success", func(t *testing.T) {
		tripID := "t1"
		userID := "u1"
		mockTripRepo.On("GetByID", mock.Anything, tripID).Return(&Trip{ID: tripID, UserID: userID}, nil)
		mockRepo.On("ListByTripID", mock.Anything, tripID).Return([]*TripGearItem{
			{ID: "tg1", Name: "Rope"},
		}, nil)
		res, err := svc.ListItems(context.Background(), tripID, userID)
		assert.NoError(t, err)
		assert.Len(t, res, 1)
		assert.Equal(t, "Rope", res[0].Name)
	})
}
func TestTripGearService_CreateItem(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
	mockRepo := new(MockTripGearRepository)
	mockTripRepo := new(MockTripRepository)
	mockMemberRepo := new(MockTripMemberRepository)
	svc := NewTripGearService(logger, mockRepo, mockTripRepo, mockMemberRepo)
	t.Run("Success", func(t *testing.T) {
		tripID := "t1"
		userID := "u1"
		item := &TripGearItem{Name: "Carabiner"}
		mockTripRepo.On("GetByID", mock.Anything, tripID).Return(&Trip{ID: tripID, UserID: userID}, nil)
		mockRepo.On("Create", mock.Anything, mock.MatchedBy(func(g *TripGearItem) bool {
			return g.Name == "Carabiner" && g.TripID == tripID
		})).Return(&TripGearItem{ID: "tg1", Name: "Carabiner", TripID: tripID}, nil)
		res, err := svc.CreateItem(context.Background(), tripID, userID, item)
		assert.NoError(t, err)
		assert.NotNil(t, res)
		assert.Equal(t, "tg1", res.ID)
	})
}
func TestTripGearService_ReplaceAllItems(t *testing.T) {
	logger := slog.New(slog.NewTextHandler(os.Stdout, nil))
	mockRepo := new(MockTripGearRepository)
	mockTripRepo := new(MockTripRepository)
	mockMemberRepo := new(MockTripMemberRepository)
	svc := NewTripGearService(logger, mockRepo, mockTripRepo, mockMemberRepo)
	t.Run("Success", func(t *testing.T) {
		tripID := "t1"
		userID := "u1"
		items := []*TripGearItem{
			{ID: "tg1", Name: "Rope"},
			{ID: "tg2", Name: "Harness"},
		}
		mockTripRepo.On("GetByID", mock.Anything, tripID).Return(&Trip{ID: tripID, UserID: userID}, nil)
		mockRepo.On("ReplaceAll", mock.Anything, tripID, mock.MatchedBy(func(args []*TripGearItem) bool {
			return len(args) == 2 && args[0].Name == "Rope" && args[1].Name == "Harness"
		})).Return(nil)
		err := svc.ReplaceAllItems(context.Background(), tripID, userID, items)
		assert.NoError(t, err)
		mockRepo.AssertExpectations(t)
	})
}
