package api

import (
	"net/http"
	openapi_types "github.com/oapi-codegen/runtime/types"
)

func (s *Server) SearchUserByEmail(w http.ResponseWriter, r *http.Request) {
	s.AuthHandler.SearchUserByEmail(w, r)
}

func (s *Server) GetUserById(w http.ResponseWriter, r *http.Request, userId openapi_types.UUID) {
	s.AuthHandler.GetUserByID(w, r, userId.String())
}
