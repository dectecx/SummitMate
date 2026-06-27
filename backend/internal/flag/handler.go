package flag

import (
	"net/http"

	"summitmate/internal/apperror"
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
	apiutil.SendJSON(w, http.StatusOK, ToSystemFlagResponseList(flags))
}

// UpdateFlag 更新特定系統旗標
// (PUT /flags)
func (h *FlagHandler) UpdateFlag(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Key   string `json:"key"`
		Value bool   `json:"value"`
	}
	if err := apiutil.DecodeBody(r, &req); err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	userID, ok := apiutil.GetUserIDFromRequest(r)
	if !ok || userID == "" {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	if err := h.svc.SetFlag(r.Context(), req.Key, req.Value, userID); err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}
