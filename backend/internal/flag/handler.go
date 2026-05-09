package flag

import (
	"encoding/json"
	"net/http"

	"summitmate/internal/common/apiutil"
)

type FlagHandler struct {
	svc FlagService
}

func NewFlagHandler(svc FlagService) *FlagHandler {
	return &FlagHandler{svc: svc}
}

// GetFlags 取得所有系統旗標
// (GET /flags)
func (h *FlagHandler) GetFlags(w http.ResponseWriter, r *http.Request) {
	flags, err := h.svc.GetAll(r.Context())
	if err != nil {
		apiutil.SendError(w, r, err)
		return
	}
	apiutil.SendJSON(w, http.StatusOK, flags)
}

// UpdateFlag 更新特定系統旗標
// (PUT /flags)
func (h *FlagHandler) UpdateFlag(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Key   string `json:"key"`
		Value bool   `json:"value"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	if err := h.svc.SetFlag(r.Context(), req.Key, req.Value); err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}
