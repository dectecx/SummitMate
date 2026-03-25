package config

import (
	"fmt"
	"os"
	"strings"
)

// Config holds all application configuration.
type Config struct {
	Port           string
	DatabaseURL    string
	JWTSecret      string
	CWAApiKey      string
	Env            string
	AllowedOrigins []string
}

// Load reads configuration from environment variables with defaults.
func Load() *Config {
	return &Config{
		Port:           getEnv("PORT", "8080"),
		DatabaseURL:    getEnv("DATABASE_URL", "postgres://dev:dev2026!@localhost:5432/summitmate?sslmode=disable"),
		JWTSecret:      getEnv("JWT_SECRET", "summitmate-dev-secret-change-in-production"),
		CWAApiKey:      getEnv("CWA_API_KEY", ""),
		Env:            getEnv("ENV", "development"),
		AllowedOrigins: getEnvAsSlice("ALLOWED_ORIGINS", []string{"http://localhost:8083"}),
	}
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
