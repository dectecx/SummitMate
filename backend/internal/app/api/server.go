package api

import (
	"summitmate/internal/auth"
	"summitmate/internal/auth/tokens"
	"summitmate/internal/handler"
	"summitmate/internal/interaction"
	"summitmate/internal/library"
	"summitmate/internal/trip"
)

// Server 實作 api.ServerInterface，作為各個 Domain Handler 的聚合器 (Glue Layer)
type Server struct {
	AuthHandler        *auth.AuthHandler
	TripHandler        *trip.TripHandler
	LibraryHandler     *library.LibraryHandler
	InteractionHandler *interaction.InteractionHandler

	// Legacy Handlers (pending migration)
	TripGearHandler  *trip.TripGearHandler
	TripMealHandler  *trip.TripMealHandler
	FavoriteHandler  *handler.FavoriteHandler
	GroupHandler     *handler.GroupEventHandler
	WeatherHandler   *handler.WeatherHandler
	LogHandler       *handler.LogHandler
	HeartbeatHandler *handler.HeartbeatHandler

	TokenManager *tokens.TokenManager
}

func NewServer(
	authH *auth.AuthHandler,
	tripH *trip.TripHandler,
	libH *library.LibraryHandler,
	interH *interaction.InteractionHandler,
	gearH *trip.TripGearHandler,
	mealH *trip.TripMealHandler,
	favH *handler.FavoriteHandler,
	groupH *handler.GroupEventHandler,
	weatherH *handler.WeatherHandler,
	logH *handler.LogHandler,
	hbH *handler.HeartbeatHandler,
	tm *tokens.TokenManager,
) *Server {
	return &Server{
		AuthHandler:        authH,
		TripHandler:        tripH,
		LibraryHandler:     libH,
		InteractionHandler: interH,
		TripGearHandler:    gearH,
		TripMealHandler:    mealH,
		FavoriteHandler:    favH,
		GroupHandler:       groupH,
		WeatherHandler:     weatherH,
		LogHandler:         logH,
		HeartbeatHandler:   hbH,
		TokenManager:       tm,
	}
}
