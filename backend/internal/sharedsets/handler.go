package sharedsets

import (
	"net"
	"net/http"

	"github.com/google/uuid"
	openapi_types "github.com/oapi-codegen/runtime/types"

	"summitmate/api"
	"summitmate/internal/auth"
	"summitmate/internal/gearset"
	"summitmate/internal/platform/apperror"
	"summitmate/internal/platform/httpx"
)

// Handler adapts the Service to the generated API. Embed it in the server type.
type Handler struct{ svc *Service }

func NewHandler(svc *Service) *Handler { return &Handler{svc: svc} }

// viewer returns the authenticated user, if the middleware found a valid token.
func viewer(r *http.Request) *uuid.UUID {
	if id, ok := auth.UserID(r.Context()); ok {
		return &id
	}
	return nil
}

// clientID is the peer address; X-Forwarded-For is deliberately not trusted.
func clientID(r *http.Request) string {
	host, _, err := net.SplitHostPort(r.RemoteAddr)
	if err != nil {
		return r.RemoteAddr
	}
	return host
}

func (h *Handler) ListSharedSets(w http.ResponseWriter, r *http.Request, p api.ListSharedSetsParams) {
	if !p.Scope.Valid() {
		httpx.WriteError(w, r, errScope)
		return
	}
	in := ListInput{Mine: p.Scope == api.ListSharedSetsParamsScopeMine}
	if p.Q != nil {
		in.Q = *p.Q
	}
	if p.Limit != nil {
		in.Limit = *p.Limit
		if in.Limit == 0 {
			in.Limit = -1 // an explicit 0 is invalid
		}
	}
	if p.Cursor != nil {
		in.Cursor = *p.Cursor
	}
	v := viewer(r)
	page, err := h.svc.List(r.Context(), v, in)
	if err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	out := api.SharedSetPage{Items: make([]api.SharedSetSummary, 0, len(page.Sets))}
	for _, s := range page.Sets {
		out.Items = append(out.Items, summary(s, v))
	}
	if page.NextCursor != "" {
		c := page.NextCursor
		out.NextCursor = &c
	}
	httpx.WriteJSON(w, http.StatusOK, out)
}

func (h *Handler) CreateSharedSet(w http.ResponseWriter, r *http.Request) {
	v := viewer(r)
	if v == nil {
		httpx.WriteError(w, r, apperror.ErrUnauthorized)
		return
	}
	var req api.CreateSharedSetRequest
	if err := httpx.Decode(w, r, &req); err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	items := make([]gearset.Item, 0, len(req.Items))
	for _, it := range req.Items {
		items = append(items, gearset.Item{
			Kind: string(it.Kind), Name: it.Name, Category: it.Category, Weight: it.Weight,
			Quantity: it.Quantity, Calories: it.Calories, Day: it.Day, Note: it.Note,
		})
	}
	set, err := h.svc.Create(r.Context(), *v, CreateInput{
		Title: req.Title, Visibility: string(req.Visibility), AccessKey: req.AccessKey, Items: items,
	})
	if err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusCreated, summary(set, v))
}

func (h *Handler) GetSharedSet(w http.ResponseWriter, r *http.Request, id openapi_types.UUID, p api.GetSharedSetParams) {
	key := ""
	if p.XAccessKey != nil {
		key = *p.XAccessKey
	}
	v := viewer(r)
	set, err := h.svc.Get(r.Context(), v, id, key, clientID(r))
	if err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	sum := summary(set, v)
	items := make([]api.SharedItem, 0, len(set.Items))
	for _, it := range set.Items {
		items = append(items, api.SharedItem{
			Kind: api.SharedItemKind(it.Kind), Name: it.Name, Category: it.Category, Weight: it.Weight,
			Quantity: it.Quantity, Calories: it.Calories, Day: it.Day, Note: it.Note,
		})
	}
	httpx.WriteJSON(w, http.StatusOK, api.SharedSetDetail{
		AuthorName: sum.AuthorName, CreatedAt: sum.CreatedAt, GearCount: sum.GearCount, Id: sum.Id, Items: items,
		MealCount: sum.MealCount, Mine: sum.Mine, Title: sum.Title, TotalWeight: sum.TotalWeight, Visibility: sum.Visibility,
	})
}

func (h *Handler) DeleteSharedSet(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	v := viewer(r)
	if v == nil {
		httpx.WriteError(w, r, apperror.ErrUnauthorized)
		return
	}
	if err := h.svc.Delete(r.Context(), *v, id); err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func summary(s Set, v *uuid.UUID) api.SharedSetSummary {
	return api.SharedSetSummary{
		Id: s.ID, Title: s.Title, AuthorName: s.AuthorName, Visibility: api.SharedVisibility(s.Visibility),
		TotalWeight: s.TotalWeight, GearCount: s.GearCount, MealCount: s.MealCount, CreatedAt: s.CreatedAt,
		Mine: v != nil && *v == s.OwnerID,
	}
}
