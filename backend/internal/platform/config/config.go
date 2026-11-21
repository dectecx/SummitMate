// Package config loads runtime configuration from environment variables.
package config

import (
	"fmt"
	"net/url"
	"os"
	"strconv"
	"time"
)

const minJWTSecretLength = 32

type Config struct {
	Port            string
	Env             string // "development" | "production"
	DatabaseURL     string
	JWTSecret       string
	AccessTokenTTL  time.Duration
	RefreshTokenTTL time.Duration
	AuthCodeTTL     time.Duration
	BcryptCost      int
	MaxBodyBytes    int64
	RequestTimeout  time.Duration
	ShutdownTimeout time.Duration
}

func (c Config) IsProduction() bool { return c.Env == "production" }

// Load reads configuration from the environment and validates it.
func Load() (Config, error) {
	c := Config{
		Port:            get("PORT", "8080"),
		Env:             get("ENV", "development"),
		JWTSecret:       os.Getenv("JWT_SECRET"),
		AccessTokenTTL:  dur("ACCESS_TOKEN_TTL", 15*time.Minute),
		RefreshTokenTTL: dur("REFRESH_TOKEN_TTL", 14*24*time.Hour),
		AuthCodeTTL:     dur("AUTH_CODE_TTL", 30*time.Minute),
		BcryptCost:      intv("BCRYPT_COST", 12),
		MaxBodyBytes:    int64(intv("MAX_BODY_BYTES", 1<<20)),
		RequestTimeout:  dur("REQUEST_TIMEOUT", 30*time.Second),
		ShutdownTimeout: dur("SHUTDOWN_TIMEOUT", 15*time.Second),
	}
	c.DatabaseURL = os.Getenv("DATABASE_URL")
	if c.DatabaseURL == "" {
		c.DatabaseURL = buildDatabaseURL()
	}
	if len(c.JWTSecret) < minJWTSecretLength {
		return c, fmt.Errorf("JWT_SECRET must be at least %d characters", minJWTSecretLength)
	}
	if c.Env != "development" && c.Env != "production" {
		return c, fmt.Errorf("ENV must be development or production, got %q", c.Env)
	}
	return c, nil
}

func buildDatabaseURL() string {
	u := url.URL{
		Scheme: "postgres",
		User:   url.UserPassword(get("DB_USER", "dev"), os.Getenv("DB_PASS")),
		Host:   get("DB_HOST", "localhost") + ":" + get("DB_PORT", "5432"),
		Path:   get("DB_NAME", "summitmate"),
	}
	q := url.Values{}
	q.Set("sslmode", get("DB_SSLMODE", "disable"))
	u.RawQuery = q.Encode()
	return u.String()
}

func get(k, def string) string {
	if v := os.Getenv(k); v != "" {
		return v
	}
	return def
}

func intv(k string, def int) int {
	if v, err := strconv.Atoi(os.Getenv(k)); err == nil {
		return v
	}
	return def
}

func dur(k string, def time.Duration) time.Duration {
	if v, err := time.ParseDuration(os.Getenv(k)); err == nil {
		return v
	}
	return def
}
