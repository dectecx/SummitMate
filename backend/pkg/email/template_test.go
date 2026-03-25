package email

import (
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestTemplateManager_Render(t *testing.T) {
	tm, err := NewTemplateManager()
	assert.NoError(t, err)

	t.Run("Verification Code", func(t *testing.T) {
		data := map[string]any{
			"Code":          "123456",
			"ExpireMinutes": 10,
		}
		html, err := tm.Render("verification_code.html", data)
		assert.NoError(t, err)
		assert.True(t, strings.Contains(html, "123456"))
		assert.True(t, strings.Contains(html, "10 minutes"))
	})

	t.Run("Registration Success", func(t *testing.T) {
		data := map[string]any{
			"Username": "johndoe",
			"LoginURL": "https://summitmate.com/login",
		}
		html, err := tm.Render("registration_success.html", data)
		assert.NoError(t, err)
		assert.True(t, strings.Contains(html, "johndoe"))
		assert.True(t, strings.Contains(html, "https://summitmate.com/login"))
	})

	t.Run("Password Reset", func(t *testing.T) {
		data := map[string]any{
			"ResetURL":    "https://summitmate.com/reset?token=abc",
			"ExpireHours": 2,
		}
		html, err := tm.Render("password_reset.html", data)
		assert.NoError(t, err)
		assert.True(t, strings.Contains(html, "https://summitmate.com/reset?token=abc"))
		assert.True(t, strings.Contains(html, "2 hours"))
	})

	t.Run("System Notification", func(t *testing.T) {
		data := map[string]any{
			"Username":   "user123",
			"Title":      "Update Available",
			"Message":    "There's a new update for the app.",
			"ActionText": "Check it out",
			"ActionURL":  "https://summitmate.com/updates",
		}
		html, err := tm.Render("system_notification.html", data)
		assert.NoError(t, err)
		assert.True(t, strings.Contains(html, "user123"))
		assert.True(t, strings.Contains(html, "Update Available"))
		assert.True(t, strings.Contains(html, "Check it out"))
	})
}
