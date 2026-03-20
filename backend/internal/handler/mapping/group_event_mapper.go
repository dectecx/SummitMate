package mapping

import (
	"summitmate/api"
	"summitmate/internal/model"

	"github.com/google/uuid"
	openapi_types "github.com/oapi-codegen/runtime/types"
)

// ToGroupEventResponse converts model.GroupEvent to api.GroupEvent
func ToGroupEventResponse(e *model.GroupEvent) api.GroupEvent {
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
	if e.PrivateMessage != "" {
		privateMsg = &e.PrivateMessage
	}

	return api.GroupEvent{
		Id:               uuid.MustParse(e.ID),
		Title:            e.Title,
		Description:      e.Description,
		Location:         e.Location,
		StartDate:        openapi_types.Date{Time: e.StartDate},
		EndDate:          endDate,
		Status:           api.GroupEventStatus(e.Status),
		MaxMembers:       e.MaxMembers,
		ApprovalRequired: e.ApprovalRequired,
		PrivateMessage:   privateMsg,
		LinkedTripId:     linkedTripID,
		LikeCount:        e.LikeCount,
		CommentCount:     e.CommentCount,
		CreatedAt:        e.CreatedAt,
		CreatedBy:        uuid.MustParse(e.CreatedBy),
		UpdatedAt:        e.UpdatedAt,
		UpdatedBy:        uuid.MustParse(e.UpdatedBy),
	}
}

// ToGroupEventApplicationResponse converts model.GroupEventApplication to api.GroupEventApplication
func ToGroupEventApplicationResponse(a *model.GroupEventApplication) api.GroupEventApplication {
	return api.GroupEventApplication{
		Id:        uuid.MustParse(a.ID),
		EventId:   uuid.MustParse(a.EventID),
		UserId:    uuid.MustParse(a.UserID),
		Status:    api.GroupEventApplicationStatus(a.Status),
		Message:   a.Message,
		CreatedAt: a.CreatedAt,
		CreatedBy: uuid.MustParse(a.CreatedBy),
		UpdatedAt: a.UpdatedAt,
		UpdatedBy: uuid.MustParse(a.UpdatedBy),
	}
}

// ToGroupEventCommentResponse converts model.GroupEventComment to api.GroupEventComment
func ToGroupEventCommentResponse(c *model.GroupEventComment) api.GroupEventComment {
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
