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

func (s *Server) GetHealth(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write([]byte(`{"status":"ok"}`))
}
