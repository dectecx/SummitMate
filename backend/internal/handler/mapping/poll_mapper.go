package mapping

import (
	"summitmate/api"
	"summitmate/internal/model"

	"github.com/google/uuid"
)

// ToPollOptionResponse converts model.PollOption to api.PollOption
func ToPollOptionResponse(opt *model.PollOption) api.PollOption {
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

// ToPollResponse converts model.Poll to api.Poll
func ToPollResponse(p *model.Poll) api.Poll {
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
