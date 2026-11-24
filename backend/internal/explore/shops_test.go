package explore

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"summitmate/api"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestEmbeddedShopsAreValid(t *testing.T) {
	svc, err := NewDefaultShopService()
	require.NoError(t, err)
	assert.GreaterOrEqual(t, len(svc.Dataset().Shops), 50)
	for _, s := range svc.Dataset().Shops {
		assert.GreaterOrEqual(t, s.Rating, 4.0, s.Name)
	}
}

func TestShopValidationRejectsBadData(t *testing.T) {
	good := `{"version":"v1","updated_at":"2026-11-25T00:00:00Z","shops":[{"id":"a-1","name":"山店","city":"臺北市","district":"","address":"中山北路1號","phone":"02 2345 6789","google_maps_url":"https://www.google.com/maps/search/?api=1&query=x","hours":null,"website":"https://shop.example/","shop_url":null,"categories":["登山裝備"],"rating":4.2,"rating_count":30,"checked_on":"2026-11-25"}]}`
	_, err := ParseShops([]byte(good))
	require.NoError(t, err)
	for name, bad := range map[string]string{
		"low rating":     strings.Replace(good, `"rating":4.2`, `"rating":3.9`, 1),
		"unknown field":  strings.Replace(good, `"hours":null`, `"hours":null,"x":1`, 1),
		"bad category":   strings.Replace(good, `登山裝備`, `玩具`, 1),
		"http url":       strings.Replace(good, `https://www.google`, `http://www.google`, 1),
		"http website":   strings.Replace(good, `https://shop.example/`, `http://shop.example/`, 1),
		"bad phone":      strings.Replace(good, `02 2345 6789`, `call me`, 1),
		"no shops":       `{"version":"v1","updated_at":"2026-11-25T00:00:00Z","shops":[]}`,
		"bad checked_on": strings.Replace(good, `2026-11-25"}]`, `yesterday"}]`, 1),
	} {
		_, err := ParseShops([]byte(bad))
		assert.Error(t, err, name)
	}
}

func TestShopsEndpointSupportsETag(t *testing.T) {
	svc, err := NewDefaultShopService()
	require.NoError(t, err)
	h := NewHandler(nil).WithShops(svc)

	rec := httptest.NewRecorder()
	h.GetExploreShops(rec, httptest.NewRequest(http.MethodGet, "/explore/shops", nil), api.GetExploreShopsParams{})
	assert.Equal(t, http.StatusOK, rec.Code)
	etag := rec.Header().Get("ETag")
	require.NotEmpty(t, etag)

	rec = httptest.NewRecorder()
	h.GetExploreShops(rec, httptest.NewRequest(http.MethodGet, "/explore/shops", nil), api.GetExploreShopsParams{IfNoneMatch: &etag})
	assert.Equal(t, http.StatusNotModified, rec.Code)
	assert.Empty(t, rec.Body.Bytes())
}
