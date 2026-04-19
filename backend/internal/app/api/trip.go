package api

import (
	"net/http"
	openapi_types "github.com/oapi-codegen/runtime/types"
)

func (s *Server) ListTrips(w http.ResponseWriter, r *http.Request) {
	s.TripHandler.ListTrips(w, r)
}

func (s *Server) CreateTrip(w http.ResponseWriter, r *http.Request) {
	s.TripHandler.CreateTrip(w, r)
}

func (s *Server) GetTrip(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	s.TripHandler.GetTrip(w, r, tripId)
}

func (s *Server) UpdateTrip(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	s.TripHandler.UpdateTrip(w, r, tripId)
}

func (s *Server) DeleteTrip(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	s.TripHandler.DeleteTrip(w, r, tripId)
}

func (s *Server) AddTripMember(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	s.TripHandler.AddTripMember(w, r, tripId)
}

func (s *Server) ListTripMembers(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	s.TripHandler.ListTripMembers(w, r, tripId)
}

func (s *Server) RemoveTripMember(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, userId openapi_types.UUID) {
	s.TripHandler.RemoveTripMember(w, r, tripId, userId)
}

func (s *Server) ListItinerary(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	s.TripHandler.ListItinerary(w, r, tripId)
}

func (s *Server) AddItineraryItem(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	s.TripHandler.AddItineraryItem(w, r, tripId)
}

func (s *Server) UpdateItineraryItem(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, itemId openapi_types.UUID) {
	s.TripHandler.UpdateItineraryItem(w, r, tripId, itemId)
}

func (s *Server) DeleteItineraryItem(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, itemId openapi_types.UUID) {
	s.TripHandler.DeleteItineraryItem(w, r, tripId, itemId)
}
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
