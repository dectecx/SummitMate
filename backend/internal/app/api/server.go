package api

import (
	"summitmate/internal/auth"
	"summitmate/internal/auth/tokens"
	"summitmate/internal/favorite"
	"summitmate/internal/flag"
	"summitmate/internal/gearset"
	"summitmate/internal/groupevent"
	"summitmate/internal/heartbeat"
	"summitmate/internal/interaction"
	"summitmate/internal/library"
	"summitmate/internal/log"
	"summitmate/internal/trip"
	"summitmate/internal/weather"
	"summitmate/pkg/cache"
)

// Server 實作 api.ServerInterface，作為各個 Domain Handler 的聚合器 (Glue Layer)
type Server struct {
	AuthHandler        *auth.AuthHandler
	TripHandler        *trip.TripHandler
	LibraryHandler     *library.LibraryHandler
	InteractionHandler *interaction.InteractionHandler
	FlagHandler        *flag.FlagHandler

	// Feature Handlers
	TripGearHandler  *trip.TripGearHandler
	TripMealHandler  *trip.TripMealHandler
	FavoriteHandler  *favorite.FavoriteHandler
	GroupHandler     *groupevent.GroupEventHandler
	WeatherHandler   *weather.WeatherHandler
	LogHandler       *log.LogHandler
	HeartbeatHandler *heartbeat.HeartbeatHandler

	// Cloud
	GearSetHandler *gearset.GearSetHandler

	TokenManager   *tokens.TokenManager
	TokenBlacklist cache.TokenBlacklist
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
	flagH *flag.FlagHandler,
	gearSetH *gearset.GearSetHandler,
	tm             *tokens.TokenManager,
	tokenBlacklist cache.TokenBlacklist,
) *Server {
	return &Server{
		AuthHandler:        authH,
		TripHandler:        tripH,
		LibraryHandler:     libH,
		InteractionHandler: interH,
		FlagHandler:        flagH,
		TripGearHandler:    gearH,
		TripMealHandler:    mealH,
		FavoriteHandler:    favH,
		GroupHandler:       groupH,
		WeatherHandler:     weatherH,
		LogHandler:         logH,
		HeartbeatHandler:   hbH,
		GearSetHandler:     gearSetH,
		TokenManager:       tm,
		TokenBlacklist:     tokenBlacklist,
	}
}
