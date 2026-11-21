package weather

import (
	"context"
	"net/http"
	"time"

	openapi_types "github.com/oapi-codegen/runtime/types"

	"summitmate/api"
	"summitmate/internal/platform/httpx"
)

// Forecaster is what the handler needs from the Service (lets tests use a fake).
type Forecaster interface {
	Forecast(ctx context.Context, q Query) (Forecast, error)
}

// Handler adapts the weather Service to the generated API. Embed it in the server type.
type Handler struct{ svc Forecaster }

func NewHandler(svc Forecaster) *Handler { return &Handler{svc: svc} }

func (h *Handler) GetWeatherForecast(w http.ResponseWriter, r *http.Request, p api.GetWeatherForecastParams) {
	q, err := NewQuery(p.Lat, p.Lng, p.Elevation, p.Days)
	if err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	f, err := h.svc.Forecast(r.Context(), q)
	if err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, toAPI(f))
}

func toAPI(f Forecast) api.WeatherForecast {
	out := api.WeatherForecast{
		Latitude: f.Latitude, Longitude: f.Longitude, Elevation: f.Elevation,
		Timezone: f.Timezone, FetchedAt: f.FetchedAt.UTC(), Daily: make([]api.WeatherDay, len(f.Daily)),
	}
	for i, d := range f.Daily {
		date, _ := time.Parse(time.DateOnly, d.Date) // validated by the upstream client
		out.Daily[i] = api.WeatherDay{
			Date: openapi_types.Date{Time: date}, WeatherCode: d.WeatherCode, TempMax: d.TempMax, TempMin: d.TempMin,
			PrecipitationProbabilityMax: d.PrecipitationProbabilityMax, PrecipitationSum: d.PrecipitationSum,
			WindSpeedMax: d.WindSpeedMax, WindGustsMax: d.WindGustsMax,
		}
	}
	return out
}
