package mapping

import (
	"time"

	"github.com/google/uuid"

	"summitmate/api"
	"summitmate/internal/model"
	"summitmate/internal/service"
	"github.com/oapi-codegen/runtime/types"
)

// ToServiceTripCreateReq converts api.TripCreateRequest to service.TripCreateRequest
func ToServiceTripCreateReq(req api.TripCreateRequest) *service.TripCreateRequest {
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

	return &service.TripCreateRequest{
		Name:        req.Name,
		Description: req.Description,
		StartDate:   startDate,
		EndDate:     endDate,
		CoverImage:  req.CoverImage,
		DayNames:    dayNames,
	}
}

// ToServiceTripUpdateReq converts api.TripUpdateRequest to service.TripUpdateRequest
func ToServiceTripUpdateReq(req api.TripUpdateRequest) *service.TripUpdateRequest {
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

	return &service.TripUpdateRequest{
		Name:        req.Name,
		Description: req.Description,
		StartDate:   startDate,
		EndDate:     endDate,
		CoverImage:  req.CoverImage,
		IsActive:    req.IsActive,
		DayNames:    req.DayNames,
	}
}

// ToTripGetResponse converts model.Trip to api.TripGetResponse
func ToTripGetResponse(t model.Trip) api.TripGetResponse {
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
		UpdatedAt:   t.UpdatedAt,
	}
}

// ToTripCreateResponse converts model.Trip to api.TripCreateResponse
func ToTripCreateResponse(t model.Trip) api.TripCreateResponse {
	// TripCreateResponse is an alias for TripGetResponse
	return ToTripGetResponse(t)
}

// ToTripUpdateResponse converts model.Trip to api.TripUpdateResponse
func ToTripUpdateResponse(t model.Trip) api.TripUpdateResponse {
	// TripUpdateResponse is an alias for TripGetResponse
	return ToTripGetResponse(t)
}

// ToTripListItem converts model.Trip to api.TripListItemResponse
func ToTripListItem(t model.Trip) api.TripListItemResponse {
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
