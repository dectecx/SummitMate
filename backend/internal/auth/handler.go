package auth

import (
	"net/http"

	"github.com/oapi-codegen/runtime/types"

	"summitmate/api"
	"summitmate/internal/platform/httpx"
	"summitmate/internal/store"
)

// Handler adapts the auth Service to the generated API. Embed it in the server type.
type Handler struct{ svc *Service }

func NewHandler(svc *Service) *Handler { return &Handler{svc: svc} }

func toAPIUser(u store.User) api.User {
	return api.User{Id: u.ID, Email: types.Email(u.Email), DisplayName: u.DisplayName, Avatar: u.Avatar, IsVerified: u.IsVerified}
}

func toAPITokens(t TokenPair) api.TokenPair {
	return api.TokenPair{AccessToken: t.AccessToken, RefreshToken: t.RefreshToken, ExpiresIn: int(t.ExpiresIn.Seconds())}
}

func (h *Handler) writeResult(w http.ResponseWriter, res Result) {
	httpx.WriteJSON(w, http.StatusOK, api.AuthResponse{Tokens: toAPITokens(res.Tokens), User: toAPIUser(res.User)})
}

func (h *Handler) Register(w http.ResponseWriter, r *http.Request) {
	var req api.RegisterRequest
	if err := httpx.Decode(w, r, &req); err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	avatar := ""
	if req.Avatar != nil {
		avatar = *req.Avatar
	}
	email, err := h.svc.Register(r.Context(), RegisterInput{
		Email: string(req.Email), Password: req.Password, DisplayName: req.DisplayName, Avatar: avatar,
	})
	if err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusCreated, api.RegisterResponse{Email: types.Email(email)})
}

func (h *Handler) VerifyEmail(w http.ResponseWriter, r *http.Request) {
	var req api.VerifyEmailRequest
	if err := httpx.Decode(w, r, &req); err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	res, err := h.svc.VerifyEmail(r.Context(), string(req.Email), req.Code)
	if err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	h.writeResult(w, res)
}

func (h *Handler) ResendVerification(w http.ResponseWriter, r *http.Request) {
	var req api.ResendVerificationJSONBody
	if err := httpx.Decode(w, r, &req); err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	if err := h.svc.ResendVerification(r.Context(), string(req.Email)); err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) Login(w http.ResponseWriter, r *http.Request) {
	var req api.LoginRequest
	if err := httpx.Decode(w, r, &req); err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	res, err := h.svc.Login(r.Context(), string(req.Email), req.Password)
	if err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	h.writeResult(w, res)
}

func (h *Handler) RefreshToken(w http.ResponseWriter, r *http.Request) {
	var req api.RefreshRequest
	if err := httpx.Decode(w, r, &req); err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	pair, err := h.svc.Refresh(r.Context(), req.RefreshToken)
	if err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, toAPITokens(pair))
}

func (h *Handler) Logout(w http.ResponseWriter, r *http.Request) {
	var req api.RefreshRequest
	if err := httpx.Decode(w, r, &req); err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	if err := h.svc.Logout(r.Context(), req.RefreshToken); err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) GetMe(w http.ResponseWriter, r *http.Request) {
	id, _ := UserID(r.Context())
	u, err := h.svc.Me(r.Context(), id)
	if err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, toAPIUser(u))
}

func (h *Handler) UpdateMe(w http.ResponseWriter, r *http.Request) {
	id, _ := UserID(r.Context())
	var req api.UpdateProfileRequest
	if err := httpx.Decode(w, r, &req); err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	u, err := h.svc.UpdateProfile(r.Context(), id, req.DisplayName, req.Avatar)
	if err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, toAPIUser(u))
}

func (h *Handler) DeleteMe(w http.ResponseWriter, r *http.Request) {
	id, _ := UserID(r.Context())
	if err := h.svc.DeleteAccount(r.Context(), id); err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) ChangePassword(w http.ResponseWriter, r *http.Request) {
	id, _ := UserID(r.Context())
	var req api.ChangePasswordRequest
	if err := httpx.Decode(w, r, &req); err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	if err := h.svc.ChangePassword(r.Context(), id, req.CurrentPassword, req.NewPassword); err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) SearchUsers(w http.ResponseWriter, r *http.Request, params api.SearchUsersParams) {
	users, err := h.svc.FindByEmail(r.Context(), string(params.Email))
	if err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	out := make([]api.PublicUser, 0, len(users))
	for _, u := range users {
		out = append(out, api.PublicUser{Id: u.ID, DisplayName: u.DisplayName, Avatar: u.Avatar})
	}
	httpx.WriteJSON(w, http.StatusOK, out)
}
