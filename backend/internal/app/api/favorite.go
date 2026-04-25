package api

import (
	"net/http"
	"summitmate/api"

	openapi_types "github.com/oapi-codegen/runtime/types"
)

func (s *Server) ListFavorites(w http.ResponseWriter, r *http.Request, params api.ListFavoritesParams) {
	s.FavoriteHandler.ListFavorites(w, r, params)
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
