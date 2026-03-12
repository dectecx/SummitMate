package model

import "time"

type PollOption struct {
	ID        string   `json:"id" db:"id"`
	PollID    string   `json:"poll_id" db:"poll_id"`
	Text      string   `json:"text" db:"text"`
	VoteCount int      `json:"vote_count" db:"-"`
	Voters    []string `json:"voters" db:"-"`
	CreatedAt time.Time `json:"created_at" db:"created_at"`
	CreatedBy string    `json:"created_by" db:"created_by"`
	UpdatedAt time.Time `json:"updated_at" db:"updated_at"`
	UpdatedBy string    `json:"updated_by" db:"updated_by"`
}

type Poll struct {
	ID                 string        `json:"id" db:"id"`
	TripID             string        `json:"trip_id" db:"trip_id"`
	Title              string        `json:"title" db:"title"`
	Description        *string       `json:"description" db:"description"`
	Deadline           *time.Time    `json:"deadline" db:"deadline"`
	IsAllowAddOption   bool          `json:"is_allow_add_option" db:"is_allow_add_option"`
	MaxOptionLimit     int           `json:"max_option_limit" db:"max_option_limit"`
	AllowMultipleVotes bool          `json:"allow_multiple_votes" db:"allow_multiple_votes"`
	ResultDisplayType  string        `json:"result_display_type" db:"result_display_type"`
	Status             string        `json:"status" db:"status"`
	Options            []*PollOption `json:"options" db:"-"`
	CreatedAt          time.Time     `json:"created_at" db:"created_at"`
	CreatedBy          string        `json:"created_by" db:"created_by"`
	UpdatedAt          time.Time     `json:"updated_at" db:"updated_at"`
	UpdatedBy          string        `json:"updated_by" db:"updated_by"`
}
