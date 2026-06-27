package config

import (
	"fmt"
	"os"
	"strconv"
	"strings"
	"testing"
	"time"
)

// minJWTSecretLength is the minimum acceptable length (in characters) for the
// JWT signing secret. A short or empty secret would let attackers brute-force
// or forge HS256 tokens.
const minJWTSecretLength = 16

// Config holds all application configuration.
type Config struct {
	Port string
	Env  string

	// HTTP server / lifecycle timeouts.
	HTTPRequestTimeout time.Duration
	ShutdownTimeout    time.Duration

	// Database connection.
	DBHost      string
	DBPort      string
	DBUser      string
	DBPass      string
	DBName      string
	DBSSLMode   string
	DatabaseURL string

	// Database connection pool tuning.
	DBMaxConns          int
	DBMinConns          int
	DBMaxConnLifetime   time.Duration
	DBMaxConnIdleTime   time.Duration
	DBHealthCheckPeriod time.Duration
	DBConnectTimeout    time.Duration

	// Auth / JWT.
	JWTSecret       string
	AccessTokenTTL  time.Duration
	RefreshTokenTTL time.Duration

	// Email verification.
	AuthCodeTTL         time.Duration
	AuthMailSendTimeout time.Duration

	// Rate limiting.
	LoginRateWindow  time.Duration
	ResendRateWindow time.Duration
	VerifyRateWindow time.Duration

	// External services.
	CWAApiKey      string
	CWAHTTPTimeout time.Duration

	AllowedOrigins []string

	SMTPHost          string
	SMTPPort          string
	SMTPUser          string
	SMTPPass          string
	SMTPFrom          string
	SMTPUseSSL        bool
	SMTPWorkerCount   int
	SMTPQueueCapacity int

	CacheType     string
	RedisAddr     string
	RedisPassword string
	RedisDB       string
}

// Load reads configuration from environment variables with defaults.
func Load() *Config {
	env := getEnv("ENV", "development")
	defaultOrigins := []string{"https://summitmate-tw.netlify.app"}
	if env == "development" {
		// 開發模式允許所有 localhost 變體與模擬器 (由中間件進行 Prefix 匹配)
		defaultOrigins = append(defaultOrigins, "http://localhost", "http://127.0.0.1", "http://10.0.2.2")
	}

	cfg := &Config{
		Port: getEnv("PORT", "8080"),
		Env:  env,

		HTTPRequestTimeout: getEnvAsDuration("HTTP_REQUEST_TIMEOUT", 30*time.Second),
		ShutdownTimeout:    getEnvAsDuration("SHUTDOWN_TIMEOUT", 10*time.Second),

		DBHost:    getEnv("DB_HOST", "localhost"),
		DBPort:    getEnv("DB_PORT", "5432"),
		DBUser:    getEnv("DB_USER", "dev"),
		DBPass:    getEnv("DB_PASS", "dev2026!"),
		DBName:    getEnv("DB_NAME", "summitmate"),
		DBSSLMode: getEnv("DB_SSLMODE", "disable"),

		DBMaxConns:          getEnvAsInt("DB_MAX_CONNS", 10),
		DBMinConns:          getEnvAsInt("DB_MIN_CONNS", 2),
		DBMaxConnLifetime:   getEnvAsDuration("DB_MAX_CONN_LIFETIME", 30*time.Minute),
		DBMaxConnIdleTime:   getEnvAsDuration("DB_MAX_CONN_IDLE_TIME", 5*time.Minute),
		DBHealthCheckPeriod: getEnvAsDuration("DB_HEALTH_CHECK_PERIOD", 1*time.Minute),
		DBConnectTimeout:    getEnvAsDuration("DB_CONNECT_TIMEOUT", 10*time.Second),

		JWTSecret:       getEnv("JWT_SECRET", ""),
		AccessTokenTTL:  getEnvAsDuration("ACCESS_TOKEN_TTL", 1*time.Hour),
		RefreshTokenTTL: getEnvAsDuration("REFRESH_TOKEN_TTL", 14*24*time.Hour),

		AuthCodeTTL:         getEnvAsDuration("AUTH_CODE_TTL", 10*time.Minute),
		AuthMailSendTimeout: getEnvAsDuration("AUTH_MAIL_SEND_TIMEOUT", 15*time.Second),

		LoginRateWindow:  getEnvAsDuration("LOGIN_RATE_WINDOW", 15*time.Minute),
		ResendRateWindow: getEnvAsDuration("RESEND_RATE_WINDOW", 30*time.Minute),
		VerifyRateWindow: getEnvAsDuration("VERIFY_RATE_WINDOW", 10*time.Minute),

		CWAApiKey:      getEnv("CWA_API_KEY", ""),
		CWAHTTPTimeout: getEnvAsDuration("CWA_HTTP_TIMEOUT", 30*time.Second),

		AllowedOrigins: getEnvAsSlice("ALLOWED_ORIGINS", defaultOrigins),

		SMTPHost:          getEnv("SMTP_HOST", "smtp.gmail.com"),
		SMTPPort:          getEnv("SMTP_PORT", "587"),
		SMTPUser:          getEnv("SMTP_USER", ""),
		SMTPPass:          getEnv("SMTP_PASS", ""),
		SMTPFrom:          getEnv("SMTP_FROM", "SummitMate <noreply@summitmate.com>"),
		SMTPUseSSL:        getEnv("SMTP_USE_SSL", "false") == "true",
		SMTPWorkerCount:   getEnvAsInt("SMTP_WORKER_COUNT", 3),
		SMTPQueueCapacity: getEnvAsInt("SMTP_QUEUE_CAPACITY", 50),

		CacheType:     getEnv("CACHE_TYPE", "memory"),
		RedisAddr:     getEnv("REDIS_ADDR", "localhost:6379"),
		RedisPassword: getEnv("REDIS_PASSWORD", ""),
		RedisDB:       getEnv("REDIS_DB", "0"),
	}

	cfg.DatabaseURL = fmt.Sprintf("postgres://%s:%s@%s:%s/%s?sslmode=%s",
		cfg.DBUser, cfg.DBPass, cfg.DBHost, cfg.DBPort, cfg.DBName, cfg.DBSSLMode)

	return cfg
}

func getEnvAsSlice(key string, fallback []string) []string {
	val := os.Getenv(key)
	if val == "" {
		return fallback
	}
	return strings.Split(val, ",")
}

// Addr returns the listen address (e.g. ":8080").
func (c *Config) Addr() string {
	return fmt.Sprintf(":%s", c.Port)
}

// Validate checks that security-critical configuration is present and safe
// before the API server starts. It is intended to be called by the API server
// entrypoint so that misconfiguration fails fast instead of silently signing
// tokens with an empty/weak key. Validation is skipped under `go test`.
func (c *Config) Validate() error {
	if testing.Testing() {
		return nil
	}

	if len(c.JWTSecret) < minJWTSecretLength {
		return fmt.Errorf("JWT_SECRET is required and must be at least %d characters long", minJWTSecretLength)
	}

	return nil
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

// getEnvAsInt reads an integer env var, falling back to the default when the
// variable is unset or cannot be parsed.
func getEnvAsInt(key string, fallback int) int {
	if v := os.Getenv(key); v != "" {
		if n, err := strconv.Atoi(v); err == nil {
			return n
		}
	}
	return fallback
}

// getEnvAsDuration reads a Go duration string (e.g. "30s", "10m", "336h"),
// falling back to the default when the variable is unset or cannot be parsed.
func getEnvAsDuration(key string, fallback time.Duration) time.Duration {
	if v := os.Getenv(key); v != "" {
		if d, err := time.ParseDuration(v); err == nil {
			return d
		}
	}
	return fallback
}
