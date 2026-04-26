package config

import (
	"fmt"
	"os"
	"strings"
)

// Config holds all application configuration.
type Config struct {
	Port           string
	DBHost         string
	DBPort         string
	DBUser         string
	DBPass         string
	DBName         string
	DBSSLMode      string
	DatabaseURL    string
	JWTSecret      string
	CWAApiKey      string
	Env            string
	AllowedOrigins []string
	SMTPHost       string
	SMTPPort       string
	SMTPUser       string
	SMTPPass       string
	SMTPFrom       string
	SMTPUseSSL     bool
	CacheType      string
	RedisAddr      string
	RedisPassword  string
	RedisDB        string
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
		Port:           getEnv("PORT", "8080"),
		DBHost:         getEnv("DB_HOST", "localhost"),
		DBPort:         getEnv("DB_PORT", "5432"),
		DBUser:         getEnv("DB_USER", "dev"),
		DBPass:         getEnv("DB_PASS", "dev2026!"),
		DBName:         getEnv("DB_NAME", "summitmate"),
		DBSSLMode:      getEnv("DB_SSLMODE", "disable"),
		JWTSecret:      getEnv("JWT_SECRET", ""),
		CWAApiKey:      getEnv("CWA_API_KEY", ""),
		Env:            env,
		AllowedOrigins: getEnvAsSlice("ALLOWED_ORIGINS", defaultOrigins),
		SMTPHost:       getEnv("SMTP_HOST", "smtp.gmail.com"),
		SMTPPort:       getEnv("SMTP_PORT", "587"),
		SMTPUser:       getEnv("SMTP_USER", ""),
		SMTPPass:       getEnv("SMTP_PASS", ""),
		SMTPFrom:       getEnv("SMTP_FROM", "SummitMate <noreply@summitmate.com>"),
		SMTPUseSSL:     getEnv("SMTP_USE_SSL", "false") == "true",
		CacheType:      getEnv("CACHE_TYPE", "memory"),
		RedisAddr:      getEnv("REDIS_ADDR", "localhost:6379"),
		RedisPassword:  getEnv("REDIS_PASSWORD", ""),
		RedisDB:        getEnv("REDIS_DB", "0"),
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

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
