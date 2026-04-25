package email

// SMTPConfig holds the configuration for the SMTP server.
type SMTPConfig struct {
	Host     string
	Port     string
	Username string
	Password string
	From     string
	UseSSL   bool
}
