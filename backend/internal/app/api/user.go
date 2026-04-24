package api

import (
	"net/http"
	api_gen "summitmate/api"
	openapi_types "github.com/oapi-codegen/runtime/types"
)

func (s *Server) SearchUserByEmail(w http.ResponseWriter, r *http.Request, params api_gen.SearchUserByEmailParams) {
	s.AuthHandler.SearchUserByEmail(w, r, string(params.Email))
}

func (s *Server) GetUserById(w http.ResponseWriter, r *http.Request, userId openapi_types.UUID) {
	s.AuthHandler.GetUserByID(w, r, userId.String())
}
