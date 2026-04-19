package api

import (
	"net/http"
	"summitmate/api"
	openapi_types "github.com/oapi-codegen/runtime/types"
)

// Legacy domain adapters (to be migrated)

func (s *Server) ListTripGearItems(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	s.TripGearHandler.ListTripGear(w, r, tripId)
}

func (s *Server) AddTripGearItem(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	s.TripGearHandler.AddTripGear(w, r, tripId)
}

func (s *Server) UpdateTripGearItem(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, itemId openapi_types.UUID) {
	s.TripGearHandler.UpdateTripGear(w, r, tripId, itemId)
}

func (s *Server) DeleteTripGearItem(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, itemId openapi_types.UUID) {
	s.TripGearHandler.RemoveTripGear(w, r, tripId, itemId)
}

func (s *Server) ReplaceAllTripGear(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	s.TripGearHandler.ReplaceAllTripGear(w, r, tripId)
}

func (s *Server) ListTripMealItems(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	s.TripMealHandler.ListTripMeals(w, r, tripId)
}

func (s *Server) AddTripMealItem(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	s.TripMealHandler.AddTripMeal(w, r, tripId)
}

func (s *Server) UpdateTripMealItem(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, itemId openapi_types.UUID) {
	s.TripMealHandler.UpdateTripMeal(w, r, tripId, itemId)
}

func (s *Server) DeleteTripMealItem(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, itemId openapi_types.UUID) {
	s.TripMealHandler.RemoveTripMeal(w, r, tripId, itemId)
}

func (srv *Server) ReplaceAllTripMeals(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	srv.TripMealHandler.ReplaceAllTripMeals(w, r, tripId)
}

func (s *Server) ListFavorites(w http.ResponseWriter, r *http.Request) {
	s.FavoriteHandler.ListFavorites(w, r)
}

func (s *Server) AddFavorite(w http.ResponseWriter, r *http.Request) {
	s.FavoriteHandler.AddFavorite(w, r)
}

func (s *Server) RemoveFavorite(w http.ResponseWriter, r *http.Request, targetId openapi_types.UUID) {
	s.FavoriteHandler.RemoveFavorite(w, r, targetId)
}

func (s *Server) BatchUpdateFavorites(w http.ResponseWriter, r *http.Request) {
	s.FavoriteHandler.BatchUpdateFavorites(w, r)
}

func (s *Server) GetGroupEvents(w http.ResponseWriter, r *http.Request, params api.GetGroupEventsParams) {
	s.GroupHandler.GetGroupEvents(w, r, params)
}

func (s *Server) PostGroupEvents(w http.ResponseWriter, r *http.Request) {
	s.GroupHandler.PostGroupEvents(w, r)
}

func (s *Server) GetGroupEventsId(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	s.GroupHandler.GetGroupEventsId(w, r, id)
}

func (s *Server) PatchGroupEventsId(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	s.GroupHandler.PatchGroupEventsId(w, r, id)
}

func (s *Server) PostGroupEventsIdApply(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	s.GroupHandler.PostGroupEventsIdApply(w, r, id)
}

func (s *Server) GetGroupEventsIdApplications(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	s.GroupHandler.GetGroupEventsIdApplications(w, r, id)
}

func (s *Server) PatchGroupEventsApplicationsAppId(w http.ResponseWriter, r *http.Request, appId openapi_types.UUID) {
	s.GroupHandler.PatchGroupEventsApplicationsAppId(w, r, appId)
}

func (s *Server) GetGroupEventsIdComments(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	s.GroupHandler.GetGroupEventsIdComments(w, r, id)
}

func (s *Server) PostGroupEventsIdComments(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	s.GroupHandler.PostGroupEventsIdComments(w, r, id)
}

func (s *Server) DeleteGroupEventsId(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	s.GroupHandler.DeleteGroupEventsId(w, r, id)
}

func (s *Server) PostGroupEventsIdLike(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	s.GroupHandler.PostGroupEventsIdLike(w, r, id)
}

func (s *Server) DeleteGroupEventsCommentsCommentId(w http.ResponseWriter, r *http.Request, commentId openapi_types.UUID) {
	s.GroupHandler.DeleteGroupEventsCommentsCommentId(w, r, commentId)
}

func (s *Server) GetHikingWeather(w http.ResponseWriter, r *http.Request) {
	s.WeatherHandler.GetHikingWeather(w, r)
}

func (s *Server) GetHikingWeatherByLocation(w http.ResponseWriter, r *http.Request, location string) {
	s.WeatherHandler.GetHikingWeatherByLocation(w, r, location)
}

func (s *Server) UploadLogs(w http.ResponseWriter, r *http.Request) {
	s.LogHandler.UploadLogs(w, r)
}

func (s *Server) Heartbeat(w http.ResponseWriter, r *http.Request) {
	s.HeartbeatHandler.Heartbeat(w, r)
}

func (s *Server) GetHealth(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write([]byte(`{"status":"ok"}`))
}
