package handler

import (
	"net/http"

	"summitmate/internal/service"
)

type WeatherHandler struct {
	service *service.WeatherService
}

func NewWeatherHandler(service *service.WeatherService) *WeatherHandler {
	return &WeatherHandler{service: service}
}

// GetHikingWeather 回傳所有登山天氣資料
func (h *WeatherHandler) GetHikingWeather(w http.ResponseWriter, r *http.Request) {
	records, err := h.service.ListAll(r.Context())
	if err != nil {
		sendError(w, err)
		return
	}
	sendJSON(w, http.StatusOK, records)
}

// GetHikingWeatherByLocation 回傳特定地點的登山天氣
func (h *WeatherHandler) GetHikingWeatherByLocation(w http.ResponseWriter, r *http.Request, location string) {
	records, err := h.service.ListByLocation(r.Context(), location)
	if err != nil {
		sendError(w, err)
		return
	}

	if len(records) == 0 {
		w.WriteHeader(http.StatusNotFound)
		return
	}

	sendJSON(w, http.StatusOK, records)
}
