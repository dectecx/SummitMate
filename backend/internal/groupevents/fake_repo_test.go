package groupevents

import (
	"context"
	"sort"
	"sync"
	"time"

	"github.com/google/uuid"
)

// fakeRepo is an in-memory Repository. WithTx holds one mutex for the whole transaction,
// which stands in for the row lock of the real repository. Failed rules never write before they fail.
type fakeRepo struct {
	mu       sync.Mutex
	events   map[uuid.UUID]*Event
	apps     []*Application
	comments []*Comment
	deleted  map[uuid.UUID]bool
	likes    map[[2]uuid.UUID]bool
	reports  map[[3]string]Report
	owners   map[[2]uuid.UUID]bool // (trip, user) is an owner
	members  map[[2]uuid.UUID]bool // (trip, user) is an active member
	names    map[uuid.UUID]string
	clock    time.Time
}

func newFake() *fakeRepo {
	return &fakeRepo{
		events: map[uuid.UUID]*Event{}, deleted: map[uuid.UUID]bool{}, likes: map[[2]uuid.UUID]bool{},
		reports: map[[3]string]Report{}, owners: map[[2]uuid.UUID]bool{}, members: map[[2]uuid.UUID]bool{},
		names: map[uuid.UUID]string{}, clock: time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC),
	}
}

func (f *fakeRepo) tick() time.Time { f.clock = f.clock.Add(time.Second); return f.clock }

func (f *fakeRepo) WithTx(_ context.Context, fn func(Tx) error) error {
	f.mu.Lock()
	defer f.mu.Unlock()
	return fn(f)
}

func (f *fakeRepo) counts(e *Event) {
	e.ApprovedCount, e.LikeCount, e.CommentCount = 0, 0, 0
	for _, a := range f.apps {
		if a.EventID == e.ID && a.Status == AppApproved {
			e.ApprovedCount++
		}
	}
	for k, ok := range f.likes {
		if ok && k[0] == e.ID {
			e.LikeCount++
		}
	}
	for _, c := range f.comments {
		if c.EventID == e.ID && !f.deleted[c.ID] {
			e.CommentCount++
		}
	}
}

func (f *fakeRepo) view(e *Event, viewer *uuid.UUID) Event {
	out := *e
	f.counts(&out)
	out.HostName = f.names[e.HostID]
	if viewer != nil {
		out.Liked = f.likes[[2]uuid.UUID{e.ID, *viewer}]
		for _, a := range f.apps {
			if a.EventID == e.ID && a.UserID == *viewer {
				out.MyStatus, out.MyRejection = a.Status, a.RejectionReason
			}
		}
	}
	return out
}

func (f *fakeRepo) Get(_ context.Context, id uuid.UUID, viewer *uuid.UUID) (Event, error) {
	f.mu.Lock()
	defer f.mu.Unlock()
	e, ok := f.events[id]
	if !ok {
		return Event{}, ErrNotFound
	}
	return f.view(e, viewer), nil
}

func (f *fakeRepo) List(_ context.Context, q ListQuery) ([]Event, error) {
	f.mu.Lock()
	defer f.mu.Unlock()
	var out []Event
	for _, e := range f.events {
		v := f.view(e, q.Viewer)
		switch q.Scope {
		case ScopeAll, ScopePopular:
			if e.Status == StatusCancelled {
				continue
			}
		case ScopeUpcoming:
			if e.Status == StatusCancelled || e.StartDate.Before(q.Today) {
				continue
			}
		case ScopeJoined:
			if v.MyStatus != AppPending && v.MyStatus != AppApproved {
				continue
			}
		case ScopeHosting:
			if q.Viewer == nil || e.HostID != *q.Viewer {
				continue
			}
		}
		out = append(out, v)
	}
	sort.Slice(out, func(i, j int) bool { return out[i].CreatedAt.After(out[j].CreatedAt) })
	if q.Limit > 0 && len(out) > q.Limit {
		out = out[:q.Limit]
	}
	return out, nil
}

func (f *fakeRepo) ListApplications(_ context.Context, eventID uuid.UUID, statuses []string) ([]Application, error) {
	f.mu.Lock()
	defer f.mu.Unlock()
	var out []Application
	for _, a := range f.apps {
		for _, s := range statuses {
			if a.EventID == eventID && a.Status == s {
				out = append(out, *a)
			}
		}
	}
	return out, nil
}

func (f *fakeRepo) ListComments(_ context.Context, eventID uuid.UUID, limit int, after *Cursor) ([]Comment, error) {
	f.mu.Lock()
	defer f.mu.Unlock()
	var out []Comment
	for _, c := range f.comments {
		if c.EventID != eventID || f.deleted[c.ID] || (after != nil && !c.CreatedAt.After(after.Time)) {
			continue
		}
		out = append(out, *c)
		if len(out) == limit {
			break
		}
	}
	return out, nil
}

func (f *fakeRepo) GetComment(_ context.Context, id uuid.UUID) (Comment, error) {
	f.mu.Lock()
	defer f.mu.Unlock()
	for _, c := range f.comments {
		if c.ID == id && !f.deleted[id] {
			return *c, nil
		}
	}
	return Comment{}, ErrNotFound
}

func (f *fakeRepo) CreateComment(_ context.Context, c Comment) (Comment, error) {
	f.mu.Lock()
	defer f.mu.Unlock()
	c.CreatedAt, c.UserName = f.tick(), f.names[c.UserID]
	f.comments = append(f.comments, &c)
	return c, nil
}

func (f *fakeRepo) DeleteComment(_ context.Context, id uuid.UUID) error {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.deleted[id] = true
	return nil
}

func (f *fakeRepo) SetLike(_ context.Context, eventID, userID uuid.UUID, liked bool) (int, error) {
	f.mu.Lock()
	defer f.mu.Unlock()
	if liked {
		f.likes[[2]uuid.UUID{eventID, userID}] = true
	} else {
		delete(f.likes, [2]uuid.UUID{eventID, userID})
	}
	n := 0
	for k := range f.likes {
		if k[0] == eventID {
			n++
		}
	}
	return n, nil
}

func (f *fakeRepo) CreateReport(_ context.Context, r Report) (Report, bool, error) {
	f.mu.Lock()
	defer f.mu.Unlock()
	key := [3]string{r.ReporterID.String(), r.TargetType, r.TargetID.String()}
	if old, ok := f.reports[key]; ok {
		return old, false, nil
	}
	r.CreatedAt = f.tick()
	f.reports[key] = r
	return r, true, nil
}

// Tx methods (the caller already holds f.mu).

func (f *fakeRepo) LockEvent(_ context.Context, id uuid.UUID) (Event, error) {
	e, ok := f.events[id]
	if !ok {
		return Event{}, ErrNotFound
	}
	return *e, nil
}

func (f *fakeRepo) InsertEvent(_ context.Context, e Event) error {
	e.CreatedAt = f.tick()
	f.events[e.ID] = &e
	return nil
}

func (f *fakeRepo) SaveEvent(_ context.Context, e Event) error {
	old := f.events[e.ID]
	e.CreatedAt = old.CreatedAt
	f.events[e.ID] = &e
	return nil
}

func (f *fakeRepo) ApprovedCount(_ context.Context, eventID uuid.UUID) (int, error) {
	n := 0
	for _, a := range f.apps {
		if a.EventID == eventID && a.Status == AppApproved {
			n++
		}
	}
	return n, nil
}

func (f *fakeRepo) GetApplication(_ context.Context, eventID, userID uuid.UUID) (Application, error) {
	for _, a := range f.apps {
		if a.EventID == eventID && a.UserID == userID {
			return *a, nil
		}
	}
	return Application{}, ErrNotFound
}

func (f *fakeRepo) GetApplicationByID(_ context.Context, eventID, appID uuid.UUID) (Application, error) {
	for _, a := range f.apps {
		if a.EventID == eventID && a.ID == appID {
			return *a, nil
		}
	}
	return Application{}, ErrNotFound
}

func (f *fakeRepo) SaveApplication(_ context.Context, a Application) error {
	a.UserName, a.CreatedAt = f.names[a.UserID], f.tick()
	for _, old := range f.apps {
		if old.EventID == a.EventID && old.UserID == a.UserID {
			old.Status, old.Message, old.RejectionReason, old.CreatedAt = a.Status, a.Message, "", a.CreatedAt
			return nil
		}
	}
	f.apps = append(f.apps, &a)
	return nil
}

func (f *fakeRepo) SetApplicationStatus(_ context.Context, appID uuid.UUID, status, reason string) error {
	for _, a := range f.apps {
		if a.ID == appID {
			a.Status, a.RejectionReason = status, reason
		}
	}
	return nil
}

func (f *fakeRepo) IsTripOwner(_ context.Context, tripID, userID uuid.UUID) (bool, error) {
	return f.owners[[2]uuid.UUID{tripID, userID}], nil
}

func (f *fakeRepo) AddTripMember(_ context.Context, tripID, userID, _ uuid.UUID) error {
	f.members[[2]uuid.UUID{tripID, userID}] = true
	return nil
}

func (f *fakeRepo) RemoveTripMember(_ context.Context, tripID, userID, _ uuid.UUID) error {
	if !f.owners[[2]uuid.UUID{tripID, userID}] {
		delete(f.members, [2]uuid.UUID{tripID, userID})
	}
	return nil
}
