package mapping

import (
	"summitmate/api"
	"summitmate/internal/model"
	"summitmate/internal/service"

	"github.com/google/uuid"
)

// ToServiceItineraryItemReq converts api.ItineraryItemRequest to service.ItineraryItemRequest
func ToServiceItineraryItemReq(req api.ItineraryItemRequest) service.ItineraryItemRequest {
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

	return service.ItineraryItemRequest{
		Day:        req.Day,
		Name:       req.Name,
		EstTime:    req.EstTime,
		Altitude:   altitude,
		Distance:   distance,
		Note:       note,
		ImageAsset: req.ImageAsset,
	}
}

// ToItineraryItemGetResponse converts model.ItineraryItem to api.ItineraryItemGetResponse
func ToItineraryItemGetResponse(item *model.ItineraryItem) api.ItineraryItemGetResponse {
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

// ToItineraryItemCreateResponse converts model.ItineraryItem to api.ItineraryItemCreateResponse
func ToItineraryItemCreateResponse(item *model.ItineraryItem) api.ItineraryItemCreateResponse {
	return api.ItineraryItemCreateResponse(ToItineraryItemGetResponse(item))
}

// ToItineraryItemUpdateResponse converts model.ItineraryItem to api.ItineraryItemUpdateResponse
func ToItineraryItemUpdateResponse(item *model.ItineraryItem) api.ItineraryItemUpdateResponse {
	return api.ItineraryItemUpdateResponse(ToItineraryItemGetResponse(item))
}

// ToItineraryItemListItemResponse converts model.ItineraryItem to api.ItineraryItemListItemResponse
func ToItineraryItemListItemResponse(item *model.ItineraryItem) api.ItineraryItemListItemResponse {
	return api.ItineraryItemListItemResponse(ToItineraryItemGetResponse(item))
}
