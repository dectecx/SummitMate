package app

import (
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"summitmate/api"
	appapi "summitmate/internal/app/api"
	"summitmate/internal/auth"
	"summitmate/internal/auth/tokens"
	"summitmate/internal/config"
	"summitmate/internal/database"
	"summitmate/internal/favorite"
	"summitmate/internal/groupevent"
	"summitmate/internal/heartbeat"
	"summitmate/internal/interaction"
	"summitmate/internal/library"
	"summitmate/internal/log"
	"summitmate/internal/middleware"
	"summitmate/internal/trip"
	"summitmate/internal/weather"
	"summitmate/pkg/cache"
	"summitmate/pkg/email"

	"github.com/go-chi/chi/v5"
	chiMiddleware "github.com/go-chi/chi/v5/middleware"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/getkin/kin-openapi/openapi3"
)

type App struct {
	Config *config.Config
	Logger *slog.Logger
	Pool   *pgxpool.Pool
	Server *http.Server
}

func NewApp(cfg *config.Config, logger *slog.Logger) (*App, error) {
	pool, err := database.Connect(context.Background(), cfg.DatabaseURL)
	if err != nil {
		return nil, fmt.Errorf("database connection failed: %w", err)
	}

	app := &App{
		Config: cfg,
		Logger: logger,
		Pool:   pool,
	}

	return app, nil
}

func (a *App) InitRouter() *chi.Mux {
	apiServer := a.initializeAPI()

	router := chi.NewRouter()
	router.Use(chiMiddleware.RequestID)
	router.Use(middleware.ContextLogger(a.Logger))
	router.Use(middleware.RequestLogger(a.Logger))
	router.Use(middleware.CORS(a.Config.AllowedOrigins))
	router.Use(chiMiddleware.Recoverer)

	// API Handler
	apiHandler := api.HandlerWithOptions(apiServer, api.ChiServerOptions{
		BaseURL: "/api/v1",
		Middlewares: []api.MiddlewareFunc{
			middleware.JWTAuth(apiServer.TokenManager),
		},
	})
	router.Mount("/", apiHandler)

	// Health check (Special case, not part of ServerInterface for simplicity here)
	router.Get("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]string{"status": "ok", "version": "1.0.0"})
	})

	return router
}

func (a *App) Run() error {
	router := a.InitRouter()

	// Scalar API Reference & OpenAPI JSON
	a.setupDocs(router)

	a.Server = &http.Server{
		Addr:    a.Config.Addr(),
		Handler: router,
	}

	// Graceful shutdown
	go func() {
		sigChan := make(chan os.Signal, 1)
		signal.Notify(sigChan, os.Interrupt, syscall.SIGTERM)
		<-sigChan

		a.Logger.Info("Shutting down server...")
		ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()

		if err := a.Server.Shutdown(ctx); err != nil {
			a.Logger.Error("Server forced to shutdown", "error", err)
		}
	}()

	a.Logger.Info("SummitMate API is running", "addr", a.Config.Addr(), "env", a.Config.Env)
	return a.Server.ListenAndServe()
}

func (a *App) setupDocs(router *chi.Mux) {
	router.Get("/openapi.json", func(w http.ResponseWriter, r *http.Request) {
		swagger, err := api.GetSwagger()
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		// Dynamically set the server to a relative path.
		// This ensures the API explorer works regardless of the domain it's hosted on.
		swagger.Servers = []*openapi3.Server{
			{URL: "/api/v1", Description: "Auto-detected"},
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(swagger)
	})

	router.Get("/docs", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "text/html; charset=utf-8")
		w.Write([]byte(`<!doctype html>
<html>
<head>
  <title>SummitMate API Reference</title>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
</head>
<body>
  <div id="app"></div>
  <script src="https://cdn.jsdelivr.net/npm/@scalar/api-reference"></script>
  <script>
    Scalar.createApiReference('#app', {
      url: '/openapi.json',
      theme: 'kepler',
    })
  </script>
</body>
</html>`))
	})
}

func (a *App) initializeAPI() *appapi.Server {
	pool := a.Pool
	cfg := a.Config
	logger := a.Logger

	// --- Repositories ---
	authRepo := auth.NewUserRepository(pool)
	tripRepo := trip.NewTripRepository(pool)
	tripMemberRepo := trip.NewTripMemberRepository(pool)
	tripItineraryRepo := trip.NewItineraryRepository(pool)
	gearLibRepo := library.NewGearLibraryRepository(pool)
	mealLibRepo := library.NewMealLibraryRepository(pool)
	messageRepo := interaction.NewMessageRepository(pool)
	pollRepo := interaction.NewPollRepository(pool)

	// --- Feature Repositories ---
	tripGearRepo := trip.NewTripGearRepository(pool)
	tripMealRepo := trip.NewTripMealRepository(pool)
	favoriteRepo := favorite.NewFavoriteRepository(pool)
	groupRepo := groupevent.NewGroupEventRepository(pool)
	weatherRepo := weather.NewWeatherRepository(pool)
	logRepo := log.NewLogRepository(pool)
	heartbeatRepo := heartbeat.NewHeartbeatRepository(pool)

	// --- Utilities ---
	tokenManager := tokens.NewTokenManager(cfg.JWTSecret)

	smtpCfg := email.SMTPConfig{
		Host: cfg.SMTPHost, Port: cfg.SMTPPort,
		Username: cfg.SMTPUser, Password: cfg.SMTPPass, From: cfg.SMTPFrom,
	}
	mailer := email.NewMailer(smtpCfg)
	templateManager, _ := email.NewTemplateManager()
	emailService := email.NewEmailService(mailer, templateManager)

	authCache, _ := cache.NewCache[string](cache.Config{
		Type:      cache.Provider(cfg.CacheType),
		RedisAddr: cfg.RedisAddr, RedisPassword: cfg.RedisPassword, RedisDB: cfg.RedisDB,
	})

	// --- Services ---
	authService := auth.NewAuthService(logger, authRepo, tokenManager, emailService, authCache, cfg.JWTSecret)
	tripService := trip.NewTripService(logger, tripRepo, tripMemberRepo, tripItineraryRepo, authRepo)
	gearLibService := library.NewGearLibraryService(logger, gearLibRepo)
	mealLibService := library.NewMealLibraryService(logger, mealLibRepo)
	messageService := interaction.NewMessageService(logger, messageRepo, tripRepo, tripMemberRepo)
	pollService := interaction.NewPollService(logger, pollRepo, tripRepo, tripMemberRepo)

	// --- Feature Services ---
	tripGearService := trip.NewTripGearService(logger, tripGearRepo, tripRepo, tripMemberRepo)
	tripMealService := trip.NewTripMealService(logger, tripMealRepo, tripRepo, tripMemberRepo)
	favoriteService := favorite.NewFavoriteService(logger, favoriteRepo)
	groupService := groupevent.NewGroupEventService(logger, groupRepo)
	weatherService := weather.NewWeatherService(logger, weatherRepo, cfg.CWAApiKey, nil)
	logService := log.NewLogService(logger, logRepo)
	heartbeatService := heartbeat.NewHeartbeatService(logger, heartbeatRepo)

	// --- Handlers ---
	authHandler := auth.NewAuthHandler(authService)
	tripHandler := trip.NewTripHandler(tripService)
	libraryHandler := library.NewLibraryHandler(gearLibService, mealLibService)
	interactionHandler := interaction.NewInteractionHandler(messageService, pollService)

	// --- Feature Handlers ---
	tripGearHandler := trip.NewTripGearHandler(tripGearService)
	tripMealHandler := trip.NewTripMealHandler(tripMealService)
	favoriteHandler := favorite.NewFavoriteHandler(favoriteService)
	groupHandler := groupevent.NewGroupEventHandler(groupService)
	weatherHandler := weather.NewWeatherHandler(weatherService)
	logHandler := log.NewLogHandler(logService)
	heartbeatHandler := heartbeat.NewHeartbeatHandler(heartbeatService)

	return appapi.NewServer(
		authHandler, tripHandler, libraryHandler, interactionHandler,
		tripGearHandler, tripMealHandler, favoriteHandler,
		groupHandler, weatherHandler, logHandler, heartbeatHandler,
		tokenManager,
	)
}
