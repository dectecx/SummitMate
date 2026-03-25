package email

import (
	"fmt"
	"net/smtp"
	"strings"
)

// Mailer defines the interface for sending emails.
type Mailer interface {
	Send(to []string, subject, body string, isHTML bool) error
}

type smtpMailer struct {
	config SMTPConfig
	auth   smtp.Auth
}

// NewMailer creates a new SMTP mailer.
func NewMailer(config SMTPConfig) Mailer {
	auth := smtp.PlainAuth("", config.Username, config.Password, config.Host)
	return &smtpMailer{
		config: config,
		auth:   auth,
	}
}

// Send sends an email to the specified recipients.
func (m *smtpMailer) Send(to []string, subject, body string, isHTML bool) error {
	contentType := "text/plain"
	if isHTML {
		contentType = "text/html"
	}

	header := make(map[string]string)
	header["From"] = m.config.From
	header["To"] = strings.Join(to, ",")
	header["Subject"] = subject
	header["MIME-Version"] = "1.0"
	header["Content-Type"] = fmt.Sprintf("%s; charset=\"utf-8\"", contentType)

	var msg strings.Builder
	for k, v := range header {
		msg.WriteString(fmt.Sprintf("%s: %s\r\n", k, v))
	}
	msg.WriteString("\r\n")
	msg.WriteString(body)

	addr := fmt.Sprintf("%s:%s", m.config.Host, m.config.Port)
	return smtp.SendMail(addr, m.auth, m.config.Username, to, []byte(msg.String()))
}
