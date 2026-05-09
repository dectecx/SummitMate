package gearset

import (
	"encoding/json"
	"net/http"

	"summitmate/api"
	"summitmate/internal/apperror"
	"summitmate/internal/common/apiutil"
	"summitmate/internal/middleware"

	openapi_types "github.com/oapi-codegen/runtime/types"

	"github.com/google/uuid"
)

type GearSetHandler struct {
	svc GearSetService
}

func NewGearSetHandler(svc GearSetService) *GearSetHandler {
	return &GearSetHandler{svc: svc}
}

// ListGearSets 取得裝備組合列表
// (GET /gear-sets)
func (h *GearSetHandler) ListGearSets(w http.ResponseWriter, r *http.Request, params api.ListGearSetsParams) {
	page := 1
	if params.Page != nil && *params.Page > 0 {
		page = *params.Page
	}
	limit := 20
	if params.Limit != nil && *params.Limit > 0 && *params.Limit <= 100 {
		limit = *params.Limit
	}
	search := ""
	if params.Search != nil {
		search = *params.Search
	}
	myUploaded := false
	if params.MyUploaded != nil {
		myUploaded = *params.MyUploaded
	}
	offset := (page - 1) * limit

	userID, loggedIn := middleware.GetUserIDFromContext(r.Context())
	if myUploaded && !loggedIn {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	sets, total, err := h.svc.List(r.Context(), limit, offset, search, userID, myUploaded)
	if err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	data := make([]api.GearSetResponse, 0, len(sets))
	for _, s := range sets {
		data = append(data, mapToResponse(s))
	}

	hasMore := offset+len(sets) < total
	resp := api.GearSetListResponse{
		Data: &data,
		Pagination: &api.PaginationMetadata{
			Page:    page,
			Limit:   limit,
			Total:   total,
			HasMore: hasMore,
		},
	}

	apiutil.SendJSON(w, http.StatusOK, resp)
}

// CreateGearSet 上傳新的裝備組合
// (POST /gear-sets)
func (h *GearSetHandler) CreateGearSet(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	var req api.GearSetCreateRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apiutil.SendError(w, r, apperror.ErrBadRequest)
		return
	}

	gs := &GearSet{
		Title:       req.Title,
		Author:      req.Author,
		Visibility:  GearSetVisibility(req.Visibility),
		DownloadKey: req.DownloadKey,
		UserID:      userID,
		CreatedBy:   userID,
		UpdatedBy:   userID,
	}

	if req.Id != nil {
		gs.ID = *req.Id
	}
	if req.TotalWeight != nil {
		gs.TotalWeight = *req.TotalWeight
	}
	if req.ItemCount != nil {
		gs.ItemCount = *req.ItemCount
	}

	for i, item := range req.Items {
		gi := GearSetItem{
			ID:         uuid.New(),
			OrderIndex: i,
		}
		if v, ok := item["name"].(string); ok {
			gi.Name = v
		}
		if v, ok := item["category"].(string); ok {
			gi.Category = v
		}
		if v, ok := item["weight"].(float64); ok {
			gi.Weight = v
		}
		if v, ok := item["quantity"].(float64); ok {
			gi.Quantity = int(v)
		} else {
			gi.Quantity = 1
		}
		gs.Items = append(gs.Items, gi)
	}

	if req.Meals != nil {
		for _, meal := range *req.Meals {
			gm := GearSetMeal{ID: uuid.New()}
			if v, ok := meal["day"].(string); ok {
				gm.Day = v
			}
			if v, ok := meal["meal_type"].(string); ok {
				gm.MealType = v
			}
			if v, ok := meal["name"].(string); ok {
				gm.Name = v
			}
			if v, ok := meal["calories"].(float64); ok {
				gm.Calories = v
			}
			if v, ok := meal["note"].(string); ok {
				gm.Note = &v
			}
			gs.Meals = append(gs.Meals, gm)
		}
	}

	created, err := h.svc.Create(r.Context(), gs)
	if err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	apiutil.SendJSON(w, http.StatusCreated, mapToResponse(created))
}

// GetGearSet 取得指定的裝備組合
// (GET /gear-sets/{id})
func (h *GearSetHandler) GetGearSet(w http.ResponseWriter, r *http.Request, id openapi_types.UUID, params api.GetGearSetParams) {
	userID, _ := middleware.GetUserIDFromContext(r.Context())

	var providedKey *string
	if params.Key != nil && *params.Key != "" {
		providedKey = params.Key
	} else if headerKey := r.Header.Get("X-Download-Key"); headerKey != "" {
		providedKey = &headerKey
	}

	parsedID := uuid.UUID(id)
	gs, err := h.svc.GetByID(r.Context(), parsedID, userID, providedKey)
	if err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	apiutil.SendJSON(w, http.StatusOK, mapToResponse(gs))
}

// DeleteGearSet 刪除指定的裝備組合
// (DELETE /gear-sets/{id})
func (h *GearSetHandler) DeleteGearSet(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	parsedID := uuid.UUID(id)
	err := h.svc.Delete(r.Context(), parsedID, userID)
	if err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func mapToResponse(gs *GearSet) api.GearSetResponse {
	items := make([]map[string]interface{}, 0, len(gs.Items))
	for _, it := range gs.Items {
		items = append(items, map[string]interface{}{
			"id":          it.ID.String(),
			"name":        it.Name,
			"category":    it.Category,
			"weight":      it.Weight,
			"quantity":    it.Quantity,
			"order_index": it.OrderIndex,
		})
	}

	var meals *[]map[string]interface{}
	if len(gs.Meals) > 0 {
		mList := make([]map[string]interface{}, 0, len(gs.Meals))
		for _, m := range gs.Meals {
			entry := map[string]interface{}{
				"id":        m.ID.String(),
				"day":       m.Day,
				"meal_type": m.MealType,
				"name":      m.Name,
				"calories":  m.Calories,
			}
			if m.Note != nil {
				entry["note"] = *m.Note
			}
			mList = append(mList, entry)
		}
		meals = &mList
	}

	// Parse string user IDs to UUID for API response
	createdBy, _ := uuid.Parse(gs.CreatedBy)
	updatedBy, _ := uuid.Parse(gs.UpdatedBy)

	resp := api.GearSetResponse{
		Id:          gs.ID,
		Title:       gs.Title,
		Author:      gs.Author,
		TotalWeight: gs.TotalWeight,
		ItemCount:   gs.ItemCount,
		Visibility:  string(gs.Visibility),
		Items:       items,
		Meals:       meals,
		CreatedAt:   gs.CreatedAt,
		CreatedBy:   createdBy,
		UpdatedAt:   gs.UpdatedAt,
		UpdatedBy:   updatedBy,
	}
	if gs.DownloadKey != nil {
		resp.DownloadKey = gs.DownloadKey
	}
	return resp
}
