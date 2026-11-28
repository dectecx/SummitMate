// Package devmaps serves a developer's local copy of the offline map files, so test devices on the local network
// download them from this machine instead of the map author's servers. Development only.
package devmaps

import (
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"
)

// Prefix is the path the files are served under, outside the API.
const Prefix = "/dev/maps/"

// The only files served: what the app downloads to install the Rudy Map.
var files = map[string]bool{"MOI_OSM_Taiwan_TOPO_Rudy.pmtiles": true, "noto-sans.zip": true}

// Wrap serves the map files in dir under Prefix and hands everything else to next. HEAD and range requests work,
// so an interrupted download can resume.
func Wrap(next http.Handler, dir string) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		name, ok := strings.CutPrefix(r.URL.Path, Prefix)
		if !ok {
			next.ServeHTTP(w, r)
			return
		}
		if !files[name] || (r.Method != http.MethodGet && r.Method != http.MethodHead) {
			http.NotFound(w, r)
			return
		}
		f, err := os.Open(filepath.Join(dir, name))
		if err != nil {
			http.NotFound(w, r)
			return
		}
		defer f.Close()
		info, err := f.Stat()
		if err != nil || info.IsDir() {
			http.NotFound(w, r)
			return
		}
		// Hundreds of megabytes: the server's write timeout for API calls must not cut it off.
		_ = http.NewResponseController(w).SetWriteDeadline(time.Time{})
		http.ServeContent(w, r, name, info.ModTime(), f)
	})
}
