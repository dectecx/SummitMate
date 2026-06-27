package email

import (
	"context"
	"crypto/tls"
	"fmt"
	"net"
	"net/smtp"
	"strings"
)

// Mailer defines the interface for sending emails.
type Mailer interface {
	Send(ctx context.Context, to []string, subject, body string, isHTML bool) error
}

type smtpMailer struct {
	config SMTPConfig
	auth   smtp.Auth
}

type logMailer struct {
	config SMTPConfig
}

// NewMailer creates a new SMTP mailer.
// If username or host is empty, it returns a logMailer that prints to console.
func NewMailer(config SMTPConfig) Mailer {
	if config.Host == "" || config.Username == "" {
		return &logMailer{config: config}
	}
	auth := smtp.PlainAuth("", config.Username, config.Password, config.Host)
	return &smtpMailer{
		config: config,
		auth:   auth,
	}
}

// Send sends an email to the specified recipients.
func (m *smtpMailer) Send(ctx context.Context, to []string, subject, body string, isHTML bool) error {
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

	if m.config.UseSSL {
		// Port 465: TLS connection first
		tlsconfig := &tls.Config{
			InsecureSkipVerify: false,
			ServerName:         m.config.Host,
		}

		dialer := &tls.Dialer{
			NetDialer: &net.Dialer{},
			Config:    tlsconfig,
		}

		conn, err := dialer.DialContext(ctx, "tcp", addr)
		if err != nil {
			return fmt.Errorf("tls dial context: %w", err)
		}
		defer conn.Close()

		if deadline, ok := ctx.Deadline(); ok {
			if err := conn.SetDeadline(deadline); err != nil {
				return fmt.Errorf("set deadline: %w", err)
			}
		}

		c, err := smtp.NewClient(conn, m.config.Host)
		if err != nil {
			return fmt.Errorf("smtp new client: %w", err)
		}
		defer c.Quit()

		if err = c.Auth(m.auth); err != nil {
			return fmt.Errorf("smtp auth: %w", err)
		}

		if err = c.Mail(m.config.Username); err != nil {
			return fmt.Errorf("smtp mail: %w", err)
		}

		for _, addr := range to {
			if err = c.Rcpt(addr); err != nil {
				return fmt.Errorf("smtp rcpt %s: %w", addr, err)
			}
		}

		w, err := c.Data()
		if err != nil {
			return fmt.Errorf("smtp data: %w", err)
		}

		_, err = w.Write([]byte(msg.String()))
		if err != nil {
			return fmt.Errorf("smtp write: %w", err)
		}

		err = w.Close()
		if err != nil {
			return fmt.Errorf("smtp close: %w", err)
		}

		return nil
	}

	// Port 587: standard STARTTLS (with DialContext for cancelable connection)
	dialer := &net.Dialer{}
	conn, err := dialer.DialContext(ctx, "tcp", addr)
	if err != nil {
		return fmt.Errorf("smtp dial: %w", err)
	}
	defer conn.Close()

	if deadline, ok := ctx.Deadline(); ok {
		if err := conn.SetDeadline(deadline); err != nil {
			return fmt.Errorf("set deadline: %w", err)
		}
	}

	c, err := smtp.NewClient(conn, m.config.Host)
	if err != nil {
		return fmt.Errorf("smtp new client: %w", err)
	}
	defer c.Quit()

	if err = c.Hello("localhost"); err != nil {
		return fmt.Errorf("smtp hello: %w", err)
	}

	if ok, _ := c.Extension("STARTTLS"); ok {
		tlsconfig := &tls.Config{
			ServerName: m.config.Host,
		}
		if err = c.StartTLS(tlsconfig); err != nil {
			return fmt.Errorf("smtp starttls: %w", err)
		}
	}

	if m.auth != nil {
		if err = c.Auth(m.auth); err != nil {
			return fmt.Errorf("smtp auth: %w", err)
		}
	}

	if err = c.Mail(m.config.Username); err != nil {
		return fmt.Errorf("smtp mail: %w", err)
	}

	for _, addr := range to {
		if err = c.Rcpt(addr); err != nil {
			return fmt.Errorf("smtp rcpt %s: %w", addr, err)
		}
	}

	w, err := c.Data()
	if err != nil {
		return fmt.Errorf("smtp data: %w", err)
	}

	_, err = w.Write([]byte(msg.String()))
	if err != nil {
		return fmt.Errorf("smtp write: %w", err)
	}

	err = w.Close()
	if err != nil {
		return fmt.Errorf("smtp close: %w", err)
	}

	return nil
}

// Send logs the email to console instead of sending it.
func (m *logMailer) Send(ctx context.Context, to []string, subject, body string, isHTML bool) error {
	fmt.Printf("\n--- [DEV EMAIL LOG] ---\n")
	fmt.Printf("From: %s\n", m.config.From)
	fmt.Printf("To: %s\n", strings.Join(to, ", "))
	fmt.Printf("Subject: %s\n", subject)
	fmt.Printf("IsHTML: %v\n", isHTML)
	fmt.Printf("Content:\n%s\n", body)
	fmt.Printf("--- [END EMAIL LOG] ---\n\n")
	return nil
}
