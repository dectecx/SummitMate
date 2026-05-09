package api

import (
	"net/http"

	"summitmate/api"

	openapi_types "github.com/oapi-codegen/runtime/types"
)

func (s *Server) ListGearSets(w http.ResponseWriter, r *http.Request, params api.ListGearSetsParams) {
	s.GearSetHandler.ListGearSets(w, r, params)
}

func (s *Server) CreateGearSet(w http.ResponseWriter, r *http.Request) {
	s.GearSetHandler.CreateGearSet(w, r)
}

func (s *Server) GetGearSet(w http.ResponseWriter, r *http.Request, id openapi_types.UUID, params api.GetGearSetParams) {
	s.GearSetHandler.GetGearSet(w, r, id, params)
}

func (s *Server) DeleteGearSet(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	s.GearSetHandler.DeleteGearSet(w, r, id)
}
