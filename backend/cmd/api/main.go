package main

import (
	"context"
	"encoding/json"
	"log/slog"
	"net/http"
	"os"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"

	"summitmate/api"
	"summitmate/internal/auth"
	"summitmate/internal/config"
	"summitmate/internal/database"
	"summitmate/internal/handler"
	appLogger "summitmate/internal/logger"
	appMiddleware "summitmate/internal/middleware"
	"summitmate/internal/repository"
	"summitmate/internal/service"
	"summitmate/pkg/email"

	openapi_types "github.com/oapi-codegen/runtime/types"
)

// server 實作 api.ServerInterface，串接各模組的 Handler。
type server struct {
	authHandler      *handler.AuthHandler
	tripHandler      *handler.TripHandler
	gearHandler      *handler.GearLibraryHandler
	mealHandler      *handler.MealLibraryHandler
	tripGearHandler  *handler.TripGearHandler
	tripMealHandler  *handler.TripMealHandler
	messageHandler   *handler.MessageHandler
	pollHandler      *handler.PollHandler
	favoriteHandler  *handler.FavoriteHandler
	groupHandler     *handler.GroupEventHandler
	weatherHandler   *handler.WeatherHandler
	logHandler       *handler.LogHandler
	heartbeatHandler *handler.HeartbeatHandler
	tokenManager     *auth.TokenManager
}

// GetHealth 處理 GET /health — 健康檢查端點。
func (srv server) GetHealth(writer http.ResponseWriter, request *http.Request) {
	writer.Header().Set("Content-Type", "application/json")
	writer.WriteHeader(http.StatusOK)
	json.NewEncoder(writer).Encode(api.HealthResponse{
		Status:  "ok",
		Version: "0.1.0",
	})
}

// RegisterUser 處理 POST /auth/register — 使用者註冊。
func (srv server) RegisterUser(writer http.ResponseWriter, request *http.Request) {
	srv.authHandler.RegisterUser(writer, request)
}

// LoginUser 處理 POST /auth/login — 使用者登入。
func (srv server) LoginUser(writer http.ResponseWriter, request *http.Request) {
	srv.authHandler.LoginUser(writer, request)
}

// GetCurrentUser 處理 GET /auth/me — 取得當前登入使用者 (需 JWT)。
// 使用 inline middleware 進行 JWT 驗證，以避免影響公開端點。
func (srv server) GetCurrentUser(writer http.ResponseWriter, request *http.Request) {
	srv.authHandler.GetCurrentUser(writer, request)
}

// UpdateCurrentUser 處理 PUT /auth/me — 更新當前使用者資料 (需 JWT)。
func (srv server) UpdateCurrentUser(writer http.ResponseWriter, request *http.Request) {
	srv.authHandler.UpdateCurrentUser(writer, request)
}

// DeleteCurrentUser 處理 DELETE /auth/me — 停用當前使用者帳號 (需 JWT)。
func (srv server) DeleteCurrentUser(writer http.ResponseWriter, request *http.Request) {
	srv.authHandler.DeleteCurrentUser(writer, request)
}

// RefreshToken 處理 POST /auth/refresh — 刷新 JWT Token (不需 JWT)。
func (srv server) RefreshToken(writer http.ResponseWriter, request *http.Request) {
	srv.authHandler.RefreshToken(writer, request)
}

// VerifyEmail 處理 POST /auth/verify-email — 驗證使用者信箱 (Stub)。
func (srv server) VerifyEmail(writer http.ResponseWriter, request *http.Request) {
	srv.authHandler.VerifyEmail(writer, request)
}

// ResendVerificationCode 處理 POST /auth/resend-verification — 重發驗證碼 (Stub)。
func (srv server) ResendVerificationCode(writer http.ResponseWriter, request *http.Request) {
	srv.authHandler.ResendVerificationCode(writer, request)
}

// --- Trips ---

func (srv server) ListTrips(w http.ResponseWriter, r *http.Request) {
	srv.tripHandler.ListTrips(w, r)
}

func (srv server) CreateTrip(w http.ResponseWriter, r *http.Request) {
	srv.tripHandler.CreateTrip(w, r)
}

func (srv server) GetTrip(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	srv.tripHandler.GetTrip(w, r, tripId)
}

func (srv server) UpdateTrip(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	srv.tripHandler.UpdateTrip(w, r, tripId)
}

func (srv server) DeleteTrip(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	srv.tripHandler.DeleteTrip(w, r, tripId)
}

// --- Trip Members ---

func (srv server) ListTripMembers(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	srv.tripHandler.ListTripMembers(w, r, tripId)
}

func (srv server) AddTripMember(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	srv.tripHandler.AddTripMember(w, r, tripId)
}

func (srv server) RemoveTripMember(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, userId openapi_types.UUID) {
	srv.tripHandler.RemoveTripMember(w, r, tripId, userId)
}

// --- Itinerary ---

func (srv server) ListItinerary(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	srv.tripHandler.ListItinerary(w, r, tripId)
}

func (srv server) AddItineraryItem(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	srv.tripHandler.AddItineraryItem(w, r, tripId)
}

func (srv server) UpdateItineraryItem(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, itemId openapi_types.UUID) {
	srv.tripHandler.UpdateItineraryItem(w, r, tripId, itemId)
}

func (srv server) DeleteItineraryItem(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, itemId openapi_types.UUID) {
	srv.tripHandler.DeleteItineraryItem(w, r, tripId, itemId)
}

// --- Gear Library ---

func (srv server) ListGearLibrary(w http.ResponseWriter, r *http.Request, params api.ListGearLibraryParams) {
	srv.gearHandler.ListGearLibrary(w, r, params)
}

func (srv server) CreateGearLibraryItem(w http.ResponseWriter, r *http.Request) {
	srv.gearHandler.CreateGearLibraryItem(w, r)
}

func (srv server) GetGearLibraryItem(w http.ResponseWriter, r *http.Request, itemId openapi_types.UUID) {
	srv.gearHandler.GetGearLibraryItem(w, r, itemId)
}

func (srv server) UpdateGearLibraryItem(w http.ResponseWriter, r *http.Request, itemId openapi_types.UUID) {
	srv.gearHandler.UpdateGearLibraryItem(w, r, itemId)
}

func (srv server) DeleteGearLibraryItem(w http.ResponseWriter, r *http.Request, itemId openapi_types.UUID) {
	srv.gearHandler.DeleteGearLibraryItem(w, r, itemId)
}

func (srv server) ReplaceAllGearLibraryItems(w http.ResponseWriter, r *http.Request) {
	srv.gearHandler.ReplaceAllGearLibraryItems(w, r)
}

// --- Meal Library ---

func (srv server) ListMealLibrary(w http.ResponseWriter, r *http.Request, params api.ListMealLibraryParams) {
	srv.mealHandler.ListMealLibrary(w, r, params)
}

func (srv server) CreateMealLibraryItem(w http.ResponseWriter, r *http.Request) {
	srv.mealHandler.CreateMealLibraryItem(w, r)
}

func (srv server) GetMealLibraryItem(w http.ResponseWriter, r *http.Request, itemId openapi_types.UUID) {
	srv.mealHandler.GetMealLibraryItem(w, r, itemId)
}

func (srv server) UpdateMealLibraryItem(w http.ResponseWriter, r *http.Request, itemId openapi_types.UUID) {
	srv.mealHandler.UpdateMealLibraryItem(w, r, itemId)
}

func (srv server) DeleteMealLibraryItem(w http.ResponseWriter, r *http.Request, itemId openapi_types.UUID) {
	srv.mealHandler.DeleteMealLibraryItem(w, r, itemId)
}

func (srv server) ReplaceAllMealLibraryItems(w http.ResponseWriter, r *http.Request) {
	srv.mealHandler.ReplaceAllMealLibraryItems(w, r)
}

// --- Trip Gear ---

func (srv server) ListTripGearItems(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	srv.tripGearHandler.ListTripGear(w, r, tripId)
}

func (srv server) AddTripGearItem(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	srv.tripGearHandler.AddTripGear(w, r, tripId)
}

func (srv server) UpdateTripGearItem(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, itemId openapi_types.UUID) {
	srv.tripGearHandler.UpdateTripGear(w, r, tripId, itemId)
}

func (srv server) DeleteTripGearItem(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, itemId openapi_types.UUID) {
	srv.tripGearHandler.RemoveTripGear(w, r, tripId, itemId)
}

func (srv server) ReplaceAllTripGear(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	srv.tripGearHandler.ReplaceAllTripGear(w, r, tripId)
}

// --- Trip Meals ---

func (srv server) ListTripMealItems(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	srv.tripMealHandler.ListTripMeals(w, r, tripId)
}

func (srv server) AddTripMealItem(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	srv.tripMealHandler.AddTripMeal(w, r, tripId)
}

func (srv server) UpdateTripMealItem(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, itemId openapi_types.UUID) {
	srv.tripMealHandler.UpdateTripMeal(w, r, tripId, itemId)
}

func (srv server) DeleteTripMealItem(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, itemId openapi_types.UUID) {
	srv.tripMealHandler.RemoveTripMeal(w, r, tripId, itemId)
}

func (srv server) ReplaceAllTripMeals(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	srv.tripMealHandler.ReplaceAllTripMeals(w, r, tripId)
}

// --- Interaction API Stubs ---

func (srv server) ListTripMessages(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	srv.messageHandler.ListTripMessages(w, r, tripId)
}

func (srv server) AddTripMessage(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	srv.messageHandler.AddTripMessage(w, r, tripId)
}

func (srv server) UpdateTripMessage(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, messageId openapi_types.UUID) {
	srv.messageHandler.UpdateTripMessage(w, r, tripId, messageId)
}

func (srv server) DeleteTripMessage(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, messageId openapi_types.UUID) {
	srv.messageHandler.DeleteTripMessage(w, r, tripId, messageId)
}

func (srv server) ListTripPolls(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	srv.pollHandler.ListTripPolls(w, r, tripId)
}

func (srv server) CreateTripPoll(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	srv.pollHandler.CreateTripPoll(w, r, tripId)
}

func (srv server) GetTripPoll(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, pollId openapi_types.UUID) {
	srv.pollHandler.GetTripPoll(w, r, tripId, pollId)
}

func (srv server) DeleteTripPoll(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, pollId openapi_types.UUID) {
	srv.pollHandler.DeleteTripPoll(w, r, tripId, pollId)
}

func (srv server) AddPollOption(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, pollId openapi_types.UUID) {
	srv.pollHandler.AddPollOption(w, r, tripId, pollId)
}

func (srv server) VotePollOption(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, pollId openapi_types.UUID, optionId openapi_types.UUID) {
	srv.pollHandler.VotePollOption(w, r, tripId, pollId, optionId)
}

func (srv server) ListFavorites(w http.ResponseWriter, r *http.Request) {
	srv.favoriteHandler.ListFavorites(w, r)
}

func (srv server) AddFavorite(w http.ResponseWriter, r *http.Request) {
	srv.favoriteHandler.AddFavorite(w, r)
}

func (srv server) RemoveFavorite(w http.ResponseWriter, r *http.Request, targetId openapi_types.UUID) {
	srv.favoriteHandler.RemoveFavorite(w, r, targetId)
}

func (srv server) BatchUpdateFavorites(w http.ResponseWriter, r *http.Request) {
	srv.favoriteHandler.BatchUpdateFavorites(w, r)
}

// --- Group Events ---

func (srv server) GetGroupEvents(w http.ResponseWriter, r *http.Request, params api.GetGroupEventsParams) {
	srv.groupHandler.GetGroupEvents(w, r, params)
}

func (srv server) PostGroupEvents(w http.ResponseWriter, r *http.Request) {
	srv.groupHandler.PostGroupEvents(w, r)
}

func (srv server) GetGroupEventsId(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	srv.groupHandler.GetGroupEventsId(w, r, id)
}

func (srv server) PatchGroupEventsId(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	srv.groupHandler.PatchGroupEventsId(w, r, id)
}

func (srv server) DeleteGroupEventsId(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	srv.groupHandler.DeleteGroupEventsId(w, r, id)
}

func (srv server) PostGroupEventsIdApply(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	srv.groupHandler.PostGroupEventsIdApply(w, r, id)
}

func (srv server) GetGroupEventsIdApplications(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	srv.groupHandler.GetGroupEventsIdApplications(w, r, id)
}

func (srv server) PatchGroupEventsApplicationsAppId(w http.ResponseWriter, r *http.Request, appId openapi_types.UUID) {
	srv.groupHandler.PatchGroupEventsApplicationsAppId(w, r, appId)
}

func (srv server) GetGroupEventsIdComments(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	srv.groupHandler.GetGroupEventsIdComments(w, r, id)
}

func (srv server) PostGroupEventsIdComments(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	srv.groupHandler.PostGroupEventsIdComments(w, r, id)
}

func (srv server) DeleteGroupEventsCommentsCommentId(w http.ResponseWriter, r *http.Request, commentId openapi_types.UUID) {
	srv.groupHandler.DeleteGroupEventsCommentsCommentId(w, r, commentId)
}

func (srv server) PostGroupEventsIdLike(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	srv.groupHandler.PostGroupEventsIdLike(w, r, id)
}

// --- Weather (Public) ---

func (srv server) GetHikingWeather(w http.ResponseWriter, r *http.Request) {
	srv.weatherHandler.GetHikingWeather(w, r)
}

func (srv server) GetHikingWeatherByLocation(w http.ResponseWriter, r *http.Request, location string) {
	srv.weatherHandler.GetHikingWeatherByLocation(w, r, location)
}

func (srv server) UploadLogs(w http.ResponseWriter, r *http.Request) {
	srv.logHandler.UploadLogs(w, r)
}

func (srv server) Heartbeat(w http.ResponseWriter, r *http.Request) {
	srv.heartbeatHandler.Heartbeat(w, r)
}

func main() {
	// 載入設定 (環境變數 + 預設值)
	cfg := config.Load()

	// 初始化 slog Logger
	logger := appLogger.NewLogger(cfg.Env)
	slog.SetDefault(logger)

	// 連線資料庫
	ctx := context.Background()
	pool, err := database.Connect(ctx, cfg.DatabaseURL)
	if err != nil {
		slog.Error("資料庫連線失敗", "error", err)
		os.Exit(1)
	}
	defer pool.Close()

	// 初始化各層依賴
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

	// Email 服務初始化
	smtpCfg := email.SMTPConfig{
		Host:     cfg.SMTPHost,
		Port:     cfg.SMTPPort,
		Username: cfg.SMTPUser,
		Password: cfg.SMTPPass,
		From:     cfg.SMTPFrom,
	}
	mailer := email.NewMailer(smtpCfg)
	templateManager, err := email.NewTemplateManager()
	if err != nil {
		slog.Error("Email 模板管理員初始化失敗", "error", err)
		os.Exit(1)
	}
	emailService := email.NewEmailService(mailer, templateManager)

	authService := service.NewAuthService(logger, userRepo, tokenManager, emailService, cfg.JWTSecret)
	tripService := service.NewTripService(logger, tripRepo, memberRepo, itineraryRepo, userRepo)
	gearLibService := service.NewGearLibraryService(logger, gearLibRepo)
	mealLibService := service.NewMealLibraryService(logger, mealLibRepo)
	tripGearService := service.NewTripGearService(logger, tripGearRepo, tripRepo, memberRepo)
	tripMealService := service.NewTripMealService(logger, tripMealRepo, tripRepo, memberRepo)
	messageService := service.NewMessageService(logger, messageRepo, tripRepo, memberRepo)
	pollService := service.NewPollService(logger, pollRepo, tripRepo, memberRepo)
	favoriteService := service.NewFavoriteService(logger, favoriteRepo)
	groupService := service.NewGroupEventService(logger, groupRepo)
	weatherService := service.NewWeatherService(logger, weatherRepo, cfg.CWAApiKey, nil)
	logRepo := repository.NewLogRepository(pool)
	logService := service.NewLogService(logger, logRepo)
	heartbeatService := service.NewHeartbeatService(logger, heartbeatRepo)

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
	logHandler := handler.NewLogHandler(logService)
	heartbeatHandler := handler.NewHeartbeatHandler(heartbeatService)

	srv := server{
		authHandler:      authHandler,
		tripHandler:      tripHandler,
		gearHandler:      gearHandler,
		mealHandler:      mealHandler,
		tripGearHandler:  tripGearHandler,
		tripMealHandler:  tripMealHandler,
		messageHandler:   messageHandler,
		pollHandler:      pollHandler,
		favoriteHandler:  favoriteHandler,
		groupHandler:     groupHandler,
		weatherHandler:   weatherHandler,
		logHandler:       logHandler,
		heartbeatHandler: heartbeatHandler,
		tokenManager:     tokenManager,
	}

	// 設定 Router
	router := chi.NewRouter()
	router.Use(middleware.RequestID)
	router.Use(appMiddleware.ContextLogger(logger))
	router.Use(appMiddleware.RequestLogger(logger))
	router.Use(appMiddleware.CORS(cfg.AllowedOrigins))
	router.Use(middleware.Recoverer)

	// OpenAPI 規格端點 (供 Scalar UI 使用)
	router.Get("/openapi.json", func(writer http.ResponseWriter, request *http.Request) {
		swagger, err := api.GetSwagger()
		if err != nil {
			http.Error(writer, err.Error(), http.StatusInternalServerError)
			return
		}
		writer.Header().Set("Content-Type", "application/json")
		json.NewEncoder(writer).Encode(swagger)
	})

	// Scalar API Reference UI
	router.Get("/docs", func(writer http.ResponseWriter, request *http.Request) {
		writer.Header().Set("Content-Type", "text/html; charset=utf-8")
		writer.Write([]byte(`<!doctype html>
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

	// 初始化並掛載 API Handler (包含統一的 JWT 中間件)
	apiHandler := api.HandlerWithOptions(srv, api.ChiServerOptions{
		BaseURL: "/api/v1",
		Middlewares: []api.MiddlewareFunc{
			appMiddleware.JWTAuth(tokenManager),
		},
	})
	router.Mount("/", apiHandler)

	slog.Info("SummitMate API 已啟動", "addr", cfg.Addr(), "env", cfg.Env)
	slog.Info("API 文件", "url", "http://localhost"+cfg.Addr()+"/docs")
	if err := http.ListenAndServe(cfg.Addr(), router); err != nil {
		slog.Error("伺服器啟動失敗", "error", err)
		os.Exit(1)
	}
}
