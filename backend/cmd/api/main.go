package main

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"summitmate/internal/auth"
	"summitmate/internal/platform/config"
	"summitmate/internal/platform/database"
	"summitmate/internal/platform/mail"
	"summitmate/internal/platform/ratelimit"
	"summitmate/internal/server"
	"summitmate/internal/sync"
)

func main() {
	if err := run(); err != nil {
		slog.Error("fatal", "error", err)
		os.Exit(1)
	}
}

func run() error {
	cfg, err := config.Load()
	if err != nil {
		return err
	}
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	pool, err := database.Open(ctx, cfg.DatabaseURL)
	if err != nil {
		return err
	}
	defer pool.Close()

	if cfg.IsProduction() {
		// A real mail provider is not chosen yet; refuse to run without one.
		return errors.New("production mailer is not configured")
	}
	tokens := auth.NewTokenManager(cfg.JWTSecret, cfg.AccessTokenTTL)
	authSvc, err := auth.NewService(auth.NewPgRepository(pool), tokens, mail.LogMailer{}, auth.Options{
		RefreshTTL:    cfg.RefreshTokenTTL,
		CodeTTL:       cfg.AuthCodeTTL,
		BcryptCost:    cfg.BcryptCost,
		LoginFailures: ratelimit.NewMemory(5, 15*time.Minute),
		Resend:        ratelimit.NewMemory(1, time.Minute),
	})
	if err != nil {
		return err
	}

	srv := &http.Server{
		Addr: ":" + cfg.Port,
		Handler: server.NewRouter(server.Options{
			Auth:           auth.NewHandler(authSvc),
			Sync:           sync.NewHandler(sync.NewService(pool)),
			Tokens:         tokens,
			MaxBodyBytes:   cfg.MaxBodyBytes,
			RequestTimeout: cfg.RequestTimeout,
		}),
		ReadHeaderTimeout: 10 * time.Second,
		ReadTimeout:       30 * time.Second,
		WriteTimeout:      60 * time.Second,
		IdleTimeout:       120 * time.Second,
	}
	errc := make(chan error, 1)
	go func() {
		slog.Info("listening", "addr", srv.Addr, "env", cfg.Env)
		errc <- srv.ListenAndServe()
	}()
	select {
	case err := <-errc:
		return err
	case <-ctx.Done():
	}
	shutdownCtx, cancel := context.WithTimeout(context.Background(), cfg.ShutdownTimeout)
	defer cancel()
	return srv.Shutdown(shutdownCtx)
}
