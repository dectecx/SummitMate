package mapping

import (
	"summitmate/api"
	"summitmate/internal/model"

	"github.com/google/uuid"
)

// ToMessageResponse converts model.TripMessage to api.Message (recursive for replies)
func ToMessageResponse(m *model.TripMessage) api.Message {
	var parentID *uuid.UUID
	if m.ParentID != nil {
		parsed := uuid.MustParse(*m.ParentID)
		parentID = &parsed
	}

	var avatar *string
	if m.Avatar != "" {
		avatar = &m.Avatar
	}

	var replies *[]api.Message
	if len(m.Replies) > 0 {
		r := make([]api.Message, len(m.Replies))
		for i, rp := range m.Replies {
			r[i] = ToMessageResponse(rp)
		}
		replies = &r
	} else {
		empty := []api.Message{}
		replies = &empty
	}

	return api.Message{
		Id:          uuid.MustParse(m.ID),
		TripId:      uuid.MustParse(m.TripID),
		ParentId:    parentID,
		UserId:      uuid.MustParse(m.UserID),
		DisplayName: m.DisplayName,
		Avatar:      avatar,
		Category:    m.Category,
		Content:     m.Content,
		Timestamp:   m.Timestamp,
		Replies:     replies,
		CreatedAt:   m.CreatedAt,
		UpdatedAt:   &m.UpdatedAt,
	}
}
