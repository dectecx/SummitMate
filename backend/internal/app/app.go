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
	"summitmate/internal/flag"
	"summitmate/internal/gearset"
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

	"github.com/getkin/kin-openapi/openapi3"
	"github.com/go-chi/chi/v5"
	chiMiddleware "github.com/go-chi/chi/v5/middleware"
	"github.com/jackc/pgx/v5/pgxpool"
)

type App struct {
	Config *config.Config
	Logger *slog.Logger
	Pool   *pgxpool.Pool
	Server *http.Server
}

func NewApp(cfg *config.Config, logger *slog.Logger) (*App, error) {
	initCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	pool, err := database.Connect(initCtx, cfg.DatabaseURL)
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

func (a *App) InitRouter() (*chi.Mux, error) {
	apiServer, err := a.initializeAPI()
	if err != nil {
		return nil, err
	}

	router := chi.NewRouter()
	router.Use(chiMiddleware.RequestID)
	router.Use(middleware.ContextLogger(a.Logger))
	router.Use(middleware.RequestLogger(a.Logger))
	router.Use(middleware.CORS(a.Config.AllowedOrigins))
	router.Use(chiMiddleware.Timeout(30 * time.Second))
	router.Use(chiMiddleware.Recoverer)

	// API Handler
	apiHandler := api.HandlerWithOptions(apiServer, api.ChiServerOptions{
		BaseURL: "/api/v1",
		Middlewares: []api.MiddlewareFunc{
			middleware.JWTAuth(apiServer.TokenManager, apiServer.AuthCache),
		},
	})
	router.Mount("/", apiHandler)

	// Basic Health check (Uses logic from ServerInterface but mounted at root)
	router.Get("/health", apiServer.GetHealth)

	return router, nil
}

func (a *App) Run() error {
	router, err := a.InitRouter()
	if err != nil {
		return err
	}

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

func (a *App) initializeAPI() (*appapi.Server, error) {
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
	tripMealDayRepo := trip.NewTripMealPlanDayRepository(pool)
	favoriteRepo := favorite.NewFavoriteRepository(pool)
	groupRepo := groupevent.NewGroupEventRepository(pool)
	weatherRepo := weather.NewWeatherRepository(pool)
	logRepo := log.NewLogRepository(pool)
	heartbeatRepo := heartbeat.NewHeartbeatRepository(pool)
	flagRepo := flag.NewFlagRepository(pool)
	gearSetRepo := gearset.NewGearSetRepository(pool)

	// --- Utilities ---
	tokenManager := tokens.NewTokenManager(cfg.JWTSecret)

	smtpCfg := email.SMTPConfig{
		Host: cfg.SMTPHost, Port: cfg.SMTPPort,
		Username: cfg.SMTPUser, Password: cfg.SMTPPass, From: cfg.SMTPFrom,
		UseSSL: cfg.SMTPUseSSL,
	}
	mailer := email.NewMailer(smtpCfg)
	templateManager, err := email.NewTemplateManager()
	if err != nil {
		return nil, fmt.Errorf("failed to initialize email template manager: %w", err)
	}
	emailService := email.NewEmailService(mailer, templateManager)

	authCache, err := cache.NewCache[string](cache.Config{
		Type:          cache.Provider(cfg.CacheType),
		RedisAddr:     cfg.RedisAddr,
		RedisPassword: cfg.RedisPassword,
		RedisDB:       cfg.RedisDB,
	})
	if err != nil {
		return nil, fmt.Errorf("failed to initialize auth cache: %w", err)
	}

	flagService := flag.NewFlagService(flagRepo, logger)

	// --- Services ---
	authService := auth.NewAuthService(logger, authRepo, tokenManager, emailService, authCache, flagService, cfg.JWTSecret)
	tripService := trip.NewTripService(logger, pool, tripRepo, tripMemberRepo, tripItineraryRepo, tripMealDayRepo, authService)
	tripAccessChecker := trip.NewTripAccessChecker(tripRepo, tripMemberRepo)
	gearLibService := library.NewGearLibraryService(logger, gearLibRepo)
	mealLibService := library.NewMealLibraryService(logger, mealLibRepo)
	messageService := interaction.NewMessageService(logger, messageRepo, tripAccessChecker)
	pollService := interaction.NewPollService(logger, pollRepo, tripAccessChecker)

	// --- Feature Services ---
	tripGearService := trip.NewTripGearService(logger, tripGearRepo, tripAccessChecker)
	tripMealService := trip.NewTripMealService(logger, tripMealRepo, tripAccessChecker)
	favoriteService := favorite.NewFavoriteService(logger, pool, favoriteRepo)
	groupService := groupevent.NewGroupEventService(logger, pool, groupRepo, tripService, authService)
	httpClient := &http.Client{
		Timeout: 30 * time.Second,
	}

	weatherService := weather.NewWeatherService(logger, pool, weatherRepo, httpClient, cfg.CWAApiKey, nil)
	logService := log.NewLogService(logger, logRepo)
	heartbeatService := heartbeat.NewHeartbeatService(logger, heartbeatRepo)
	gearSetService := gearset.NewGearSetService(logger, gearSetRepo, authService)

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
	flagHandler := flag.NewFlagHandler(flagService)
	gearSetHandler := gearset.NewGearSetHandler(gearSetService)

	return appapi.NewServer(
		authHandler, tripHandler, libraryHandler, interactionHandler,
		tripGearHandler, tripMealHandler, favoriteHandler,
		groupHandler, weatherHandler, logHandler, heartbeatHandler,
		flagHandler, gearSetHandler,
		tokenManager,
		authCache,
	), nil
}
