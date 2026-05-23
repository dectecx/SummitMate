package gearset

import (
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
	if err := apiutil.DecodeBody(r, &req); err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	gs := &GearSet{
		Title:       req.Title,
		Visibility:  GearSetVisibility(req.Visibility),
		DownloadKey: req.DownloadKey,
		UserID:      userID,
		CreatedBy:   userID,
		UpdatedBy:   userID,
	}

	for _, item := range req.Items {
		gi := GearSetItem{
			ID:       uuid.Must(uuid.NewV7()),
			Name:     item.Name,
			Category: item.Category,
			Weight:   item.Weight,
			Quantity: item.Quantity,
		}
		if item.OrderIndex != nil {
			gi.OrderIndex = *item.OrderIndex
		}
		gs.Items = append(gs.Items, gi)
	}

	if req.Meals != nil {
		for _, meal := range *req.Meals {
			gm := GearSetMeal{
				ID:       uuid.Must(uuid.NewV7()),
				Day:      meal.Day,
				MealType: meal.MealType,
				Name:     meal.Name,
				Note:     meal.Note,
			}
			if meal.Calories != nil {
				gm.Calories = *meal.Calories
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

// UpdateGearSet 更新指定的裝備組合
// (PUT /gear-sets/{id})
func (h *GearSetHandler) UpdateGearSet(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	var req api.GearSetCreateRequest
	if err := apiutil.DecodeBody(r, &req); err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	parsedID := uuid.UUID(id)
	gs := &GearSet{
		ID:          parsedID,
		Title:       req.Title,
		Visibility:  GearSetVisibility(req.Visibility),
		DownloadKey: req.DownloadKey,
	}

	for _, item := range req.Items {
		gi := GearSetItem{
			ID:       uuid.Must(uuid.NewV7()),
			Name:     item.Name,
			Category: item.Category,
			Weight:   item.Weight,
			Quantity: item.Quantity,
		}
		if item.OrderIndex != nil {
			gi.OrderIndex = *item.OrderIndex
		}
		gs.Items = append(gs.Items, gi)
	}

	if req.Meals != nil {
		for _, meal := range *req.Meals {
			gm := GearSetMeal{
				ID:       uuid.Must(uuid.NewV7()),
				Day:      meal.Day,
				MealType: meal.MealType,
				Name:     meal.Name,
				Note:     meal.Note,
			}
			if meal.Calories != nil {
				gm.Calories = *meal.Calories
			}
			gs.Meals = append(gs.Meals, gm)
		}
	}

	updated, err := h.svc.Update(r.Context(), gs, userID)
	if err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	apiutil.SendJSON(w, http.StatusOK, mapToResponse(updated))
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
	items := make([]api.GearSetItemResponse, 0, len(gs.Items))
	for _, it := range gs.Items {
		items = append(items, api.GearSetItemResponse{
			Id:         it.ID,
			Name:       it.Name,
			Category:   it.Category,
			Weight:     it.Weight,
			Quantity:   it.Quantity,
			OrderIndex: it.OrderIndex,
		})
	}

	var meals *[]api.GearSetMealResponse
	if len(gs.Meals) > 0 {
		mList := make([]api.GearSetMealResponse, 0, len(gs.Meals))
		for _, m := range gs.Meals {
			mList = append(mList, api.GearSetMealResponse{
				Id:       m.ID,
				Day:      m.Day,
				MealType: m.MealType,
				Name:     m.Name,
				Calories: m.Calories,
				Note:     m.Note,
			})
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
