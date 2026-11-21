package explore

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"slices"
	"strings"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"summitmate/api"
)

func ptr[T any](v T) *T { return &v }

func validMountain(id string, elevation int) Mountain {
	return Mountain{
		ID: id, Name: "測試山", Elevation: elevation, Region: "測試區", Latitude: 23.5, Longitude: 121,
		Category: CategoryBaiyue, Summary: "測試用資料。", Sources: []string{"https://example.com/a"},
	}
}

func validDataset(ms ...Mountain) Dataset {
	return Dataset{Version: "test.1", UpdatedAt: time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC), Mountains: ms}
}

func TestEmbeddedDatasetIsValid(t *testing.T) {
	svc, err := NewDefaultService()
	require.NoError(t, err)
	d := svc.Dataset()
	assert.Len(t, d.Mountains, 100, "the 100 baiyue peaks")
	for _, m := range d.Mountains {
		assert.False(t, m.Verified, m.ID)
		assert.Equal(t, CategoryBaiyue, m.Category, m.ID)
	}
	assert.True(t, slices.IsSortedFunc(d.Mountains, func(a, b Mountain) int {
		if a.Elevation != b.Elevation {
			return b.Elevation - a.Elevation
		}
		return strings.Compare(a.ID, b.ID)
	}))
}

func TestValidate(t *testing.T) {
	require.NoError(t, validDataset(validMountain("a", 3000), validMountain("b-1", 2000)).Validate())

	bad := func(mut func(*Mountain)) error {
		m := validMountain("a", 3000)
		mut(&m)
		return validDataset(m).Validate()
	}
	cases := map[string]func(*Mountain){
		"uppercase id":    func(m *Mountain) { m.ID = "Yushan" },
		"non-ascii id":    func(m *Mountain) { m.ID = "玉山" },
		"trailing hyphen": func(m *Mountain) { m.ID = "a-" },
		"empty name":      func(m *Mountain) { m.Name = " " },
		"empty region":    func(m *Mountain) { m.Region = "" },
		"low elevation":   func(m *Mountain) { m.Elevation = 99 },
		"high elevation":  func(m *Mountain) { m.Elevation = 4001 },
		"lat too low":     func(m *Mountain) { m.Latitude = 21 },
		"lat too high":    func(m *Mountain) { m.Latitude = 26 },
		"lng too low":     func(m *Mountain) { m.Longitude = 119 },
		"lng too high":    func(m *Mountain) { m.Longitude = 123 },
		"bad category":    func(m *Mountain) { m.Category = "hill" },
		"bad difficulty":  func(m *Mountain) { m.Difficulty = ptr("impossible") },
		"verified":        func(m *Mountain) { m.Verified = true },
		"no sources":      func(m *Mountain) { m.Sources = nil },
		"non-url source":  func(m *Mountain) { m.Sources = []string{"wikipedia"} },
		"non-http source": func(m *Mountain) { m.Sources = []string{"ftp://example.com/x"} },
		"source w/o host": func(m *Mountain) { m.Sources = []string{"https://"} },
		"empty summary":   func(m *Mountain) { m.Summary = "" },
	}
	for name, mut := range cases {
		assert.Error(t, bad(mut), name)
	}
	assert.NoError(t, bad(func(m *Mountain) { m.Difficulty = ptr("expert"); m.Category = CategoryOther }))

	assert.Error(t, validDataset(validMountain("a", 3000), validMountain("a", 2000)).Validate(), "duplicate id")
	assert.Error(t, validDataset().Validate(), "empty list")
	d := validDataset(validMountain("a", 3000))
	d.Version = ""
	assert.Error(t, d.Validate(), "empty version")
}

func TestParseRejectsUnknownFieldsAndBadJSON(t *testing.T) {
	_, err := Parse([]byte(`{"version":"1","updated_at":"2026-01-01T00:00:00Z","mountains":[],"extra":1}`))
	assert.Error(t, err)
	_, err = Parse([]byte(`{`))
	assert.Error(t, err)
}

func TestOrderingIsDeterministic(t *testing.T) {
	ms := []Mountain{validMountain("b", 3000), validMountain("a", 3000), validMountain("c", 3500), validMountain("d", 2000)}
	s1, err := NewService(validDataset(ms...))
	require.NoError(t, err)
	rev := slices.Clone(ms)
	slices.Reverse(rev)
	s2, err := NewService(validDataset(rev...))
	require.NoError(t, err)

	var ids []string
	for _, m := range s1.Dataset().Mountains {
		ids = append(ids, m.ID)
	}
	assert.Equal(t, []string{"c", "a", "b", "d"}, ids)
	assert.Equal(t, s1.Body(), s2.Body())
	assert.Equal(t, s1.ETag(), s2.ETag())
	assert.Equal(t, "b", ms[0].ID, "the caller's slice is not reordered")
}

func TestETagChangesWithContent(t *testing.T) {
	a, _ := NewService(validDataset(validMountain("a", 3000)))
	d := validDataset(validMountain("a", 3000))
	d.Version = "test.2"
	b, _ := NewService(d)
	assert.NotEqual(t, a.ETag(), b.ETag())
	assert.True(t, strings.HasPrefix(a.ETag(), `"`) && strings.HasSuffix(a.ETag(), `"`), "strong validator: quoted, no W/")
}

func newTestHandler(t *testing.T) (*Handler, *Service) {
	t.Helper()
	svc, err := NewDefaultService()
	require.NoError(t, err)
	return NewHandler(svc), svc
}

func get(h *Handler, ifNoneMatch *string) *httptest.ResponseRecorder {
	req := httptest.NewRequest(http.MethodGet, "/explore/mountains", nil)
	rec := httptest.NewRecorder()
	h.GetExploreMountains(rec, req, api.GetExploreMountainsParams{IfNoneMatch: ifNoneMatch})
	return rec
}

func TestHandlerReturnsJSONWithETag(t *testing.T) {
	h, svc := newTestHandler(t)
	rec := get(h, nil)
	require.Equal(t, http.StatusOK, rec.Code)
	assert.Equal(t, "application/json", rec.Header().Get("Content-Type"))
	assert.Equal(t, svc.ETag(), rec.Header().Get("ETag"))
	assert.Equal(t, "public, max-age=3600", rec.Header().Get("Cache-Control"))

	// The body must match the generated API contract exactly (no unknown fields).
	var out api.MountainDataset
	dec := json.NewDecoder(bytes.NewReader(rec.Body.Bytes()))
	dec.DisallowUnknownFields()
	require.NoError(t, dec.Decode(&out))
	assert.Equal(t, svc.Dataset().Version, out.Version)
	assert.Len(t, out.Mountains, 100)
	assert.Equal(t, "yushan-main", out.Mountains[0].Id)
	for _, m := range out.Mountains {
		assert.False(t, m.Verified)
	}
}

func TestHandlerConditionalRequests(t *testing.T) {
	h, svc := newTestHandler(t)
	etag := svc.ETag()

	for name, header := range map[string]string{
		"exact": etag, "weak form": "W/" + etag, "list": `"other", ` + etag, "star": "*",
	} {
		rec := get(h, &header)
		assert.Equal(t, http.StatusNotModified, rec.Code, name)
		assert.Empty(t, rec.Body.Bytes(), name)
		assert.Equal(t, etag, rec.Header().Get("ETag"), name)
		assert.Equal(t, "public, max-age=3600", rec.Header().Get("Cache-Control"), name)
	}

	other := `"not-the-etag"`
	rec := get(h, &other)
	assert.Equal(t, http.StatusOK, rec.Code)
	assert.NotEmpty(t, rec.Body.Bytes())
}
