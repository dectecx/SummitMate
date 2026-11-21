// Package mail defines the outgoing email interface.
package mail

import (
	"context"
	"log/slog"
)

// Mailer sends transactional emails.
type Mailer interface {
	SendVerificationCode(ctx context.Context, to, code string) error
}

// LogMailer writes the code to the log. For local development only.
type LogMailer struct{}

func (LogMailer) SendVerificationCode(ctx context.Context, to, code string) error {
	slog.InfoContext(ctx, "verification code (dev mailer)", "to", to, "code", code)
	return nil
}
