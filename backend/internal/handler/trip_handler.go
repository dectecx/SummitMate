package handler

import (
	"encoding/json"
	"net/http"

	"summitmate/api"
	"summitmate/internal/apperror"
	"summitmate/internal/handler/mapping"
	"summitmate/internal/middleware"
	"summitmate/internal/service"

	openapi_types "github.com/oapi-codegen/runtime/types"
)

// TripHandler 處理 /trips 相關的 HTTP 請求。
type TripHandler struct {
	svc *service.TripService
}

// NewTripHandler 建立 TripHandler 實例。
func NewTripHandler(svc *service.TripService) *TripHandler {
	return &TripHandler{svc: svc}
}

// ------------------------------------------------------------------
// Trip CRUD
// ------------------------------------------------------------------

// ListTrips 取得我建立或加入的行程列表
// (GET /trips)
func (h *TripHandler) ListTrips(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendError(w, r, apperror.ErrUnauthorized)
		return
	}

	trips, err := h.svc.ListTrips(r.Context(), userID)
	if err != nil {
		sendError(w, r, err)
		return
	}

	res := make([]api.TripListItemResponse, 0, len(trips))
	for _, t := range trips {
		res = append(res, mapping.ToTripListItem(*t))
	}

	sendJSON(w, http.StatusOK, res)
}

// CreateTrip 建立新行程
// (POST /trips)
func (h *TripHandler) CreateTrip(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendError(w, r, apperror.ErrUnauthorized)
		return
	}

	var req api.TripCreateRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendError(w, r, apperror.ErrBadRequest)
		return
	}

	svcReq := mapping.ToServiceTripCreateReq(req)

	createdTrip, err := h.svc.CreateTrip(r.Context(), userID, svcReq)
	if err != nil {
		sendError(w, r, err)
		return
	}

	sendJSON(w, http.StatusCreated, mapping.ToTripCreateResponse(*createdTrip))
}

// GetTrip 取得特定行程詳細資料
// (GET /trips/{tripId})
func (h *TripHandler) GetTrip(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendError(w, r, apperror.ErrUnauthorized)
		return
	}

	trip, err := h.svc.GetTrip(r.Context(), tripId.String(), userID)
	if err != nil {
		sendError(w, r, err)
		return
	}

	sendJSON(w, http.StatusOK, mapping.ToTripGetResponse(*trip))
}

// UpdateTrip 更新行程資料
// (PUT /trips/{tripId})
func (h *TripHandler) UpdateTrip(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendError(w, r, apperror.ErrUnauthorized)
		return
	}

	var req api.TripUpdateRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendError(w, r, apperror.ErrBadRequest)
		return
	}

	svcReq := mapping.ToServiceTripUpdateReq(req)

	updatedTrip, err := h.svc.UpdateTrip(r.Context(), tripId.String(), userID, svcReq)
	if err != nil {
		sendError(w, r, err)
		return
	}

	sendJSON(w, http.StatusOK, mapping.ToTripUpdateResponse(*updatedTrip))
}

// DeleteTrip 刪除行程
// (DELETE /trips/{tripId})
func (h *TripHandler) DeleteTrip(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendError(w, r, apperror.ErrUnauthorized)
		return
	}

	err := h.svc.DeleteTrip(r.Context(), tripId.String(), userID)
	if err != nil {
		sendError(w, r, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// ------------------------------------------------------------------
// Trip Members
// ------------------------------------------------------------------

// ListTripMembers 取得行程成員列表
// (GET /trips/{tripId}/members)
func (h *TripHandler) ListTripMembers(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendError(w, r, apperror.ErrUnauthorized)
		return
	}

	members, err := h.svc.ListMembers(r.Context(), tripId.String(), userID)
	if err != nil {
		sendError(w, r, err)
		return
	}

	res := make([]api.TripMemberListItemResponse, 0, len(members))
	for _, m := range members {
		res = append(res, mapping.ToTripMemberListItemResponse(m))
	}

	sendJSON(w, http.StatusOK, res)
}

// AddTripMember 新增成員到行程
// (POST /trips/{tripId}/members)
func (h *TripHandler) AddTripMember(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendError(w, r, apperror.ErrUnauthorized)
		return
	}

	var req api.AddMemberRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendError(w, r, apperror.ErrBadRequest)
		return
	}

	member, err := h.svc.AddMember(r.Context(), tripId.String(), userID, string(req.Email))
	if err != nil {
		sendError(w, r, err)
		return
	}

	sendJSON(w, http.StatusCreated, mapping.ToTripMemberGetResponse(member))
}

// RemoveTripMember 將成員移出行程
// (DELETE /trips/{tripId}/members/{userId})
func (h *TripHandler) RemoveTripMember(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, targetUserId openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendError(w, r, apperror.ErrUnauthorized)
		return
	}

	err := h.svc.RemoveMember(r.Context(), tripId.String(), userID, targetUserId.String())
	if err != nil {
		sendError(w, r, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// ------------------------------------------------------------------
// Itinerary
// ------------------------------------------------------------------

// ListItinerary 取得行程表
// (GET /trips/{tripId}/itinerary)
func (h *TripHandler) ListItinerary(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendError(w, r, apperror.ErrUnauthorized)
		return
	}

	items, err := h.svc.ListItinerary(r.Context(), tripId.String(), userID)
	if err != nil {
		sendError(w, r, err)
		return
	}

	res := make([]api.ItineraryItemListItemResponse, 0, len(items))
	for _, item := range items {
		res = append(res, mapping.ToItineraryItemListItemResponse(item))
	}

	sendJSON(w, http.StatusOK, res)
}

// AddItineraryItem 新增行程表節點
// (POST /trips/{tripId}/itinerary)
func (h *TripHandler) AddItineraryItem(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendError(w, r, apperror.ErrUnauthorized)
		return
	}

	var req api.ItineraryItemRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendError(w, r, apperror.ErrBadRequest)
		return
	}

	svcReq := mapping.ToServiceItineraryItemReq(req)

	item, err := h.svc.AddItineraryItem(r.Context(), tripId.String(), userID, &svcReq)
	if err != nil {
		sendError(w, r, err)
		return
	}

	sendJSON(w, http.StatusCreated, mapping.ToItineraryItemCreateResponse(item))
}

// UpdateItineraryItem 更新行程表節點
// (PUT /trips/{tripId}/itinerary/{itemId})
func (h *TripHandler) UpdateItineraryItem(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, itemId openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendError(w, r, apperror.ErrUnauthorized)
		return
	}

	var req api.ItineraryItemRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendError(w, r, apperror.ErrBadRequest)
		return
	}

	svcReq := mapping.ToServiceItineraryItemReq(req)

	item, err := h.svc.UpdateItineraryItem(r.Context(), tripId.String(), itemId.String(), userID, &svcReq)
	if err != nil {
		sendError(w, r, err)
		return
	}

	sendJSON(w, http.StatusOK, mapping.ToItineraryItemUpdateResponse(item))
}

// DeleteItineraryItem 刪除行程表節點
// (DELETE /trips/{tripId}/itinerary/{itemId})
func (h *TripHandler) DeleteItineraryItem(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, itemId openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendError(w, r, apperror.ErrUnauthorized)
		return
	}

	err := h.svc.DeleteItineraryItem(r.Context(), tripId.String(), itemId.String(), userID)
	if err != nil {
		sendError(w, r, err)
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// ------------------------------------------------------------------
// Helpers
// ------------------------------------------------------------------

func intPtrToInt32(ptr *int) int32 {
	if ptr == nil {
		return 0
	}
	return int32(*ptr)
}

func float64PtrToFloat64(ptr *float64) float64 {
	if ptr == nil {
		return 0
	}
	return *ptr
}

func strPtrToStr(ptr *string) string {
	if ptr == nil {
		return ""
	}
	return *ptr
}
