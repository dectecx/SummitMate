package interaction

import (
	"summitmate/api"

	"github.com/google/uuid"
)

// ToMessageResponse converts TripMessage to api.Message (recursive for replies)
func ToMessageResponse(m *TripMessage) api.Message {
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

// ToPollOptionResponse converts PollOption to api.PollOption
func ToPollOptionResponse(opt *PollOption) api.PollOption {
	var voters *[]uuid.UUID
	if len(opt.Voters) > 0 {
		voterUUIDs := make([]uuid.UUID, len(opt.Voters))
		for i, v := range opt.Voters {
			voterUUIDs[i] = uuid.MustParse(v)
		}
		voters = &voterUUIDs
	}

	return api.PollOption{
		Id:        uuid.MustParse(opt.ID),
		PollId:    uuid.MustParse(opt.PollID),
		Text:      opt.Text,
		VoteCount: opt.VoteCount,
		Voters:    voters,
		CreatedAt: opt.CreatedAt,
		CreatedBy: uuid.MustParse(opt.CreatedBy),
		UpdatedAt: opt.UpdatedAt,
		UpdatedBy: uuid.MustParse(opt.UpdatedBy),
	}
}

// ToPollResponse converts Poll to api.Poll
func ToPollResponse(p *Poll) api.Poll {
	options := make([]api.PollOption, len(p.Options))
	for i, opt := range p.Options {
		options[i] = ToPollOptionResponse(opt)
	}

	return api.Poll{
		Id:                 uuid.MustParse(p.ID),
		TripId:             uuid.MustParse(p.TripID),
		Title:              p.Title,
		Description:        p.Description,
		Deadline:           p.Deadline,
		IsAllowAddOption:   p.IsAllowAddOption,
		MaxOptionLimit:     p.MaxOptionLimit,
		AllowMultipleVotes: p.AllowMultipleVotes,
		ResultDisplayType:  p.ResultDisplayType,
		Status:             p.Status,
		Options:            options,
		CreatedAt:          p.CreatedAt,
		CreatedBy:          uuid.MustParse(p.CreatedBy),
		UpdatedAt:          p.UpdatedAt,
		UpdatedBy:          uuid.MustParse(p.UpdatedBy),
	}
}
