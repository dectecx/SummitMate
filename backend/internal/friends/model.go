// Package friends implements friendships with mutual consent: online only, not part of sync.
package friends

import (
	"time"

	"github.com/google/uuid"
)

// Friendship statuses. A declined or cancelled request deletes the row instead of getting a status.
const (
	StatusPending  = "pending"
	StatusAccepted = "accepted"
)

// Friendship is one row: a pair of users has at most one.
type Friendship struct {
	ID          uuid.UUID
	Requester   uuid.UUID
	Addressee   uuid.UUID
	Status      string
	CreatedAt   time.Time
	RespondedAt *time.Time
}

// Person is the public profile of the other side. Never carries an e-mail.
type Person struct {
	ID          uuid.UUID
	DisplayName string
	Avatar      string
}

// Friend is an accepted friendship seen from one user.
type Friend struct {
	Person
	Since time.Time
}

// Request is a pending request seen from one user; Person is the other side.
type Request struct {
	ID        uuid.UUID
	Person    Person
	CreatedAt time.Time
}

// Lists is everything the friends screen shows.
type Lists struct {
	Friends  []Friend
	Incoming []Request
	Outgoing []Request
}

// SendResult is the outcome of sending a request.
type SendResult struct {
	Status    string
	RequestID uuid.UUID
	Created   bool // false when nothing changed (HTTP 200)
}
