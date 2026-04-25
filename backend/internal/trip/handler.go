package trip

import (
	"encoding/json"
	"net/http"

	"summitmate/api"
	"summitmate/internal/apperror"
	"summitmate/internal/common/apiutil"

	openapi_types "github.com/oapi-codegen/runtime/types"
)

// TripHandler 處理行程相關的 HTTP 請求。
type TripHandler struct {
	svc TripService
}

func NewTripHandler(svc TripService) *TripHandler {
	return &TripHandler{svc: svc}
}

// ListTrips 取得當前使用者的行程列表 (GET /trips)
func (h *TripHandler) ListTrips(w http.ResponseWriter, r *http.Request, params api.ListTripsParams) {
	userID, ok := apiutil.GetUserIDFromRequest(r)
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	page := 1
	if params.Page != nil && *params.Page > 0 {
		page = *params.Page
	}
	limit := 20
	if params.Limit != nil && *params.Limit > 0 {
		limit = *params.Limit
	}
	search := ""
	if params.Search != nil {
		search = *params.Search
	}

	trips, total, hasMore, err := h.svc.ListTrips(r.Context(), userID, page, limit, search)
	if err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	items := make([]api.TripListItemResponse, len(trips))
	for i, t := range trips {
		items[i] = ToTripListItem(*t)
	}

	resp := api.TripListPaginationResponse{
		Items: items,
		Pagination: api.PaginationMetadata{
			HasMore: hasMore,
			Page:    page,
			Limit:   limit,
			Total:   total,
		},
	}

	apiutil.SendJSON(w, http.StatusOK, resp)
}

// CreateTrip 建立新行程 (POST /trips)
func (h *TripHandler) CreateTrip(w http.ResponseWriter, r *http.Request) {
	userID, ok := apiutil.GetUserIDFromRequest(r)
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	var req api.TripCreateRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apiutil.SendError(w, r, apperror.ErrBadRequest)
		return
	}

	svcReq := ToServiceTripCreateReq(req)
	trip, err := h.svc.CreateTrip(r.Context(), userID, svcReq)
	if err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	apiutil.SendJSON(w, http.StatusCreated, ToTripCreateResponse(*trip))
}

// GetTrip 取得單一行程詳情 (GET /trips/{tripId})
func (h *TripHandler) GetTrip(w http.ResponseWriter, r *http.Request, tripID openapi_types.UUID) {
	userID, ok := apiutil.GetUserIDFromRequest(r)
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	trip, err := h.svc.GetTrip(r.Context(), tripID.String(), userID)
	if err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	apiutil.SendJSON(w, http.StatusOK, ToTripGetResponse(*trip))
}

// UpdateTrip 更新行程資料 (PATCH /trips/{tripId})
func (h *TripHandler) UpdateTrip(w http.ResponseWriter, r *http.Request, tripID openapi_types.UUID) {
	userID, ok := apiutil.GetUserIDFromRequest(r)
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	var req api.TripUpdateRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apiutil.SendError(w, r, apperror.ErrBadRequest)
		return
	}

	svcReq := ToServiceTripUpdateReq(req)
	trip, err := h.svc.UpdateTrip(r.Context(), tripID.String(), userID, svcReq)
	if err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	apiutil.SendJSON(w, http.StatusOK, ToTripUpdateResponse(*trip))
}

// DeleteTrip 刪除行程 (DELETE /trips/{tripId})
func (h *TripHandler) DeleteTrip(w http.ResponseWriter, r *http.Request, tripID openapi_types.UUID) {
	userID, ok := apiutil.GetUserIDFromRequest(r)
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	if err := h.svc.DeleteTrip(r.Context(), tripID.String(), userID); err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// ListTripMembers 取得行程成員列表 (GET /trips/{tripId}/members)
func (h *TripHandler) ListTripMembers(w http.ResponseWriter, r *http.Request, tripID openapi_types.UUID) {
	userID, ok := apiutil.GetUserIDFromRequest(r)
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	members, err := h.svc.ListMembers(r.Context(), tripID.String(), userID)
	if err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	apiutil.SendJSON(w, http.StatusOK, members)
}

// AddTripMember 邀請成員加入行程 (POST /trips/{tripId}/members)
func (h *TripHandler) AddTripMember(w http.ResponseWriter, r *http.Request, tripID openapi_types.UUID) {
	userID, ok := apiutil.GetUserIDFromRequest(r)
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	var req struct {
		Email string `json:"email"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apiutil.SendError(w, r, apperror.ErrBadRequest)
		return
	}

	member, err := h.svc.AddMember(r.Context(), tripID.String(), userID, req.Email)
	if err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	apiutil.SendJSON(w, http.StatusCreated, member)
}

// RemoveTripMember 移除非建立者的成員 (DELETE /trips/{tripId}/members/{userId})
func (h *TripHandler) RemoveTripMember(w http.ResponseWriter, r *http.Request, tripID openapi_types.UUID, userID openapi_types.UUID) {
	actionUserID, ok := apiutil.GetUserIDFromRequest(r)
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	if err := h.svc.RemoveMember(r.Context(), tripID.String(), actionUserID, userID.String()); err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// ListItinerary 取得行程表 (GET /trips/{tripId}/itinerary)
func (h *TripHandler) ListItinerary(w http.ResponseWriter, r *http.Request, tripID openapi_types.UUID) {
	userID, ok := apiutil.GetUserIDFromRequest(r)
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	itinerary, err := h.svc.ListItinerary(r.Context(), tripID.String(), userID)
	if err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	resp := make([]api.ItineraryItemListItemResponse, len(itinerary))
	for i, item := range itinerary {
		resp[i] = ToItineraryItemListItemResponse(item)
	}

	apiutil.SendJSON(w, http.StatusOK, resp)
}

// AddItineraryItem 新增行程表項目 (POST /trips/{tripId}/itinerary)
func (h *TripHandler) AddItineraryItem(w http.ResponseWriter, r *http.Request, tripID openapi_types.UUID) {
	userID, ok := apiutil.GetUserIDFromRequest(r)
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	var req api.ItineraryItemRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apiutil.SendError(w, r, apperror.ErrBadRequest)
		return
	}

	svcReq := ToServiceItineraryItemReq(req)
	item, err := h.svc.AddItineraryItem(r.Context(), tripID.String(), userID, &svcReq)
	if err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	apiutil.SendJSON(w, http.StatusCreated, ToItineraryItemCreateResponse(item))
}

// UpdateItineraryItem 更新行程表項目 (PATCH /trips/{tripId}/itinerary/{itemId})
func (h *TripHandler) UpdateItineraryItem(w http.ResponseWriter, r *http.Request, tripID openapi_types.UUID, itemID openapi_types.UUID) {
	userID, ok := apiutil.GetUserIDFromRequest(r)
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	var req api.ItineraryItemRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		apiutil.SendError(w, r, apperror.ErrBadRequest)
		return
	}

	svcReq := ToServiceItineraryItemReq(req)
	item, err := h.svc.UpdateItineraryItem(r.Context(), tripID.String(), itemID.String(), userID, &svcReq)
	if err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	apiutil.SendJSON(w, http.StatusOK, ToItineraryItemUpdateResponse(item))
}

// DeleteItineraryItem 刪除行程表項目 (DELETE /trips/{tripId}/itinerary/{itemId})
func (h *TripHandler) DeleteItineraryItem(w http.ResponseWriter, r *http.Request, tripID openapi_types.UUID, itemID openapi_types.UUID) {
	userID, ok := apiutil.GetUserIDFromRequest(r)
	if !ok {
		apiutil.SendError(w, r, apperror.ErrUnauthorized)
		return
	}

	if err := h.svc.DeleteItineraryItem(r.Context(), tripID.String(), itemID.String(), userID); err != nil {
		apiutil.SendError(w, r, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}
