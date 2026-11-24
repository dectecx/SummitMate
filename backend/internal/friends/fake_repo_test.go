package friends

import (
	"context"
	"sync"
	"time"

	"github.com/google/uuid"
)

// fakeRepo is an in-memory Repository. WithTx holds one mutex for the whole transaction,
// which stands in for the pair lock of the real repository.
type fakeRepo struct {
	mu    sync.Mutex
	rows  map[uuid.UUID]*Friendship
	users map[uuid.UUID]*Person // available (active, verified) users
}

func newFake() *fakeRepo {
	return &fakeRepo{rows: map[uuid.UUID]*Friendship{}, users: map[uuid.UUID]*Person{}}
}

func (f *fakeRepo) WithTx(_ context.Context, fn func(Tx) error) error {
	f.mu.Lock()
	defer f.mu.Unlock()
	return fn(f)
}

func (f *fakeRepo) List(_ context.Context, user uuid.UUID) (Lists, error) {
	f.mu.Lock()
	defer f.mu.Unlock()
	out := Lists{Friends: []Friend{}, Incoming: []Request{}, Outgoing: []Request{}}
	for _, r := range f.rows {
		other := r.Addressee
		if other == user {
			other = r.Requester
		} else if r.Requester != user {
			continue
		}
		p, ok := f.users[other]
		if !ok {
			continue
		}
		switch {
		case r.Status == StatusAccepted:
			out.Friends = append(out.Friends, Friend{Person: *p, Since: *r.RespondedAt})
		case r.Requester == user:
			out.Outgoing = append(out.Outgoing, Request{ID: r.ID, Person: *p, CreatedAt: r.CreatedAt})
		default:
			out.Incoming = append(out.Incoming, Request{ID: r.ID, Person: *p, CreatedAt: r.CreatedAt})
		}
	}
	sortFriends(out.Friends)
	return out, nil
}

func (f *fakeRepo) LockPair(context.Context, uuid.UUID, uuid.UUID) error { return nil }

func (f *fakeRepo) UserAvailable(_ context.Context, id uuid.UUID) (bool, error) {
	_, ok := f.users[id]
	return ok, nil
}

func (f *fakeRepo) GetByPair(_ context.Context, a, b uuid.UUID) (Friendship, error) {
	for _, r := range f.rows {
		if (r.Requester == a && r.Addressee == b) || (r.Requester == b && r.Addressee == a) {
			return *r, nil
		}
	}
	return Friendship{}, ErrNotFound
}

func (f *fakeRepo) GetByID(_ context.Context, id uuid.UUID) (Friendship, error) {
	if r, ok := f.rows[id]; ok {
		return *r, nil
	}
	return Friendship{}, ErrNotFound
}

func (f *fakeRepo) CountPendingOutgoing(_ context.Context, user uuid.UUID) (int, error) {
	n := 0
	for _, r := range f.rows {
		if r.Requester == user && r.Status == StatusPending {
			n++
		}
	}
	return n, nil
}

func (f *fakeRepo) Insert(_ context.Context, r Friendship) error {
	f.rows[r.ID] = &r
	return nil
}

func (f *fakeRepo) Accept(_ context.Context, id uuid.UUID, at time.Time) error {
	r := f.rows[id]
	r.Status, r.RespondedAt = StatusAccepted, &at
	return nil
}

func (f *fakeRepo) Delete(_ context.Context, id uuid.UUID) error {
	delete(f.rows, id)
	return nil
}

func (f *fakeRepo) DeleteAccepted(_ context.Context, a, b uuid.UUID) error {
	for id, r := range f.rows {
		if r.Status == StatusAccepted && ((r.Requester == a && r.Addressee == b) || (r.Requester == b && r.Addressee == a)) {
			delete(f.rows, id)
		}
	}
	return nil
}
