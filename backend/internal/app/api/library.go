package api

import (
	"net/http"
	"summitmate/api"
	openapi_types "github.com/oapi-codegen/runtime/types"
)

func (s *Server) ListGearLibrary(w http.ResponseWriter, r *http.Request, params api.ListGearLibraryParams) {
	s.LibraryHandler.ListGearLibrary(w, r, params)
}

func (s *Server) CreateGearLibraryItem(w http.ResponseWriter, r *http.Request) {
	s.LibraryHandler.CreateGearLibraryItem(w, r)
}

func (s *Server) GetGearLibraryItem(w http.ResponseWriter, r *http.Request, itemId openapi_types.UUID) {
	s.LibraryHandler.GetGearLibraryItem(w, r, itemId)
}

func (s *Server) UpdateGearLibraryItem(w http.ResponseWriter, r *http.Request, itemId openapi_types.UUID) {
	s.LibraryHandler.UpdateGearLibraryItem(w, r, itemId)
}

func (s *Server) DeleteGearLibraryItem(w http.ResponseWriter, r *http.Request, itemId openapi_types.UUID) {
	s.LibraryHandler.DeleteGearLibraryItem(w, r, itemId)
}

func (s *Server) ReplaceAllGearLibraryItems(w http.ResponseWriter, r *http.Request) {
	s.LibraryHandler.ReplaceAllGearLibraryItems(w, r)
}

func (s *Server) ListMealLibrary(w http.ResponseWriter, r *http.Request, params api.ListMealLibraryParams) {
	s.LibraryHandler.ListMealLibrary(w, r, params)
}

func (s *Server) CreateMealLibraryItem(w http.ResponseWriter, r *http.Request) {
	s.LibraryHandler.CreateMealLibraryItem(w, r)
}

func (s *Server) GetMealLibraryItem(w http.ResponseWriter, r *http.Request, itemId openapi_types.UUID) {
	s.LibraryHandler.GetMealLibraryItem(w, r, itemId)
}

func (s *Server) UpdateMealLibraryItem(w http.ResponseWriter, r *http.Request, itemId openapi_types.UUID) {
	s.LibraryHandler.UpdateMealLibraryItem(w, r, itemId)
}

func (s *Server) DeleteMealLibraryItem(w http.ResponseWriter, r *http.Request, itemId openapi_types.UUID) {
	s.LibraryHandler.DeleteMealLibraryItem(w, r, itemId)
}

func (s *Server) ReplaceAllMealLibraryItems(w http.ResponseWriter, r *http.Request) {
	s.LibraryHandler.ReplaceAllMealLibraryItems(w, r)
}
