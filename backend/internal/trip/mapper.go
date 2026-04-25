package trip

import (
	"time"

	"github.com/google/uuid"
	"github.com/oapi-codegen/runtime/types"

	"summitmate/api"
)

// ToServiceTripCreateReq converts api.TripCreateRequest to TripCreateRequest
func ToServiceTripCreateReq(req api.TripCreateRequest) *TripCreateRequest {
	startDate := req.StartDate.Time

	var endDate *time.Time
	if req.EndDate != nil {
		endDate = &req.EndDate.Time
	}

	var dayNames []string
	if req.DayNames != nil {
		dayNames = *req.DayNames
	} else {
		dayNames = []string{}
	}

	return &TripCreateRequest{
		Name:        req.Name,
		Description: req.Description,
		StartDate:   startDate,
		EndDate:     endDate,
		CoverImage:  req.CoverImage,
		DayNames:    dayNames,
	}
}

// ToServiceTripUpdateReq converts api.TripUpdateRequest to TripUpdateRequest
func ToServiceTripUpdateReq(req api.TripUpdateRequest) *TripUpdateRequest {
	var startDate *time.Time
	if req.StartDate != nil {
		t := req.StartDate.Time
		startDate = &t
	}

	var endDate *time.Time
	if req.EndDate != nil {
		t := req.EndDate.Time
		endDate = &t
	}

	return &TripUpdateRequest{
		Name:          req.Name,
		Description:   req.Description,
		StartDate:     startDate,
		EndDate:       endDate,
		CoverImage:    req.CoverImage,
		IsActive:      req.IsActive,
		DayNames:      req.DayNames,
		LastUpdatedAt: req.LastUpdatedAt,
	}
}

// ToTripGetResponse converts Trip to api.TripGetResponse
func ToTripGetResponse(t Trip) api.TripGetResponse {
	var endDate *types.Date
	if t.EndDate != nil {
		endDate = &types.Date{Time: *t.EndDate}
	}

	return api.TripGetResponse{
		Id:          uuid.MustParse(t.ID),
		UserId:      uuid.MustParse(t.UserID),
		Name:        t.Name,
		Description: t.Description,
		StartDate:   types.Date{Time: t.StartDate},
		EndDate:     endDate,
		CoverImage:  t.CoverImage,
		IsActive:    t.IsActive,
		DayNames:    t.DayNames,
		CreatedAt:   t.CreatedAt,
		CreatedBy:   uuid.MustParse(t.CreatedBy),
		UpdatedAt:   t.UpdatedAt,
		UpdatedBy:   uuid.MustParse(t.UpdatedBy),
	}
}

// ToTripCreateResponse converts Trip to api.TripCreateResponse
func ToTripCreateResponse(t Trip) api.TripCreateResponse {
	// TripCreateResponse is an alias for TripGetResponse
	return ToTripGetResponse(t)
}

// ToTripUpdateResponse converts Trip to api.TripUpdateResponse
func ToTripUpdateResponse(t Trip) api.TripUpdateResponse {
	// TripUpdateResponse is an alias for TripGetResponse
	return ToTripGetResponse(t)
}

// ToTripListItem converts Trip to api.TripListItemResponse
func ToTripListItem(t Trip) api.TripListItemResponse {
	var endDate *types.Date
	if t.EndDate != nil {
		endDate = &types.Date{Time: *t.EndDate}
	}

	return api.TripListItemResponse{
		Id:         uuid.MustParse(t.ID),
		Name:       t.Name,
		CoverImage: t.CoverImage,
		StartDate:  types.Date{Time: t.StartDate},
		EndDate:    endDate,
		IsActive:   t.IsActive,
		CreatedAt:  t.CreatedAt,
	}
}

// --- Itinerary Mappers ---

// ToServiceItineraryItemReq converts api.ItineraryItemRequest to ItineraryItemRequest
func ToServiceItineraryItemReq(req api.ItineraryItemRequest) ItineraryItemRequest {
	var distance float64 = 0
	if req.Distance != nil {
		distance = float64(*req.Distance)
	}
	var altitude int32 = 0
	if req.Altitude != nil {
		altitude = int32(*req.Altitude)
	}
	var note string = ""
	if req.Note != nil {
		note = *req.Note
	}

	return ItineraryItemRequest{
		Day:        req.Day,
		Name:       req.Name,
		EstTime:    req.EstTime,
		Altitude:   altitude,
		Distance:   distance,
		Note:       note,
		ImageAsset: req.ImageAsset,
	}
}

// ToItineraryItemGetResponse converts ItineraryItem to api.ItineraryItemGetResponse
func ToItineraryItemGetResponse(item *ItineraryItem) api.ItineraryItemGetResponse {
	return api.ItineraryItemGetResponse{
		Id:          uuid.MustParse(item.ID),
		TripId:      uuid.MustParse(item.TripID),
		Day:         item.Day,
		Name:        item.Name,
		EstTime:     item.EstTime,
		ActualTime:  item.ActualTime,
		Altitude:    int(item.Altitude),
		Distance:    float64(item.Distance),
		Note:        item.Note,
		ImageAsset:  item.ImageAsset,
		IsCheckedIn: item.IsCheckedIn,
		CheckedInAt: item.CheckedInAt,
		CreatedAt:   item.CreatedAt,
		UpdatedAt:   item.UpdatedAt,
	}
}

// ToItineraryItemCreateResponse converts ItineraryItem to api.ItineraryItemCreateResponse
func ToItineraryItemCreateResponse(item *ItineraryItem) api.ItineraryItemCreateResponse {
	return api.ItineraryItemCreateResponse(ToItineraryItemGetResponse(item))
}

// ToItineraryItemUpdateResponse converts ItineraryItem to api.ItineraryItemUpdateResponse
func ToItineraryItemUpdateResponse(item *ItineraryItem) api.ItineraryItemUpdateResponse {
	return api.ItineraryItemUpdateResponse(ToItineraryItemGetResponse(item))
}

// ToItineraryItemListItemResponse converts ItineraryItem to api.ItineraryItemListItemResponse
func ToItineraryItemListItemResponse(item *ItineraryItem) api.ItineraryItemListItemResponse {
	return api.ItineraryItemListItemResponse(ToItineraryItemGetResponse(item))
}
