package handler

import (
	"encoding/json"
	"net/http"

	"summitmate/api"
	"summitmate/internal/middleware"
	"summitmate/internal/service"

	"time"

	"github.com/google/uuid"
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
		sendErrorResponse(w, http.StatusUnauthorized, "未登入")
		return
	}

	trips, err := h.svc.ListTrips(r.Context(), userID)
	if err != nil {
		sendErrorResponse(w, http.StatusInternalServerError, "無法取得行程列表: "+err.Error())
		return
	}

	// 轉換為 OpenAPI response
	var res []api.Trip
	for _, t := range trips {
		res = append(res, api.Trip{
			Id:          toOpenAPIUUID(t.ID),
			UserId:      toOpenAPIUUID(t.UserID),
			Name:        t.Name,
			Description: t.Description,
			StartDate:   toOpenAPIDate(t.StartDate),
			EndDate:     toOpenAPIDatePtr(t.EndDate),
			CoverImage:  t.CoverImage,
			IsActive:    t.IsActive,
			DayNames:    t.DayNames,
			CreatedAt:   toOpenAPITime(t.CreatedAt),
			UpdatedAt:   toOpenAPITime(t.UpdatedAt),
		})
	}
	if res == nil {
		res = []api.Trip{}
	}

	sendJSON(w, http.StatusOK, res)
}

// CreateTrip 建立新行程
// (POST /trips)
func (h *TripHandler) CreateTrip(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendErrorResponse(w, http.StatusUnauthorized, "未登入")
		return
	}

	var req api.TripCreateRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendErrorResponse(w, http.StatusBadRequest, "參數格式錯誤")
		return
	}

	var dayNames []string
	if req.DayNames != nil {
		dayNames = *req.DayNames
	}

	svcReq := &service.TripCreateRequest{
		Name:        req.Name,
		Description: req.Description,
		StartDate:   req.StartDate.Time.Format("2006-01-02"),
		EndDate:     toServiceDateStringPtr(req.EndDate),
		CoverImage:  req.CoverImage,
		DayNames:    dayNames,
	}

	createdTrip, err := h.svc.CreateTrip(r.Context(), userID, svcReq)
	if err != nil {
		sendErrorResponse(w, http.StatusInternalServerError, "建立行程失敗: "+err.Error())
		return
	}

	res := api.Trip{
		Id:          toOpenAPIUUID(createdTrip.ID),
		UserId:      toOpenAPIUUID(createdTrip.UserID),
		Name:        createdTrip.Name,
		Description: createdTrip.Description,
		StartDate:   toOpenAPIDate(createdTrip.StartDate),
		EndDate:     toOpenAPIDatePtr(createdTrip.EndDate),
		CoverImage:  createdTrip.CoverImage,
		IsActive:    createdTrip.IsActive,
		DayNames:    createdTrip.DayNames,
		CreatedAt:   toOpenAPITime(createdTrip.CreatedAt),
		UpdatedAt:   toOpenAPITime(createdTrip.UpdatedAt),
	}

	sendJSON(w, http.StatusCreated, res)
}

// GetTrip 取得特定行程詳細資料
// (GET /trips/{tripId})
func (h *TripHandler) GetTrip(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendErrorResponse(w, http.StatusUnauthorized, "未登入")
		return
	}

	trip, err := h.svc.GetTrip(r.Context(), tripId.String(), userID)
	if err != nil {
		if err == service.ErrUnauthorizedTripAccess {
			sendErrorResponse(w, http.StatusForbidden, "無權限存取此行程")
			return
		}
		sendErrorResponse(w, http.StatusNotFound, "找不到行程")
		return
	}

	res := api.Trip{
		Id:          toOpenAPIUUID(trip.ID),
		UserId:      toOpenAPIUUID(trip.UserID),
		Name:        trip.Name,
		Description: trip.Description,
		StartDate:   toOpenAPIDate(trip.StartDate),
		EndDate:     toOpenAPIDatePtr(trip.EndDate),
		CoverImage:  trip.CoverImage,
		IsActive:    trip.IsActive,
		DayNames:    trip.DayNames,
		CreatedAt:   toOpenAPITime(trip.CreatedAt),
		UpdatedAt:   toOpenAPITime(trip.UpdatedAt),
	}

	sendJSON(w, http.StatusOK, res)
}

// UpdateTrip 更新行程資料
// (PUT /trips/{tripId})
func (h *TripHandler) UpdateTrip(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendErrorResponse(w, http.StatusUnauthorized, "未登入")
		return
	}

	var req api.TripUpdateRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendErrorResponse(w, http.StatusBadRequest, "參數格式錯誤")
		return
	}

	var startDate *string
	if req.StartDate != nil {
		sd := req.StartDate.Time.Format("2006-01-02")
		startDate = &sd
	}
	svcReq := &service.TripUpdateRequest{
		Name:        req.Name,
		Description: req.Description,
		StartDate:   startDate,
		EndDate:     toServiceDateStringPtr(req.EndDate),
		CoverImage:  req.CoverImage,
		IsActive:    req.IsActive,
		DayNames:    req.DayNames,
	}

	updatedTrip, err := h.svc.UpdateTrip(r.Context(), tripId.String(), userID, svcReq)
	if err != nil {
		if err == service.ErrUnauthorizedTripAccess {
			sendErrorResponse(w, http.StatusForbidden, "無權限更新此行程")
			return
		}
		sendErrorResponse(w, http.StatusInternalServerError, "更新行程失敗: "+err.Error())
		return
	}

	res := api.Trip{
		Id:          toOpenAPIUUID(updatedTrip.ID),
		UserId:      toOpenAPIUUID(updatedTrip.UserID),
		Name:        updatedTrip.Name,
		Description: updatedTrip.Description,
		StartDate:   toOpenAPIDate(updatedTrip.StartDate),
		EndDate:     toOpenAPIDatePtr(updatedTrip.EndDate),
		CoverImage:  updatedTrip.CoverImage,
		IsActive:    updatedTrip.IsActive,
		DayNames:    updatedTrip.DayNames,
		CreatedAt:   toOpenAPITime(updatedTrip.CreatedAt),
		UpdatedAt:   toOpenAPITime(updatedTrip.UpdatedAt),
	}
	sendJSON(w, http.StatusOK, res)
}

// DeleteTrip 刪除行程
// (DELETE /trips/{tripId})
func (h *TripHandler) DeleteTrip(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendErrorResponse(w, http.StatusUnauthorized, "未登入")
		return
	}

	err := h.svc.DeleteTrip(r.Context(), tripId.String(), userID)
	if err != nil {
		if err == service.ErrCannotRemoveCreator {
			sendErrorResponse(w, http.StatusBadRequest, "無法移除行程建立者")
			return
		}
		if err == service.ErrUnauthorizedTripAccess {
			sendErrorResponse(w, http.StatusForbidden, "只有建立者可以刪除行程")
			return
		}
		sendErrorResponse(w, http.StatusInternalServerError, "刪除失敗: "+err.Error())
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
		sendErrorResponse(w, http.StatusUnauthorized, "未登入")
		return
	}

	members, err := h.svc.ListMembers(r.Context(), tripId.String(), userID)
	if err != nil {
		sendErrorResponse(w, http.StatusForbidden, "無權限存取成員列表")
		return
	}

	var res []api.TripMember
	for _, m := range members {
		res = append(res, api.TripMember{
			TripId:   toOpenAPIUUID(m.TripID),
			UserId:   toOpenAPIUUID(m.UserID),
			JoinedAt: toOpenAPITime(m.JoinedAt),
			UserMetadata: api.User{
				Id:          toOpenAPIUUID(m.UserID),
				Email:       openapi_types.Email(m.UserEmail),
				DisplayName: m.UserDisplayName,
				Avatar:      m.UserAvatar,
			},
		})
	}
	if res == nil {
		res = []api.TripMember{}
	}

	sendJSON(w, http.StatusOK, res)
}

// AddTripMember 新增成員到行程
// (POST /trips/{tripId}/members)
func (h *TripHandler) AddTripMember(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendErrorResponse(w, http.StatusUnauthorized, "未登入")
		return
	}

	var req api.AddMemberRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendErrorResponse(w, http.StatusBadRequest, "參數格式錯誤")
		return
	}

	member, err := h.svc.AddMember(r.Context(), tripId.String(), userID, string(req.Email))
	if err != nil {
		sendErrorResponse(w, http.StatusBadRequest, "無法新增成員: "+err.Error())
		return
	}

	res := api.TripMember{
		TripId:   toOpenAPIUUID(member.TripID),
		UserId:   toOpenAPIUUID(member.UserID),
		JoinedAt: toOpenAPITime(member.JoinedAt),
		UserMetadata: api.User{
			Id:          toOpenAPIUUID(member.UserID),
			Email:       openapi_types.Email(member.UserEmail),
			DisplayName: member.UserDisplayName,
			Avatar:      member.UserAvatar,
		},
	}
	sendJSON(w, http.StatusCreated, res)
}

// RemoveTripMember 將成員移出行程
// (DELETE /trips/{tripId}/members/{userId})
func (h *TripHandler) RemoveTripMember(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, targetUserId openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendErrorResponse(w, http.StatusUnauthorized, "未登入")
		return
	}

	err := h.svc.RemoveMember(r.Context(), tripId.String(), userID, targetUserId.String())
	if err != nil {
		if err == service.ErrCannotRemoveCreator {
			sendErrorResponse(w, http.StatusBadRequest, "無法移除行程建立者")
			return
		}
		if err == service.ErrUnauthorizedTripAccess {
			sendErrorResponse(w, http.StatusForbidden, "只有建立者可以移除其他成員")
			return
		}
		sendErrorResponse(w, http.StatusInternalServerError, "移除成員失敗")
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
		sendErrorResponse(w, http.StatusUnauthorized, "未登入")
		return
	}

	items, err := h.svc.ListItinerary(r.Context(), tripId.String(), userID)
	if err != nil {
		sendErrorResponse(w, http.StatusForbidden, "無權限存取行程表")
		return
	}

	var res []api.ItineraryItem
	for _, item := range items {
		res = append(res, api.ItineraryItem{
			Id:          toOpenAPIUUID(item.ID),
			TripId:      toOpenAPIUUID(item.TripID),
			Day:         item.Day,
			Name:        item.Name,
			EstTime:     item.EstTime,
			ActualTime:  toOpenAPITimePtr(item.ActualTime),
			Altitude:    int(item.Altitude), // OpenAPI gen produces int by default
			Distance:    item.Distance,
			Note:        item.Note,
			ImageAsset:  item.ImageAsset,
			IsCheckedIn: item.IsCheckedIn,
			CheckedInAt: toOpenAPITimePtr(item.CheckedInAt),
			CreatedAt:   toOpenAPITime(item.CreatedAt),
			UpdatedAt:   toOpenAPITime(item.UpdatedAt),
		})
	}
	if res == nil {
		res = []api.ItineraryItem{}
	}

	sendJSON(w, http.StatusOK, res)
}

// AddItineraryItem 新增行程表節點
// (POST /trips/{tripId}/itinerary)
func (h *TripHandler) AddItineraryItem(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendErrorResponse(w, http.StatusUnauthorized, "未登入")
		return
	}

	var req api.ItineraryItemRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendErrorResponse(w, http.StatusBadRequest, "參數格式錯誤")
		return
	}

	svcReq := &service.ItineraryItemRequest{
		Day:        req.Day,
		Name:       req.Name,
		EstTime:    req.EstTime,
		Altitude:   intPtrToInt32(req.Altitude),
		Distance:   float64PtrToFloat64(req.Distance),
		Note:       strPtrToStr(req.Note),
		ImageAsset: req.ImageAsset,
	}

	item, err := h.svc.AddItineraryItem(r.Context(), tripId.String(), userID, svcReq)
	if err != nil {
		sendErrorResponse(w, http.StatusForbidden, "無法新增: "+err.Error())
		return
	}

	res := api.ItineraryItem{
		Id:          toOpenAPIUUID(item.ID),
		TripId:      toOpenAPIUUID(item.TripID),
		Day:         item.Day,
		Name:        item.Name,
		EstTime:     item.EstTime,
		ActualTime:  item.ActualTime,
		Altitude:    int(item.Altitude),
		Distance:    item.Distance,
		Note:        item.Note,
		ImageAsset:  item.ImageAsset,
		IsCheckedIn: item.IsCheckedIn,
		CheckedInAt: item.CheckedInAt,
		CreatedAt:   item.CreatedAt,
		UpdatedAt:   item.UpdatedAt,
	}

	sendJSON(w, http.StatusCreated, res)
}

// UpdateItineraryItem 更新行程表節點
// (PUT /trips/{tripId}/itinerary/{itemId})
func (h *TripHandler) UpdateItineraryItem(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, itemId openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendErrorResponse(w, http.StatusUnauthorized, "未登入")
		return
	}

	var req api.ItineraryItemRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		sendErrorResponse(w, http.StatusBadRequest, "參數格式錯誤")
		return
	}

	svcReq := &service.ItineraryItemRequest{
		Day:        req.Day,
		Name:       req.Name,
		EstTime:    req.EstTime,
		Altitude:   intPtrToInt32(req.Altitude),
		Distance:   float64PtrToFloat64(req.Distance),
		Note:       strPtrToStr(req.Note),
		ImageAsset: req.ImageAsset,
	}

	item, err := h.svc.UpdateItineraryItem(r.Context(), tripId.String(), itemId.String(), userID, svcReq)
	if err != nil {
		sendErrorResponse(w, http.StatusForbidden, "無法更新: "+err.Error())
		return
	}

	res := api.ItineraryItem{
		Id:          toOpenAPIUUID(item.ID),
		TripId:      toOpenAPIUUID(item.TripID),
		Day:         item.Day,
		Name:        item.Name,
		EstTime:     item.EstTime,
		ActualTime:  item.ActualTime,
		Altitude:    int(item.Altitude),
		Distance:    item.Distance,
		Note:        item.Note,
		ImageAsset:  item.ImageAsset,
		IsCheckedIn: item.IsCheckedIn,
		CheckedInAt: item.CheckedInAt,
		CreatedAt:   item.CreatedAt,
		UpdatedAt:   item.UpdatedAt,
	}

	sendJSON(w, http.StatusOK, res)
}

// DeleteItineraryItem 刪除行程表節點
// (DELETE /trips/{tripId}/itinerary/{itemId})
func (h *TripHandler) DeleteItineraryItem(w http.ResponseWriter, r *http.Request, tripId openapi_types.UUID, itemId openapi_types.UUID) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		sendErrorResponse(w, http.StatusUnauthorized, "未登入")
		return
	}

	err := h.svc.DeleteItineraryItem(r.Context(), tripId.String(), itemId.String(), userID)
	if err != nil {
		sendErrorResponse(w, http.StatusForbidden, "無法刪除: "+err.Error())
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

// ------------------------------------------------------------------
// Helpers
// ------------------------------------------------------------------

func sendJSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(data)
}

func sendErrorResponse(w http.ResponseWriter, status int, message string) {
	sendJSON(w, status, api.ErrorResponse{Message: message})
}

func toOpenAPIUUID(s string) openapi_types.UUID {
	u, _ := uuid.Parse(s)
	return u
}

func toOpenAPIDate(s string) openapi_types.Date {
	t, _ := time.Parse("2006-01-02", s)
	return openapi_types.Date{Time: t}
}

func toOpenAPIDatePtr(s *string) *openapi_types.Date {
	if s == nil {
		return nil
	}
	d := toOpenAPIDate(*s)
	return &d
}

func toServiceDateStringPtr(d *openapi_types.Date) *string {
	if d == nil {
		return nil
	}
	s := d.Time.Format("2006-01-02")
	return &s
}

func toOpenAPITime(t time.Time) time.Time {
	return t
}

func toOpenAPITimePtr(t *time.Time) *time.Time {
	return t
}

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
