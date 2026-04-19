package mapping

import (
	"summitmate/api"
	"summitmate/internal/trip"

	"github.com/google/uuid"
	openapi_types "github.com/oapi-codegen/runtime/types"
)

// ToTripMemberGetResponse converts trip.TripMember to api.TripMemberGetResponse
func ToTripMemberGetResponse(m *trip.TripMember) api.TripMemberGetResponse {
	apiUser := api.User{
		Id:          uuid.MustParse(m.UserID),
		Email:       openapi_types.Email(m.UserEmail),
		DisplayName: m.UserDisplayName,
		Avatar:      m.UserAvatar,
		CreatedAt:   m.JoinedAt, // TripMember model lacks users.created_at, substituting JoinedAt for standard compliance
	}

	return api.TripMemberGetResponse{
		TripId:       uuid.MustParse(m.TripID),
		UserId:       uuid.MustParse(m.UserID),
		JoinedAt:     m.JoinedAt,
		UserMetadata: apiUser,
	}
}

// ToTripMemberListItemResponse converts trip.TripMember to api.TripMemberListItemResponse
func ToTripMemberListItemResponse(m *trip.TripMember) api.TripMemberListItemResponse {
	return api.TripMemberListItemResponse(ToTripMemberGetResponse(m))
}
