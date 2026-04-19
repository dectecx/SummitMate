package api

import (
	"summitmate/internal/auth"
	"summitmate/internal/auth/tokens"
	"summitmate/internal/favorite"
	"summitmate/internal/groupevent"
	"summitmate/internal/heartbeat"
	"summitmate/internal/interaction"
	"summitmate/internal/library"
	"summitmate/internal/log"
	"summitmate/internal/trip"
	"summitmate/internal/weather"
)

// Server 實作 api.ServerInterface，作為各個 Domain Handler 的聚合器 (Glue Layer)
type Server struct {
	AuthHandler        *auth.AuthHandler
	TripHandler        *trip.TripHandler
	LibraryHandler     *library.LibraryHandler
	InteractionHandler *interaction.InteractionHandler

	// Feature Handlers
	TripGearHandler  *trip.TripGearHandler
	TripMealHandler  *trip.TripMealHandler
	FavoriteHandler  *favorite.FavoriteHandler
	GroupHandler     *groupevent.GroupEventHandler
	WeatherHandler   *weather.WeatherHandler
	LogHandler       *log.LogHandler
	HeartbeatHandler *heartbeat.HeartbeatHandler

	TokenManager *tokens.TokenManager
}

func NewServer(
	authH *auth.AuthHandler,
	tripH *trip.TripHandler,
	libH *library.LibraryHandler,
	interH *interaction.InteractionHandler,
	gearH *trip.TripGearHandler,
	mealH *trip.TripMealHandler,
	favH *favorite.FavoriteHandler,
	groupH *groupevent.GroupEventHandler,
	weatherH *weather.WeatherHandler,
	logH *log.LogHandler,
	hbH *heartbeat.HeartbeatHandler,
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
