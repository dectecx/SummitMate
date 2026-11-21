package email

import (
	"bytes"
	"embed"
	"html/template"
)

//go:embed templates/*.html
var templatesFS embed.FS

// TemplateManager handles the rendering of email templates.
type TemplateManager interface {
	Render(name string, data any) (string, error)
}

type templateManager struct {
	templates *template.Template
}

// NewTemplateManager creates a new TemplateManager.
func NewTemplateManager() (TemplateManager, error) {
	tmpl, err := template.ParseFS(templatesFS, "templates/*.html")
	if err != nil {
		return nil, err
	}
	return &templateManager{templates: tmpl}, nil
}

// Render renders the specified template with the given data.
func (tm *templateManager) Render(name string, data any) (string, error) {
	var buf bytes.Buffer
	if err := tm.templates.ExecuteTemplate(&buf, name, data); err != nil {
		return "", err
	}
	return buf.String(), nil
}
