package middleware

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/getkin/kin-openapi/openapi3"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"summitmate/api"
)

const testAPIBaseURL = "/api/v1"

// routeAuthRequirements 以真實的 spec 與 chi 路由掛載方式，記錄每個請求對應的 AuthPolicy 判定結果。
func routeAuthRequirements(t *testing.T, spec *openapi3.T, requests []*http.Request) map[string]bool {
	t.Helper()

	policy := NewSpecAuthPolicy(spec, testAPIBaseURL)
	results := make(map[string]bool)
	var current string

	recorder := func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			results[current] = policy(r)
			w.WriteHeader(http.StatusNoContent)
		})
	}

	handler := api.HandlerWithOptions(api.Unimplemented{}, api.ChiServerOptions{
		BaseURL:     testAPIBaseURL,
		Middlewares: []api.MiddlewareFunc{recorder},
	})

	for _, req := range requests {
		current = req.Method + " " + req.URL.Path
		handler.ServeHTTP(httptest.NewRecorder(), req)
	}
	return results
}

func TestNewSpecAuthPolicy_RealSpec(t *testing.T) {
	spec, err := api.GetSwagger()
	require.NoError(t, err)

	requests := []*http.Request{
		httptest.NewRequest(http.MethodPost, "/api/v1/auth/login", nil),
		httptest.NewRequest(http.MethodGet, "/api/v1/trips", nil),
		httptest.NewRequest(http.MethodGet, "/api/v1/system/flags", nil),
	}
	results := routeAuthRequirements(t, spec, requests)

	assert.False(t, results["POST /api/v1/auth/login"], "login is a public endpoint")
	assert.True(t, results["GET /api/v1/trips"], "listing trips requires bearer auth")
	assert.Contains(t, results, "GET /api/v1/system/flags", "route must reach the middleware")
}

func TestNewSpecAuthPolicy_Rules(t *testing.T) {
	bearer := openapi3.SecurityRequirement{"bearerAuth": []string{}}
	anonymous := openapi3.SecurityRequirement{}

	tests := []struct {
		name     string
		global   openapi3.SecurityRequirements
		op       *openapi3.SecurityRequirements
		expected bool
	}{
		{"no security anywhere is public", nil, nil, false},
		{"global security applies when operation has none", openapi3.SecurityRequirements{bearer}, nil, true},
		{"operation security overrides global", openapi3.SecurityRequirements{bearer}, &openapi3.SecurityRequirements{}, false},
		{"anonymous alternative makes it optional", nil, &openapi3.SecurityRequirements{bearer, anonymous}, false},
		{"operation level bearer is required", nil, &openapi3.SecurityRequirements{bearer}, true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			op := openapi3.NewOperation()
			op.Security = tt.op
			spec := &openapi3.T{
				Security: tt.global,
				Paths:    openapi3.NewPaths(),
			}
			spec.Paths.Set("/things", &openapi3.PathItem{Get: op})

			assert.Equal(t, tt.expected, operationRequiresAuth(spec, op))
		})
	}
}

func TestNewSpecAuthPolicy_FailClosed(t *testing.T) {
	policy := NewSpecAuthPolicy(&openapi3.T{Paths: openapi3.NewPaths()}, testAPIBaseURL)

	// 沒有 chi route context
	assert.True(t, policy(httptest.NewRequest(http.MethodGet, "/anything", nil)))
}
