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
	"summitmate/internal/app"
	"summitmate/internal/config"
	"summitmate/internal/database"

	openapi_types "github.com/oapi-codegen/runtime/types"
)

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

	cfg.DatabaseURL = connStr

	// 初始化 Domain 邏輯透過 app.App
	appInstance, err := app.NewApp(cfg, slog.Default())
	s.Require().NoError(err, "無法初始化 App")
	appInstance.Pool = pool // reuse the test container pool

	router := appInstance.InitRouter()

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
