package api

import (
	openapi_types "github.com/oapi-codegen/runtime/types"
	"net/http"
	"summitmate/api"
)

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
