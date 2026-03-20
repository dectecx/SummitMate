package dto

import "time"

// PollOptionResponse is the API response DTO for poll options.
type PollOptionResponse struct {
	ID        string    `json:"id"`
	PollID    string    `json:"poll_id"`
	Text      string    `json:"text"`
	VoteCount int       `json:"vote_count"`
	Voters    []string  `json:"voters"`
	CreatedAt time.Time `json:"created_at"`
	CreatedBy string    `json:"created_by"`
	UpdatedAt time.Time `json:"updated_at"`
	UpdatedBy string    `json:"updated_by"`
}

// PollResponse is the API response DTO for polls.
type PollResponse struct {
	ID                 string               `json:"id"`
	TripID             string               `json:"trip_id"`
	Title              string               `json:"title"`
	Description        string               `json:"description"`
	Deadline           *time.Time           `json:"deadline,omitempty"`
	IsAllowAddOption   bool                 `json:"is_allow_add_option"`
	MaxOptionLimit     int                  `json:"max_option_limit"`
	AllowMultipleVotes bool                 `json:"allow_multiple_votes"`
	ResultDisplayType  string               `json:"result_display_type"`
	Status             string               `json:"status"`
	Options            []PollOptionResponse `json:"options"`
	CreatedAt          time.Time            `json:"created_at"`
	CreatedBy          string               `json:"created_by"`
	UpdatedAt          time.Time            `json:"updated_at"`
	UpdatedBy          string               `json:"updated_by"`
}
