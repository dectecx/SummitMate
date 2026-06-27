package email

import (
	"context"
	"fmt"
	"log/slog"
	"time"
)

// EmailService provides high-level methods for sending common emails.
// Use NewEmailService for synchronous-only usage and
// NewEmailServiceWithPool when background delivery is required.
type EmailService struct {
	mailer  Mailer
	tmplMgr TemplateManager
	pool    *WorkerPool
	logger  *slog.Logger
}

// NewEmailService creates a new EmailService without background delivery.
func NewEmailService(mailer Mailer, tmplMgr TemplateManager) *EmailService {
	return &EmailService{mailer: mailer, tmplMgr: tmplMgr}
}

// NewEmailServiceWithPool creates an EmailService backed by a bounded worker
// pool for non-blocking background delivery.  Call Shutdown before process exit.
func NewEmailServiceWithPool(mailer Mailer, tmplMgr TemplateManager, pool *WorkerPool, logger *slog.Logger) *EmailService {
	return &EmailService{mailer: mailer, tmplMgr: tmplMgr, pool: pool, logger: logger}
}

// SubmitAsync enqueues fn for background delivery via the worker pool.
// Returns false when the pool is nil or its queue is full; the caller should
// log a warning in that case.
func (s *EmailService) SubmitAsync(timeout time.Duration, fn func(ctx context.Context) error) bool {
	if s.pool == nil {
		return false
	}
	return s.pool.Submit(timeout, fn)
}

// Shutdown drains the internal worker pool.  Safe to call when pool is nil.
func (s *EmailService) Shutdown() {
	if s.pool != nil {
		s.pool.Shutdown()
	}
}

// SendVerificationCode sends a verification code email.
func (s *EmailService) SendVerificationCode(ctx context.Context, to string, code string, expireMinutes int) error {
	data := map[string]any{
		"Code":          code,
		"ExpireMinutes": expireMinutes,
	}
	body, err := s.tmplMgr.Render("verification_code.html", data)
	if err != nil {
		return fmt.Errorf("render template: %w", err)
	}

	return s.mailer.Send(ctx, []string{to}, "Your SummitMate Verification Code", body, true)
}

// SendRegistrationSuccess sends a registration success email.
func (s *EmailService) SendRegistrationSuccess(ctx context.Context, to string, username string, loginURL string) error {
	data := map[string]any{
		"Username": username,
		"LoginURL": loginURL,
	}
	body, err := s.tmplMgr.Render("registration_success.html", data)
	if err != nil {
		return fmt.Errorf("render template: %w", err)
	}

	return s.mailer.Send(ctx, []string{to}, "Welcome to SummitMate!", body, true)
}

// SendPasswordReset sends a password reset email.
func (s *EmailService) SendPasswordReset(ctx context.Context, to string, resetURL string, expireHours int) error {
	data := map[string]any{
		"ResetURL":    resetURL,
		"ExpireHours": expireHours,
	}
	body, err := s.tmplMgr.Render("password_reset.html", data)
	if err != nil {
		return fmt.Errorf("render template: %w", err)
	}

	return s.mailer.Send(ctx, []string{to}, "Reset Your SummitMate Password", body, true)
}

// SendSystemNotification sends a general system notification email.
func (s *EmailService) SendSystemNotification(ctx context.Context, to string, username string, title string, message string, actionText string, actionURL string) error {
	data := map[string]any{
		"Username":   username,
		"Title":      title,
		"Message":    message,
		"ActionText": actionText,
		"ActionURL":  actionURL,
	}
	body, err := s.tmplMgr.Render("system_notification.html", data)
	if err != nil {
		return fmt.Errorf("render template: %w", err)
	}

	return s.mailer.Send(ctx, []string{to}, title, body, true)
}
