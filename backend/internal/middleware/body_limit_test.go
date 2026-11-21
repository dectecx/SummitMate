package middleware_test

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"

	"summitmate/internal/apperror"
	"summitmate/internal/common/apiutil"
	"summitmate/internal/middleware"
)

func TestMaxBodySize(t *testing.T) {
	handler := middleware.MaxBodySize(32)(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		var payload struct {
			Name string `json:"name"`
		}
		if err := apiutil.DecodeBody(r, &payload); err != nil {
			apiutil.SendError(w, r, err)
			return
		}
		w.WriteHeader(http.StatusNoContent)
	}))

	t.Run("Given a body within the limit, When decoding it, Then the request succeeds", func(t *testing.T) {
		rec := httptest.NewRecorder()
		handler.ServeHTTP(rec, httptest.NewRequest(http.MethodPost, "/", strings.NewReader(`{"name":"ok"}`)))

		assert.Equal(t, http.StatusNoContent, rec.Code)
	})

	t.Run("Given a body above the limit, When decoding it, Then it returns 413", func(t *testing.T) {
		rec := httptest.NewRecorder()
		big := `{"name":"` + strings.Repeat("a", 1024) + `"}`
		handler.ServeHTTP(rec, httptest.NewRequest(http.MethodPost, "/", strings.NewReader(big)))

		assert.Equal(t, apperror.ErrPayloadTooLarge.HTTPStatus, rec.Code)
	})
}
