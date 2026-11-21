package middleware

import (
	"net/http"

	"github.com/getkin/kin-openapi/openapi3"
	"github.com/go-chi/chi/v5"
)

// AuthPolicy 判斷目前請求所對應的 operation 是否必須通過認證。
type AuthPolicy func(r *http.Request) bool

// NewSpecAuthPolicy 直接依 OpenAPI spec 的 security 設定建立 AuthPolicy。
//
// 規則：
//   - operation 自身的 security 會覆寫 spec 全域 security。
//   - 沒有任何 security requirement，或其中包含匿名替代方案 ({})，視為公開端點。
//   - 找不到對應的 operation 時一律視為「需要認證」(fail-closed)。
//
// baseURL 為 API 掛載的前綴 (例如 "/api/v1")，需與 api.ChiServerOptions.BaseURL 一致。
func NewSpecAuthPolicy(spec *openapi3.T, baseURL string) AuthPolicy {
	required := make(map[string]bool)
	if spec.Paths != nil {
		for path, item := range spec.Paths.Map() {
			for method, op := range item.Operations() {
				required[routeKey(method, baseURL+path)] = operationRequiresAuth(spec, op)
			}
		}
	}

	return func(r *http.Request) bool {
		routeContext := chi.RouteContext(r.Context())
		if routeContext == nil {
			return true
		}
		isRequired, found := required[routeKey(r.Method, routeContext.RoutePattern())]
		if !found {
			return true
		}
		return isRequired
	}
}

func routeKey(method, pattern string) string {
	return method + " " + pattern
}

// operationRequiresAuth 套用「operation 覆寫全域 security」的規則。
func operationRequiresAuth(spec *openapi3.T, op *openapi3.Operation) bool {
	security := spec.Security
	if op.Security != nil {
		security = *op.Security
	}
	return securityRequired(security)
}

func securityRequired(security openapi3.SecurityRequirements) bool {
	if len(security) == 0 {
		return false
	}
	for _, requirement := range security {
		if len(requirement) == 0 {
			return false
		}
	}
	return true
}
