package flag

import (
	"net/http"

	"summitmate/internal/apperror"
	"summitmate/internal/common/apiutil"
)

type FlagHandler struct {
	svc FlagService
	// admin 用來限制只有管理員可以修改旗標。
	admin AdminChecker
	// allowDangerousFlags 為 false（正式環境）時，不允許開啟會降低安全性的旗標。
	allowDangerousFlags bool
}

func NewFlagHandler(svc FlagService, admin AdminChecker, allowDangerousFlags bool) *FlagHandler {
	return &FlagHandler{svc: svc, admin: admin, allowDangerousFlags: allowDangerousFlags}
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

	isAdmin, err := h.admin.IsAdmin(r.Context(), userID)
	if err != nil {
		apiutil.SendError(w, r, err)
		return
	}
	if !isAdmin {
		apiutil.SendError(w, r, apperror.ErrAccessDenied)
		return
	}

	if req.Value && dangerousFlags[req.Key] && !h.allowDangerousFlags {
		apiutil.SendError(w, r, apperror.ErrAccessDenied.WithMessage("此旗標不允許在目前環境開啟"))
		return
	}

	if err := h.svc.SetFlag(r.Context(), req.Key, req.Value, userID); err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}
