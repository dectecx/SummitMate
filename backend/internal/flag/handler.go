package flag

import (
	"encoding/json"
	"net/http"
)

type FlagHandler struct {
	svc Service
}

func NewFlagHandler(svc Service) *FlagHandler {
	return &FlagHandler{svc: svc}
}

// GetFlags 取得所有系統旗標。
func (h *FlagHandler) GetFlags(w http.ResponseWriter, r *http.Request) {
	flags, err := h.svc.GetAll(r.Context())
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(flags)
}

// UpdateFlag 更新特定系統旗標。
func (h *FlagHandler) UpdateFlag(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Key   string `json:"key"`
		Value bool   `json:"value"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	if err := h.svc.SetFlag(r.Context(), req.Key, req.Value); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}
