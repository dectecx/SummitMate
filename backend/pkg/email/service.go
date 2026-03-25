package email

import (
	"fmt"
)

// EmailService provides high-level methods for sending common emails.
type EmailService struct {
	mailer  Mailer
	tmplMgr TemplateManager
}

// NewEmailService creates a new EmailService.
func NewEmailService(mailer Mailer, tmplMgr TemplateManager) *EmailService {
	return &EmailService{
		mailer:  mailer,
		tmplMgr: tmplMgr,
	}
}

// SendVerificationCode sends a verification code email.
func (s *EmailService) SendVerificationCode(to string, code string, expireMinutes int) error {
	data := map[string]any{
		"Code":          code,
		"ExpireMinutes": expireMinutes,
	}
	body, err := s.tmplMgr.Render("verification_code.html", data)
	if err != nil {
		return fmt.Errorf("render template: %w", err)
	}

	return s.mailer.Send([]string{to}, "Your SummitMate Verification Code", body, true)
}

// SendRegistrationSuccess sends a registration success email.
func (s *EmailService) SendRegistrationSuccess(to string, username string, loginURL string) error {
	data := map[string]any{
		"Username": username,
		"LoginURL": loginURL,
	}
	body, err := s.tmplMgr.Render("registration_success.html", data)
	if err != nil {
		return fmt.Errorf("render template: %w", err)
	}

	return s.mailer.Send([]string{to}, "Welcome to SummitMate!", body, true)
}

// SendPasswordReset sends a password reset email.
func (s *EmailService) SendPasswordReset(to string, resetURL string, expireHours int) error {
	data := map[string]any{
		"ResetURL":    resetURL,
		"ExpireHours": expireHours,
	}
	body, err := s.tmplMgr.Render("password_reset.html", data)
	if err != nil {
		return fmt.Errorf("render template: %w", err)
	}

	return s.mailer.Send([]string{to}, "Reset Your SummitMate Password", body, true)
}

// SendSystemNotification sends a general system notification email.
func (s *EmailService) SendSystemNotification(to string, username string, title string, message string, actionText string, actionURL string) error {
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

	return s.mailer.Send([]string{to}, title, body, true)
}
