package friends

import (
	"net/http"

	"github.com/google/uuid"
	openapi_types "github.com/oapi-codegen/runtime/types"

	"summitmate/api"
	"summitmate/internal/auth"
	"summitmate/internal/platform/apperror"
	"summitmate/internal/platform/httpx"
)

// Handler adapts the Service to the generated API. Embed it in the server type.
type Handler struct{ svc *Service }

func NewHandler(svc *Service) *Handler { return &Handler{svc: svc} }

// caller returns the authenticated user or writes a 401.
func caller(w http.ResponseWriter, r *http.Request) (uuid.UUID, bool) {
	id, ok := auth.UserID(r.Context())
	if !ok {
		httpx.WriteError(w, r, apperror.ErrUnauthorized)
		return uuid.Nil, false
	}
	return id, true
}

func publicUser(p Person) api.PublicUser {
	return api.PublicUser{Id: p.ID, DisplayName: p.DisplayName, Avatar: p.Avatar}
}

func requests(in []Request) []api.FriendRequest {
	out := make([]api.FriendRequest, 0, len(in))
	for _, q := range in {
		out = append(out, api.FriendRequest{RequestId: q.ID, User: publicUser(q.Person), CreatedAt: q.CreatedAt})
	}
	return out
}

func (h *Handler) ListFriends(w http.ResponseWriter, r *http.Request) {
	me, ok := caller(w, r)
	if !ok {
		return
	}
	l, err := h.svc.List(r.Context(), me)
	if err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	friends := make([]api.Friend, 0, len(l.Friends))
	for _, f := range l.Friends {
		friends = append(friends, api.Friend{UserId: f.ID, DisplayName: f.DisplayName, Avatar: f.Avatar, Since: f.Since})
	}
	httpx.WriteJSON(w, http.StatusOK, api.FriendList{Friends: friends, Incoming: requests(l.Incoming), Outgoing: requests(l.Outgoing)})
}

func (h *Handler) SendFriendRequest(w http.ResponseWriter, r *http.Request) {
	me, ok := caller(w, r)
	if !ok {
		return
	}
	var req api.SendFriendRequest
	if err := httpx.Decode(w, r, &req); err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	res, err := h.svc.Send(r.Context(), me, req.UserId)
	if err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	code := http.StatusOK
	if res.Created {
		code = http.StatusCreated
	}
	httpx.WriteJSON(w, code, api.FriendRequestResult{Status: api.FriendRequestResultStatus(res.Status), RequestId: res.RequestID})
}

func (h *Handler) AcceptFriendRequest(w http.ResponseWriter, r *http.Request, requestId openapi_types.UUID) {
	me, ok := caller(w, r)
	if !ok {
		return
	}
	if err := h.svc.Accept(r.Context(), me, requestId); err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) RemoveFriendRequest(w http.ResponseWriter, r *http.Request, requestId openapi_types.UUID) {
	me, ok := caller(w, r)
	if !ok {
		return
	}
	if err := h.svc.Remove(r.Context(), me, requestId); err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) Unfriend(w http.ResponseWriter, r *http.Request, userId openapi_types.UUID) {
	me, ok := caller(w, r)
	if !ok {
		return
	}
	if err := h.svc.Unfriend(r.Context(), me, userId); err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
