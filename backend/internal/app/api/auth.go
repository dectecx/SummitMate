package api

import (
	"net/http"
)

func (s *Server) RegisterUser(w http.ResponseWriter, r *http.Request) {
	s.AuthHandler.RegisterUser(w, r)
}

func (s *Server) LoginUser(w http.ResponseWriter, r *http.Request) {
	s.AuthHandler.LoginUser(w, r)
}

func (s *Server) VerifyEmail(w http.ResponseWriter, r *http.Request) {
	s.AuthHandler.VerifyEmail(w, r)
}

func (s *Server) ResendVerificationCode(w http.ResponseWriter, r *http.Request) {
	s.AuthHandler.ResendVerificationCode(w, r)
}

func (s *Server) GetCurrentUser(w http.ResponseWriter, r *http.Request) {
	s.AuthHandler.GetCurrentUser(w, r)
}

func (s *Server) UpdateCurrentUser(w http.ResponseWriter, r *http.Request) {
	s.AuthHandler.UpdateCurrentUser(w, r)
}

func (s *Server) DeleteCurrentUser(w http.ResponseWriter, r *http.Request) {
	s.AuthHandler.DeleteCurrentUser(w, r)
}

func (s *Server) RefreshToken(w http.ResponseWriter, r *http.Request) {
	s.AuthHandler.RefreshToken(w, r)
}
