package groupevent

import (
	"summitmate/api"

	"github.com/google/uuid"
	openapi_types "github.com/oapi-codegen/runtime/types"
)

// ToGroupEventResponse converts GroupEvent to api.GroupEvent
func ToGroupEventResponse(e *GroupEvent, requesterID string) api.GroupEvent {
	var endDate *openapi_types.Date
	if e.EndDate != nil {
		d := openapi_types.Date{Time: *e.EndDate}
		endDate = &d
	}

	var linkedTripID *uuid.UUID
	if e.LinkedTripID != nil {
		parsed := uuid.MustParse(*e.LinkedTripID)
		linkedTripID = &parsed
	}

	var privateMsg *string
	isApproved := e.MyApplicationStatus != nil && *e.MyApplicationStatus == ApplicationStatusApproved
	isHost := e.HostID == requesterID

	if (isApproved || isHost) && e.PrivateMessage != "" {
		privateMsg = &e.PrivateMessage
	}

	var snapshot *api.TripSnapshot
	if e.TripSnapshot != nil {
		snapshot = &api.TripSnapshot{
			Name:      e.TripSnapshot.Name,
			StartDate: e.TripSnapshot.StartDate,
			EndDate:   e.TripSnapshot.EndDate,
			Itinerary: e.TripSnapshot.Itinerary,
		}
	}

	var myAppID *uuid.UUID
	if e.MyApplicationID != nil {
		id := uuid.MustParse(*e.MyApplicationID)
		myAppID = &id
	}

	return api.GroupEvent{
		Id:                  uuid.MustParse(e.ID),
		HostId:              uuid.MustParse(e.HostID),
		HostName:            e.HostName,
		HostAvatar:          e.HostAvatar,
		Title:               e.Title,
		Description:         e.Description,
		Category:            string(e.Category),
		Location:            e.Location,
		StartDate:           openapi_types.Date{Time: e.StartDate},
		EndDate:             endDate,
		Status:              api.GroupEventStatus(e.Status),
		MaxMembers:          e.MaxMembers,
		ApprovalRequired:    e.ApprovalRequired,
		PrivateMessage:      privateMsg,
		LinkedTripId:        linkedTripID,
		TripSnapshot:        snapshot,
		SnapshotUpdatedAt:   e.SnapshotUpdatedAt,
		LikeCount:           e.LikeCount,
		CommentCount:        e.CommentCount,
		ApplicationCount:    &e.ApplicationCount,
		IsLiked:             &e.IsLiked,
		MyApplicationId:     myAppID,
		MyApplicationStatus: (*api.GroupEventMyApplicationStatus)(e.MyApplicationStatus),
		MyApplicationReason: e.MyApplicationReason,
		CreatedAt:           e.CreatedAt,
		CreatedBy:           uuid.MustParse(e.CreatedBy),
		UpdatedAt:           e.UpdatedAt,
		UpdatedBy:           uuid.MustParse(e.UpdatedBy),
	}
}

// ToGroupEventApplicationResponse converts GroupEventApplication to api.GroupEventApplication
func ToGroupEventApplicationResponse(a *GroupEventApplication) api.GroupEventApplication {
	return api.GroupEventApplication{
		Id:         uuid.MustParse(a.ID),
		EventId:    uuid.MustParse(a.EventID),
		UserId:     uuid.MustParse(a.UserID),
		UserName:   a.UserName,
		UserAvatar: a.UserAvatar,
		Status:          api.GroupEventApplicationStatus(a.Status),
		Message:         a.Message,
		RejectionReason: &a.RejectionReason,
		CreatedAt:       a.CreatedAt,
		CreatedBy:       uuid.MustParse(a.CreatedBy),
		UpdatedAt:       a.UpdatedAt,
		UpdatedBy:       uuid.MustParse(a.UpdatedBy),
	}
}

// ToGroupEventCommentResponse converts GroupEventComment to api.GroupEventComment
func ToGroupEventCommentResponse(c *GroupEventComment) api.GroupEventComment {
	var displayName *string
	if c.DisplayName != "" {
		displayName = &c.DisplayName
	}
	var avatar *string
	if c.Avatar != "" {
		avatar = &c.Avatar
	}

	return api.GroupEventComment{
		Id:          uuid.MustParse(c.ID),
		EventId:     uuid.MustParse(c.EventID),
		UserId:      uuid.MustParse(c.UserID),
		Content:     c.Content,
		DisplayName: displayName,
		Avatar:      avatar,
		CreatedAt:   c.CreatedAt,
		CreatedBy:   uuid.MustParse(c.CreatedBy),
		UpdatedAt:   c.UpdatedAt,
		UpdatedBy:   uuid.MustParse(c.UpdatedBy),
	}
}
