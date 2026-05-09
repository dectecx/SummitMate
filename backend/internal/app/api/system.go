package api

import (
	"net/http"
)

func (s *Server) UploadLogs(w http.ResponseWriter, r *http.Request) {
	s.LogHandler.UploadLogs(w, r)
}

func (s *Server) Heartbeat(w http.ResponseWriter, r *http.Request) {
	s.HeartbeatHandler.Heartbeat(w, r)
}

func (s *Server) GetFlags(w http.ResponseWriter, r *http.Request) {
	s.FlagHandler.GetFlags(w, r)
}

func (s *Server) UpdateFlag(w http.ResponseWriter, r *http.Request) {
	s.FlagHandler.UpdateFlag(w, r)
}

func (s *Server) GetHealth(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write([]byte(`{"status":"ok", "version":"1.0.0"}`))
}
