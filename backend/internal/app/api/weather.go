package api

import (
	"net/http"
)

func (s *Server) GetHikingWeather(w http.ResponseWriter, r *http.Request) {
	s.WeatherHandler.GetHikingWeather(w, r)
}

func (s *Server) GetHikingWeatherByLocation(w http.ResponseWriter, r *http.Request, location string) {
	s.WeatherHandler.GetHikingWeatherByLocation(w, r, location)
}
