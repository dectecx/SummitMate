package flag

import (
	"context"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"

	"summitmate/internal/middleware"
)

type fakeAdminChecker struct{ admins map[string]bool }

func (f fakeAdminChecker) IsAdmin(_ context.Context, userID string) (bool, error) {
	return f.admins[userID], nil
}

type recordingFlagService struct {
	FlagService
	set map[string]bool
}

func (r *recordingFlagService) SetFlag(_ context.Context, key string, value bool, _ string) error {
	r.set[key] = value
	return nil
}

func updateFlagRequest(userID, body string) *http.Request {
	req := httptest.NewRequest(http.MethodPost, "/system/flags", strings.NewReader(body))
	if userID != "" {
		req = req.WithContext(context.WithValue(req.Context(), middleware.UserIDKey, userID))
	}
	return req
}

func TestFlagHandler_UpdateFlag_Authorization(t *testing.T) {
	admins := fakeAdminChecker{admins: map[string]bool{"admin-1": true}}

	tests := []struct {
		name         string
		userID       string
		body         string
		allowDanger  bool
		wantStatus   int
		wantFlagSet  bool
		wantFlagName string
	}{
		{"Given no authenticated user, When updating a flag, Then it is rejected as unauthorized", "", `{"key":"enable_email_sending","value":false}`, true, http.StatusUnauthorized, false, ""},
		{"Given a regular user, When updating a flag, Then it is forbidden", "user-1", `{"key":"skip_verification_code","value":true}`, true, http.StatusForbidden, false, ""},
		{"Given an admin, When updating a normal flag, Then it succeeds", "admin-1", `{"key":"enable_email_sending","value":false}`, false, http.StatusNoContent, true, "enable_email_sending"},
		{"Given an admin in production, When enabling skip_verification_code, Then it is forbidden", "admin-1", `{"key":"skip_verification_code","value":true}`, false, http.StatusForbidden, false, ""},
		{"Given an admin in production, When disabling skip_verification_code, Then it succeeds", "admin-1", `{"key":"skip_verification_code","value":false}`, false, http.StatusNoContent, true, "skip_verification_code"},
		{"Given an admin outside production, When enabling skip_verification_code, Then it succeeds", "admin-1", `{"key":"skip_verification_code","value":true}`, true, http.StatusNoContent, true, "skip_verification_code"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			svc := &recordingFlagService{set: map[string]bool{}}
			handler := NewFlagHandler(svc, admins, tt.allowDanger)
			rec := httptest.NewRecorder()

			handler.UpdateFlag(rec, updateFlagRequest(tt.userID, tt.body))

			assert.Equal(t, tt.wantStatus, rec.Code)
			if tt.wantFlagSet {
				assert.Contains(t, svc.set, tt.wantFlagName)
			} else {
				assert.Empty(t, svc.set, "the flag must not be written")
			}
		})
	}
}
