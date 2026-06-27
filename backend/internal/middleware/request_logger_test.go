package middleware

import (
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestSanitizeBody_RedactsSensitiveFields(t *testing.T) {
	body := []byte(`{"email":"a@b.com","password":"secret","token":"abc","refresh_token":"def","code":"123456","old_password":"x","new_password":"y"}`)

	out := sanitizeBody(body)

	assert.Contains(t, out, `"email":"a@b.com"`)
	assert.Contains(t, out, `"password":"[REDACTED]"`)
	assert.Contains(t, out, `"token":"[REDACTED]"`)
	assert.Contains(t, out, `"refresh_token":"[REDACTED]"`)
	assert.Contains(t, out, `"code":"[REDACTED]"`)
	assert.Contains(t, out, `"old_password":"[REDACTED]"`)
	assert.Contains(t, out, `"new_password":"[REDACTED]"`)

	assert.NotContains(t, out, "secret")
	assert.NotContains(t, out, "abc")
	assert.NotContains(t, out, "def")
	assert.NotContains(t, out, "123456")
}

func TestSanitizeBody_RedactsNestedAndArrayFields(t *testing.T) {
	body := []byte(`{"user":{"password":"secret"},"sessions":[{"refresh_token":"def"}]}`)

	out := sanitizeBody(body)

	assert.Contains(t, out, `"password":"[REDACTED]"`)
	assert.Contains(t, out, `"refresh_token":"[REDACTED]"`)
	assert.NotContains(t, out, "secret")
	assert.NotContains(t, out, "def")
}

func TestSanitizeBody_NonJSONIsTruncatedOnly(t *testing.T) {
	body := []byte("plain text not json")

	out := sanitizeBody(body)

	assert.Equal(t, "plain text not json", out)
}

func TestSanitizeBody_TruncatesOversizedBody(t *testing.T) {
	body := []byte(strings.Repeat("a", maxBodyLogBytes+100))

	out := sanitizeBody(body)

	assert.True(t, strings.HasSuffix(out, "...(truncated)"))
	assert.Equal(t, maxBodyLogBytes+len("...(truncated)"), len(out))
}
