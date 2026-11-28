package devmaps

import (
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestWrap(t *testing.T) {
	dir := t.TempDir()
	require.NoError(t, os.WriteFile(filepath.Join(dir, "noto-sans.zip"), []byte("0123456789"), 0o644))
	require.NoError(t, os.WriteFile(filepath.Join(dir, "secret.txt"), []byte("no"), 0o644))
	h := Wrap(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) { w.WriteHeader(http.StatusTeapot) }), dir)
	do := func(method, path, rng string) *httptest.ResponseRecorder {
		req := httptest.NewRequest(method, path, nil)
		if rng != "" {
			req.Header.Set("Range", rng)
		}
		rec := httptest.NewRecorder()
		h.ServeHTTP(rec, req)
		return rec
	}

	head := do(http.MethodHead, "/dev/maps/noto-sans.zip", "")
	assert.Equal(t, http.StatusOK, head.Code)
	assert.Equal(t, "10", head.Header().Get("Content-Length"))

	part := do(http.MethodGet, "/dev/maps/noto-sans.zip", "bytes=4-")
	assert.Equal(t, http.StatusPartialContent, part.Code)
	assert.Equal(t, "456789", part.Body.String())

	// only the listed files, only for reading
	assert.Equal(t, http.StatusNotFound, do(http.MethodGet, "/dev/maps/secret.txt", "").Code)
	assert.Equal(t, http.StatusNotFound, do(http.MethodGet, "/dev/maps/../devmaps.go", "").Code)
	assert.Equal(t, http.StatusNotFound, do(http.MethodDelete, "/dev/maps/noto-sans.zip", "").Code)
	assert.Equal(t, http.StatusNotFound, do(http.MethodGet, "/dev/maps/MOI_OSM_Taiwan_TOPO_Rudy.pmtiles", "").Code, "not cached")

	assert.Equal(t, http.StatusTeapot, do(http.MethodGet, "/api/v1/health", "").Code, "everything else is untouched")
}
