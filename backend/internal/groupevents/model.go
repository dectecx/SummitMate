// Package groupevents implements group events (揪團): online only, not part of sync.
package groupevents

import (
	"encoding/json"
	"time"

	"github.com/google/uuid"
)

// Event statuses.
const (
	StatusOpen      = "open"
	StatusClosed    = "closed"
	StatusCancelled = "cancelled"
)

// Application statuses.
const (
	AppPending   = "pending"
	AppApproved  = "approved"
	AppRejected  = "rejected"
	AppCancelled = "cancelled"
)

// List scopes.
const (
	ScopeAll      = "all"
	ScopeUpcoming = "upcoming"
	ScopePopular  = "popular"
	ScopeJoined   = "joined"
	ScopeHosting  = "hosting"
)

// Report target types.
const (
	TargetEvent   = "group_event"
	TargetComment = "group_event_comment"
)

// Event is a group event as stored, plus per-viewer fields filled by list/get queries.
type Event struct {
	ID               uuid.UUID
	HostID           uuid.UUID
	Title            string
	Description      string
	Category         string
	Location         string
	StartDate        time.Time // date at 00:00 UTC
	EndDate          *time.Time
	MaxMembers       int
	ApprovalRequired bool
	PrivateMessage   string // raw; the service blanks it for viewers without access
	Status           string
	LinkedTripID     *uuid.UUID
	TripSnapshot     json.RawMessage // normalized Snapshot JSON, nil when none
	SnapshotAt       *time.Time
	CreatedAt        time.Time

	HostName   string
	HostAvatar string

	ApprovedCount int
	PendingCount  int // applications waiting for review, host only
	CommentCount  int

	// Viewer specific.
	MyStatus    string // "" when the viewer never applied
	MyRejection string
	IsHost      bool

	// PrivateMessageVisible is decided by the service (host or approved applicant).
	PrivateMessageVisible bool
}

// Application is one user's application to an event.
type Application struct {
	ID              uuid.UUID
	EventID         uuid.UUID
	UserID          uuid.UUID
	UserName        string
	UserAvatar      string
	Status          string
	Message         string
	RejectionReason string
	CreatedAt       time.Time
}

// Comment is a public comment.
type Comment struct {
	ID         uuid.UUID
	EventID    uuid.UUID
	UserID     uuid.UUID
	UserName   string
	UserAvatar string
	Body       string
	CreatedAt  time.Time
	Mine       bool
}

// Report is a stored report.
type Report struct {
	ID         uuid.UUID
	ReporterID uuid.UUID
	TargetType string
	TargetID   uuid.UUID
	Reason     string
	CreatedAt  time.Time
}

// Snapshot is the display-only copy of a trip plan.
type Snapshot struct {
	Name      string         `json:"name"`
	StartDate *string        `json:"start_date"`
	EndDate   *string        `json:"end_date"`
	Itinerary []SnapshotNode `json:"itinerary"`
}

// SnapshotNode is one itinerary entry of a Snapshot.
type SnapshotNode struct {
	Day      int      `json:"day"`
	Name     string   `json:"name"`
	Time     *string  `json:"time"`
	Altitude int      `json:"altitude"`
	Lat      *float64 `json:"lat"`
	Lng      *float64 `json:"lng"`
}

// Opt marks a PATCH field as present (Set) with a possibly nil Value (explicit null).
type Opt[T any] struct {
	Set   bool
	Value T
}
