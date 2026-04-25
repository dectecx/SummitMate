package api

import (
	openapi_types "github.com/oapi-codegen/runtime/types"
	"net/http"
)

func (s *Server) ListTripMessages(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	s.InteractionHandler.ListTripMessages(w, r, tripId)
}

func (s *Server) AddTripMessage(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	s.InteractionHandler.AddTripMessage(w, r, tripId)
}

func (s *Server) UpdateTripMessage(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, messageId openapi_types.UUID) {
	s.InteractionHandler.UpdateTripMessage(w, r, tripId, messageId)
}

func (s *Server) DeleteTripMessage(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, messageId openapi_types.UUID) {
	s.InteractionHandler.DeleteTripMessage(w, r, tripId, messageId)
}

func (s *Server) ListTripPolls(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	s.InteractionHandler.ListTripPolls(w, r, tripId)
}

func (s *Server) CreateTripPoll(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	s.InteractionHandler.CreateTripPoll(w, r, tripId)
}

func (s *Server) GetTripPoll(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, pollId openapi_types.UUID) {
	s.InteractionHandler.GetTripPoll(w, r, tripId, pollId)
}

func (s *Server) DeleteTripPoll(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, pollId openapi_types.UUID) {
	s.InteractionHandler.DeleteTripPoll(w, r, tripId, pollId)
}

func (s *Server) AddPollOption(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, pollId openapi_types.UUID) {
	s.InteractionHandler.AddPollOption(w, r, tripId, pollId)
}

func (s *Server) VotePollOption(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, pollId openapi_types.UUID, optionId openapi_types.UUID) {
	s.InteractionHandler.VotePollOption(w, r, tripId, pollId, optionId)
}
