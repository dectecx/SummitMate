package e2e

import (
	"bytes"
	"context"
	"encoding/json"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/golang-migrate/migrate/v4"
	_ "github.com/golang-migrate/migrate/v4/database/postgres"
	_ "github.com/golang-migrate/migrate/v4/source/file"
	"github.com/jackc/pgx/v5/pgxpool"
	_ "github.com/jackc/pgx/v5/stdlib"
	"github.com/stretchr/testify/suite"
	"github.com/testcontainers/testcontainers-go"
	tcpostgres "github.com/testcontainers/testcontainers-go/modules/postgres"
	"github.com/testcontainers/testcontainers-go/wait"

	"summitmate/api"
	"summitmate/internal/auth"

	"summitmate/internal/config"
	"summitmate/internal/database"
	"summitmate/internal/handler"
	appMiddleware "summitmate/internal/middleware"
	"summitmate/internal/repository"
	"summitmate/internal/service"

	openapi_types "github.com/oapi-codegen/runtime/types"
)

// testServer 實作 api.ServerInterface，供測試使用
// 由於不能循環 import main，我們在 e2e 複製一份 server 注入邏輯
type testServer struct {
	authHandler     *handler.AuthHandler
	tripHandler     *handler.TripHandler
	gearHandler     *handler.GearLibraryHandler
	mealHandler     *handler.MealLibraryHandler
	tripGearHandler *handler.TripGearHandler
	tripMealHandler *handler.TripMealHandler
	messageHandler  *handler.MessageHandler
	pollHandler     *handler.PollHandler
	favoriteHandler *handler.FavoriteHandler
	groupHandler    *handler.GroupEventHandler
	weatherHandler  *handler.WeatherHandler
	logHandler      *handler.LogHandler
	heartbeatHandler *handler.HeartbeatHandler
	tokenManager    *auth.TokenManager
}

func (srv testServer) GetHealth(writer http.ResponseWriter, request *http.Request) {
	writer.Header().Set("Content-Type", "application/json")
	writer.WriteHeader(http.StatusOK)
	writer.Write([]byte(`{"status":"ok","version":"0.1.0"}`))
}

func (srv testServer) RegisterUser(writer http.ResponseWriter, request *http.Request) {
	srv.authHandler.RegisterUser(writer, request)
}

func (srv testServer) LoginUser(writer http.ResponseWriter, request *http.Request) {
	srv.authHandler.LoginUser(writer, request)
}

func (srv testServer) GetCurrentUser(writer http.ResponseWriter, request *http.Request) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(srv.authHandler.GetCurrentUser)).ServeHTTP(writer, request)
}

func (srv testServer) UpdateCurrentUser(writer http.ResponseWriter, request *http.Request) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(srv.authHandler.UpdateCurrentUser)).ServeHTTP(writer, request)
}

func (srv testServer) DeleteCurrentUser(writer http.ResponseWriter, request *http.Request) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(srv.authHandler.DeleteCurrentUser)).ServeHTTP(writer, request)
}

func (srv testServer) RefreshToken(writer http.ResponseWriter, request *http.Request) {
	srv.authHandler.RefreshToken(writer, request)
}

func (srv testServer) VerifyEmail(writer http.ResponseWriter, request *http.Request) {
	srv.authHandler.VerifyEmail(writer, request)
}

func (srv testServer) ResendVerificationCode(writer http.ResponseWriter, request *http.Request) {
	srv.authHandler.ResendVerificationCode(writer, request)
}

func (srv testServer) ListTrips(w http.ResponseWriter, r *http.Request) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(srv.tripHandler.ListTrips)).ServeHTTP(w, r)
}

func (srv testServer) CreateTrip(w http.ResponseWriter, r *http.Request) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(srv.tripHandler.CreateTrip)).ServeHTTP(w, r)
}

func (srv testServer) GetTrip(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.tripHandler.GetTrip(w, r, tripId)
	})).ServeHTTP(w, r)
}

func (srv testServer) UpdateTrip(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.tripHandler.UpdateTrip(w, r, tripId)
	})).ServeHTTP(w, r)
}

func (srv testServer) DeleteTrip(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.tripHandler.DeleteTrip(w, r, tripId)
	})).ServeHTTP(w, r)
}

func (srv testServer) ListTripMembers(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.tripHandler.ListTripMembers(w, r, tripId)
	})).ServeHTTP(w, r)
}

func (srv testServer) AddTripMember(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.tripHandler.AddTripMember(w, r, tripId)
	})).ServeHTTP(w, r)
}

func (srv testServer) RemoveTripMember(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, userId openapi_types.UUID) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.tripHandler.RemoveTripMember(w, r, tripId, userId)
	})).ServeHTTP(w, r)
}

func (srv testServer) ListItinerary(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.tripHandler.ListItinerary(w, r, tripId)
	})).ServeHTTP(w, r)
}

func (srv testServer) AddItineraryItem(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.tripHandler.AddItineraryItem(w, r, tripId)
	})).ServeHTTP(w, r)
}

func (srv testServer) UpdateItineraryItem(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, itemId openapi_types.UUID) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.tripHandler.UpdateItineraryItem(w, r, tripId, itemId)
	})).ServeHTTP(w, r)
}

func (srv testServer) DeleteItineraryItem(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, itemId openapi_types.UUID) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.tripHandler.DeleteItineraryItem(w, r, tripId, itemId)
	})).ServeHTTP(w, r)
}

// --- Gear Library ---

func (srv testServer) ListGearLibrary(w http.ResponseWriter, r *http.Request, params api.ListGearLibraryParams) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.gearHandler.ListGearLibrary(w, r, params)
	})).ServeHTTP(w, r)
}

func (srv testServer) CreateGearLibraryItem(w http.ResponseWriter, r *http.Request) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(srv.gearHandler.CreateGearLibraryItem)).ServeHTTP(w, r)
}

func (srv testServer) GetGearLibraryItem(w http.ResponseWriter, r *http.Request, itemId openapi_types.UUID) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.gearHandler.GetGearLibraryItem(w, r, itemId)
	})).ServeHTTP(w, r)
}

func (srv testServer) UpdateGearLibraryItem(w http.ResponseWriter, r *http.Request, itemId openapi_types.UUID) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.gearHandler.UpdateGearLibraryItem(w, r, itemId)
	})).ServeHTTP(w, r)
}

func (srv testServer) DeleteGearLibraryItem(w http.ResponseWriter, r *http.Request, itemId openapi_types.UUID) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.gearHandler.DeleteGearLibraryItem(w, r, itemId)
	})).ServeHTTP(w, r)
}

func (srv testServer) ReplaceAllGearLibraryItems(w http.ResponseWriter, r *http.Request) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(srv.gearHandler.ReplaceAllGearLibraryItems)).ServeHTTP(w, r)
}

// --- Meal Library ---

func (srv testServer) ListMealLibrary(w http.ResponseWriter, r *http.Request, params api.ListMealLibraryParams) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.mealHandler.ListMealLibrary(w, r, params)
	})).ServeHTTP(w, r)
}

func (srv testServer) CreateMealLibraryItem(w http.ResponseWriter, r *http.Request) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(srv.mealHandler.CreateMealLibraryItem)).ServeHTTP(w, r)
}

func (srv testServer) GetMealLibraryItem(w http.ResponseWriter, r *http.Request, itemId openapi_types.UUID) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.mealHandler.GetMealLibraryItem(w, r, itemId)
	})).ServeHTTP(w, r)
}

func (srv testServer) UpdateMealLibraryItem(w http.ResponseWriter, r *http.Request, itemId openapi_types.UUID) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.mealHandler.UpdateMealLibraryItem(w, r, itemId)
	})).ServeHTTP(w, r)
}

func (srv testServer) DeleteMealLibraryItem(w http.ResponseWriter, r *http.Request, itemId openapi_types.UUID) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.mealHandler.DeleteMealLibraryItem(w, r, itemId)
	})).ServeHTTP(w, r)
}

func (srv testServer) ReplaceAllMealLibraryItems(w http.ResponseWriter, r *http.Request) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(srv.mealHandler.ReplaceAllMealLibraryItems)).ServeHTTP(w, r)
}

// --- Trip Gear ---

func (srv testServer) ListTripGearItems(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.tripGearHandler.ListTripGear(w, r, tripId)
	})).ServeHTTP(w, r)
}

func (srv testServer) AddTripGearItem(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.tripGearHandler.AddTripGear(w, r, tripId)
	})).ServeHTTP(w, r)
}

func (srv testServer) UpdateTripGearItem(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, itemId openapi_types.UUID) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.tripGearHandler.UpdateTripGear(w, r, tripId, itemId)
	})).ServeHTTP(w, r)
}

func (srv testServer) DeleteTripGearItem(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, itemId openapi_types.UUID) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.tripGearHandler.RemoveTripGear(w, r, tripId, itemId)
	})).ServeHTTP(w, r)
}

func (srv testServer) ReplaceAllTripGear(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.tripGearHandler.ReplaceAllTripGear(w, r, tripId)
	})).ServeHTTP(w, r)
}

// --- Trip Meals ---

func (srv testServer) ListTripMealItems(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.tripMealHandler.ListTripMeals(w, r, tripId)
	})).ServeHTTP(w, r)
}

func (srv testServer) AddTripMealItem(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.tripMealHandler.AddTripMeal(w, r, tripId)
	})).ServeHTTP(w, r)
}

func (srv testServer) UpdateTripMealItem(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, itemId openapi_types.UUID) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.tripMealHandler.UpdateTripMeal(w, r, tripId, itemId)
	})).ServeHTTP(w, r)
}

func (srv testServer) DeleteTripMealItem(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, itemId openapi_types.UUID) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.tripMealHandler.RemoveTripMeal(w, r, tripId, itemId)
	})).ServeHTTP(w, r)
}

func (srv testServer) ReplaceAllTripMeals(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.tripMealHandler.ReplaceAllTripMeals(w, r, tripId)
	})).ServeHTTP(w, r)
}

// --- Trip Messages ---

func (srv testServer) ListTripMessages(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.messageHandler.ListTripMessages(w, r, tripId)
	})).ServeHTTP(w, r)
}

func (srv testServer) AddTripMessage(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.messageHandler.AddTripMessage(w, r, tripId)
	})).ServeHTTP(w, r)
}

func (srv testServer) UpdateTripMessage(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, messageId openapi_types.UUID) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.messageHandler.UpdateTripMessage(w, r, tripId, messageId)
	})).ServeHTTP(w, r)
}

func (srv testServer) DeleteTripMessage(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, messageId openapi_types.UUID) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.messageHandler.DeleteTripMessage(w, r, tripId, messageId)
	})).ServeHTTP(w, r)
}

// --- Trip Polls ---

func (srv testServer) ListTripPolls(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.pollHandler.ListTripPolls(w, r, tripId)
	})).ServeHTTP(w, r)
}

func (srv testServer) CreateTripPoll(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.pollHandler.CreateTripPoll(w, r, tripId)
	})).ServeHTTP(w, r)
}

func (srv testServer) GetTripPoll(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, pollId openapi_types.UUID) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.pollHandler.GetTripPoll(w, r, tripId, pollId)
	})).ServeHTTP(w, r)
}

func (srv testServer) DeleteTripPoll(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, pollId openapi_types.UUID) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.pollHandler.DeleteTripPoll(w, r, tripId, pollId)
	})).ServeHTTP(w, r)
}

func (srv testServer) AddPollOption(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, pollId openapi_types.UUID) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.pollHandler.AddPollOption(w, r, tripId, pollId)
	})).ServeHTTP(w, r)
}

func (srv testServer) VotePollOption(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, pollId openapi_types.UUID, optionId openapi_types.UUID) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.pollHandler.VotePollOption(w, r, tripId, pollId, optionId)
	})).ServeHTTP(w, r)
}

// --- Favorites ---

func (srv testServer) ListFavorites(w http.ResponseWriter, r *http.Request) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(srv.favoriteHandler.ListFavorites)).ServeHTTP(w, r)
}

func (srv testServer) AddFavorite(w http.ResponseWriter, r *http.Request) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(srv.favoriteHandler.AddFavorite)).ServeHTTP(w, r)
}

func (srv testServer) RemoveFavorite(w http.ResponseWriter, r *http.Request, targetId openapi_types.UUID) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.favoriteHandler.RemoveFavorite(w, r, targetId)
	})).ServeHTTP(w, r)
}

func (srv testServer) BatchUpdateFavorites(w http.ResponseWriter, r *http.Request) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(srv.favoriteHandler.BatchUpdateFavorites)).ServeHTTP(w, r)
}

// --- Group Events ---

func (srv testServer) GetGroupEvents(w http.ResponseWriter, r *http.Request, params api.GetGroupEventsParams) {
	srv.groupHandler.GetGroupEvents(w, r, params)
}

func (srv testServer) PostGroupEvents(w http.ResponseWriter, r *http.Request) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(srv.groupHandler.PostGroupEvents)).ServeHTTP(w, r)
}

func (srv testServer) GetGroupEventsId(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	srv.groupHandler.GetGroupEventsId(w, r, id)
}

func (srv testServer) PatchGroupEventsId(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.groupHandler.PatchGroupEventsId(w, r, id)
	})).ServeHTTP(w, r)
}

func (srv testServer) DeleteGroupEventsId(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.groupHandler.DeleteGroupEventsId(w, r, id)
	})).ServeHTTP(w, r)
}

func (srv testServer) PostGroupEventsIdApply(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.groupHandler.PostGroupEventsIdApply(w, r, id)
	})).ServeHTTP(w, r)
}

func (srv testServer) GetGroupEventsIdApplications(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.groupHandler.GetGroupEventsIdApplications(w, r, id)
	})).ServeHTTP(w, r)
}

func (srv testServer) PatchGroupEventsApplicationsAppId(w http.ResponseWriter, r *http.Request, appId openapi_types.UUID) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.groupHandler.PatchGroupEventsApplicationsAppId(w, r, appId)
	})).ServeHTTP(w, r)
}

func (srv testServer) GetGroupEventsIdComments(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	srv.groupHandler.GetGroupEventsIdComments(w, r, id)
}

func (srv testServer) PostGroupEventsIdComments(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.groupHandler.PostGroupEventsIdComments(w, r, id)
	})).ServeHTTP(w, r)
}

func (srv testServer) DeleteGroupEventsCommentsCommentId(w http.ResponseWriter, r *http.Request, commentId openapi_types.UUID) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.groupHandler.DeleteGroupEventsCommentsCommentId(w, r, commentId)
	})).ServeHTTP(w, r)
}

func (srv testServer) PostGroupEventsIdLike(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		srv.groupHandler.PostGroupEventsIdLike(w, r, id)
	})).ServeHTTP(w, r)
}

// --- Weather (Public) ---

func (srv testServer) GetHikingWeather(w http.ResponseWriter, r *http.Request) {
	srv.weatherHandler.GetHikingWeather(w, r)
}

func (srv testServer) GetHikingWeatherByLocation(w http.ResponseWriter, r *http.Request, location string) {
	srv.weatherHandler.GetHikingWeatherByLocation(w, r, location)
}

func (srv testServer) UploadLogs(w http.ResponseWriter, r *http.Request) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(srv.logHandler.UploadLogs)).ServeHTTP(w, r)
}

func (srv testServer) Heartbeat(w http.ResponseWriter, r *http.Request) {
	jwtAuth := appMiddleware.JWTAuth(srv.tokenManager)
	jwtAuth(http.HandlerFunc(srv.heartbeatHandler.Heartbeat)).ServeHTTP(w, r)
}

// APITestSuite 定義了 E2E 測試的 Suite
type APITestSuite struct {
	suite.Suite
	pgContainer *tcpostgres.PostgresContainer
	dbPool      *pgxpool.Pool
	ts          *httptest.Server
	baseURL     string
}

// SetupSuite 在所有測試開始前執行一次（初始化 TestContainers, DB, Server）
func (s *APITestSuite) SetupSuite() {
	cfg := config.Load()

	ctx := context.Background()

	// 1. 啟動 PostgreSQL 測試容器
	// postgres module 會自帶適合的 wait strategy 判定 DB 是否就緒
	pgContainer, err := tcpostgres.Run(ctx,
		"postgres:18-alpine",
		tcpostgres.WithDatabase("test_db"),
		tcpostgres.WithUsername("test_user"),
		tcpostgres.WithPassword("test_password"),
		testcontainers.WithWaitStrategy(
			wait.ForLog("database system is ready to accept connections").
				WithOccurrence(2).
				WithStartupTimeout(60*time.Second),
		),
	)
	s.Require().NoError(err, "無法啟動測試用 PostgreSQL 容器")
	s.pgContainer = pgContainer

	connStr, err := pgContainer.ConnectionString(ctx, "sslmode=disable")
	s.Require().NoError(err, "無法取得測試容器連線字串")

	s.T().Logf("Testcontainer DB URL: %s", connStr)

	// 2. 執行 Database Migration
	// 注意：在 `tests/e2e` 目錄執行時，相對路徑需往上兩層
	m, err := migrate.New(
		"file://../../migrations",
		connStr,
	)
	s.Require().NoError(err, "無法初始化 migration")
	if err := m.Up(); err != nil && err != migrate.ErrNoChange {
		s.Require().NoError(err, "執行 migration up 失敗")
	}

	// 3. 連線 dbPool
	pool, err := database.Connect(ctx, connStr)
	s.Require().NoError(err, "無法連接至測試資料庫")
	s.dbPool = pool

	// 初始化 Domain 邏輯
	userRepo := repository.NewUserRepository(pool)
	tripRepo := repository.NewTripRepository(pool)
	memberRepo := repository.NewTripMemberRepository(pool)
	itineraryRepo := repository.NewItineraryRepository(pool)
	gearLibRepo := repository.NewGearLibraryRepository(pool)
	mealLibRepo := repository.NewMealLibraryRepository(pool)
	tripGearRepo := repository.NewTripGearRepository(pool)
	tripMealRepo := repository.NewTripMealRepository(pool)
	messageRepo := repository.NewMessageRepository(pool)
	pollRepo := repository.NewPollRepository(pool)
	favoriteRepo := repository.NewFavoriteRepository(pool)
	groupRepo := repository.NewGroupEventRepository(pool)
	weatherRepo := repository.NewWeatherRepository(pool)
	heartbeatRepo := repository.NewHeartbeatRepository(pool)
	tokenManager := auth.NewTokenManager(cfg.JWTSecret)

	authService := service.NewAuthService(slog.Default(), userRepo, tokenManager)
	tripService := service.NewTripService(slog.Default(), tripRepo, memberRepo, itineraryRepo, userRepo)
	gearLibService := service.NewGearLibraryService(slog.Default(), gearLibRepo)
	mealLibService := service.NewMealLibraryService(slog.Default(), mealLibRepo)
	tripGearService := service.NewTripGearService(slog.Default(), tripGearRepo, tripRepo, memberRepo)
	tripMealService := service.NewTripMealService(slog.Default(), tripMealRepo, tripRepo, memberRepo)
	messageService := service.NewMessageService(slog.Default(), messageRepo, tripRepo, memberRepo)
	pollService := service.NewPollService(slog.Default(), pollRepo, tripRepo, memberRepo)
	favoriteService := service.NewFavoriteService(slog.Default(), favoriteRepo)
	groupService := service.NewGroupEventService(slog.Default(), groupRepo)
	weatherService := service.NewWeatherService(slog.Default(), weatherRepo, cfg.CWAApiKey)
	heartbeatService := service.NewHeartbeatService(slog.Default(), heartbeatRepo)

	authHandler := handler.NewAuthHandler(authService)
	tripHandler := handler.NewTripHandler(tripService)
	gearHandler := handler.NewGearLibraryHandler(gearLibService)
	mealHandler := handler.NewMealLibraryHandler(mealLibService)
	tripGearHandler := handler.NewTripGearHandler(tripGearService)
	tripMealHandler := handler.NewTripMealHandler(tripMealService)
	messageHandler := handler.NewMessageHandler(messageService)
	pollHandler := handler.NewPollHandler(pollService)
	favoriteHandler := handler.NewFavoriteHandler(favoriteService)
	groupHandler := handler.NewGroupEventHandler(groupService)
	weatherHandler := handler.NewWeatherHandler(weatherService)
	logRepo := repository.NewLogRepository(pool)
	logService := service.NewLogService(logRepo)
	logHandler := handler.NewLogHandler(logService)
	heartbeatHandler := handler.NewHeartbeatHandler(heartbeatService)

	srv := testServer{
		authHandler:     authHandler,
		tripHandler:     tripHandler,
		gearHandler:     gearHandler,
		mealHandler:     mealHandler,
		tripGearHandler: tripGearHandler,
		tripMealHandler: tripMealHandler,
		messageHandler:  messageHandler,
		pollHandler:     pollHandler,
		favoriteHandler: favoriteHandler,
		groupHandler:    groupHandler,
		weatherHandler:  weatherHandler,
		logHandler:      logHandler,
		heartbeatHandler: heartbeatHandler,
		tokenManager:    tokenManager,
	}

	router := chi.NewRouter()

	swagger, err := api.GetSwagger()
	s.Require().NoError(err, "無法載入 OpenAPI 規格")
	swagger.Servers = nil

	// OapiRequestValidator 需要 import oapimiddleware
	// 假設有額外依賴 github.com/oapi-codegen/nethttp-middleware
	router.Route("/api/v1", func(r chi.Router) {
		// r.Use(oapimiddleware.OapiRequestValidator(swagger)) // 若無法 resolve，先拔掉 validator
		api.HandlerFromMux(srv, r)
	})

	s.ts = httptest.NewServer(router)
	s.baseURL = s.ts.URL + "/api/v1"
}

// TearDownSuite 在所有測試結束後執行
func (s *APITestSuite) TearDownSuite() {
	if s.ts != nil {
		s.ts.Close()
	}
	if s.dbPool != nil {
		s.dbPool.Close()
	}
	if s.pgContainer != nil {
		if os.Getenv("KEEP_TEST_DB") == "true" {
			s.T().Log("⚠️ KEEP_TEST_DB=true: 測試容器不會被關閉，方便除錯。請手動清理 Docker 內的 postgres 容器。")
		} else {
			_ = s.pgContainer.Terminate(context.Background())
		}
	}
}

// SetupTest 在每個測試開始前執行（清理資料表或做準備）
func (s *APITestSuite) SetupTest() {
	ctx := context.Background()
	// 清理資料表以確保測試隔離，改用 DELETE 避免 TRUNCATE 的 Access Exclusive Lock 卡住
	cleanupSQL := `
		DELETE FROM group_event_likes;
		DELETE FROM group_event_comments;
		DELETE FROM group_event_applications;
		DELETE FROM group_events;
		DELETE FROM poll_votes;
		DELETE FROM poll_options;
		DELETE FROM polls;
		DELETE FROM messages;
		DELETE FROM favorites;
		DELETE FROM itinerary_items;
		DELETE FROM trip_members;
		DELETE FROM trips;
		DELETE FROM users;
		DELETE FROM heartbeats;
	`
	_, err := s.dbPool.Exec(ctx, cleanupSQL)
	s.Require().NoError(err, "清理測試資料庫失敗")
}

// --- Shared Helpers ---

// registerAndLogin 註冊並登入，回傳 token 及 userID
func (s *APITestSuite) registerAndLogin(displayName string) (token string, userID string) {
	email := randomEmail()
	password := "TestPassword123!"
	// 註冊取得 token
	regPayload, _ := json.Marshal(api.RegisterRequest{
		Email:       openapi_types.Email(email),
		Password:    password,
		DisplayName: displayName,
	})
	regResp, _ := http.Post(s.baseURL+"/auth/register", "application/json", bytes.NewReader(regPayload))
	defer regResp.Body.Close()

	if regResp.StatusCode != http.StatusCreated {
		s.T().Fatalf("測試用註冊失敗: %d", regResp.StatusCode)
	}
	var authResp api.AuthResponse
	json.NewDecoder(regResp.Body).Decode(&authResp)

	return authResp.Token, authResp.User.Id.String()
}

// createTripForTest 建立行程，回傳 tripID
func (s *APITestSuite) createTripForTest(token string) string {
	payload, _ := json.Marshal(map[string]interface{}{
		"name":       "互動測試行程",
		"start_date": "2026-06-01",
	})
	req, _ := http.NewRequest("POST", s.baseURL+"/trips", bytes.NewReader(payload))
	req.Header.Set("Authorization", "Bearer "+token)
	req.Header.Set("Content-Type", "application/json")
	resp, err := http.DefaultClient.Do(req)
	s.Require().NoError(err)
	defer resp.Body.Close()
	s.Require().Equal(http.StatusCreated, resp.StatusCode, "建立行程應回傳 201")

	var trip map[string]interface{}
	json.NewDecoder(resp.Body).Decode(&trip)
	id, ok := trip["id"].(string)
	s.Require().True(ok, "行程回應應包含 id 欄位")
	return id
}

// doRequest 發送 HTTP 請求的共用封裝
func (s *APITestSuite) doRequest(method, url string, body interface{}, token string) *http.Response {
	var reqBody *bytes.Reader
	if body != nil {
		b, _ := json.Marshal(body)
		reqBody = bytes.NewReader(b)
	} else {
		reqBody = bytes.NewReader([]byte{})
	}

	req, _ := http.NewRequest(method, url, reqBody)
	req.Header.Set("Authorization", "Bearer "+token)
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	resp, err := http.DefaultClient.Do(req)
	s.Require().NoError(err)
	return resp
}

// 供 auth_test.go 執行 Suite 的入口
func TestE2ESuite(t *testing.T) {
	suite.Run(t, new(APITestSuite))
}
