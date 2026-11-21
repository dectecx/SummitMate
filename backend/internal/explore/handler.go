package explore

import (
	"net/http"
	"strings"

	"summitmate/api"
)

// CacheControl is sent with every response: the data changes only with a deploy.
const CacheControl = "public, max-age=3600"

// Handler adapts the explore Service to the generated API. Embed it in the server type.
type Handler struct{ svc *Service }

func NewHandler(svc *Service) *Handler { return &Handler{svc: svc} }

// GetExploreMountains is public (no token). Honours If-None-Match with 304 and no body.
func (h *Handler) GetExploreMountains(w http.ResponseWriter, _ *http.Request, p api.GetExploreMountainsParams) {
	hd := w.Header()
	hd.Set("ETag", h.svc.ETag())
	hd.Set("Cache-Control", CacheControl)
	if p.IfNoneMatch != nil && etagMatches(*p.IfNoneMatch, h.svc.ETag()) {
		w.WriteHeader(http.StatusNotModified)
		return
	}
	hd.Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	_, _ = w.Write(h.svc.Body())
}

// etagMatches implements If-None-Match weak comparison: "*", or any listed tag equal to etag ignoring a W/ prefix.
func etagMatches(header, etag string) bool {
	for _, tag := range strings.Split(header, ",") {
		tag = strings.TrimSpace(tag)
		if tag == "*" || strings.TrimPrefix(tag, "W/") == etag {
			return true
		}
	}
	return false
}
