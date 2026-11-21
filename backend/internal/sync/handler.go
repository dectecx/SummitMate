package sync

import (
	"net/http"

	"summitmate/api"
	"summitmate/internal/auth"
	"summitmate/internal/platform/apperror"
	"summitmate/internal/platform/httpx"
)

// Handler adapts the sync Service to the generated API. Embed it in the server type.
type Handler struct{ svc *Service }

func NewHandler(svc *Service) *Handler { return &Handler{svc: svc} }

func (h *Handler) PullChanges(w http.ResponseWriter, r *http.Request, params api.PullChangesParams) {
	userID, ok := auth.UserID(r.Context())
	if !ok {
		httpx.WriteError(w, r, apperror.ErrUnauthorized)
		return
	}
	limit := 0
	if params.Limit != nil {
		limit = *params.Limit
		if limit < 1 || limit > maxPullLimit {
			httpx.WriteError(w, r, apperror.New(http.StatusBadRequest, apperror.TypeValidation, "invalid_limit", "limit 必須介於 1 到 500").WithParam("limit"))
			return
		}
	}
	ch, err := h.svc.Pull(r.Context(), userID, params.Since, limit)
	if err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, api.ChangesResponse{
		ServerTime: ch.ServerTime, NextSince: ch.NextSince, HasMore: ch.HasMore, Changes: ch.Rows,
	})
}

func (h *Handler) PushOps(w http.ResponseWriter, r *http.Request) {
	userID, ok := auth.UserID(r.Context())
	if !ok {
		httpx.WriteError(w, r, apperror.ErrUnauthorized)
		return
	}
	var req api.PushRequest
	if err := httpx.Decode(w, r, &req); err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	if len(req.Ops) == 0 || len(req.Ops) > MaxPushOps {
		httpx.WriteError(w, r, apperror.ErrBadRequest.WithParam("ops"))
		return
	}
	ops := make([]Op, 0, len(req.Ops))
	for _, o := range req.Ops {
		op := Op{OpID: o.OpId, Entity: string(o.Entity), EntityID: o.EntityId, Delete: o.Type == "delete"}
		if o.Type != "delete" && o.Type != "upsert" {
			httpx.WriteError(w, r, apperror.ErrBadRequest.WithParam("type"))
			return
		}
		if o.Patch != nil {
			op.Patch = *o.Patch
		}
		ops = append(ops, op)
	}
	results, err := h.svc.Push(r.Context(), userID, ops)
	if err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	out := make([]api.PushResult, 0, len(results))
	for _, res := range results {
		pr := api.PushResult{OpId: res.OpID, Status: api.PushResultStatus(res.Status)}
		if res.Message != "" {
			m := res.Message
			pr.Message = &m
		}
		if res.Row != nil {
			row := res.Row
			pr.Row = &row
		}
		out = append(out, pr)
	}
	httpx.WriteJSON(w, http.StatusOK, api.PushResponse{Results: out})
}
