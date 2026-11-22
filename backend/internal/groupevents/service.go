package groupevents

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"

	"summitmate/internal/platform/apperror"
	"summitmate/internal/platform/ratelimit"
)

// Limits.
const (
	DefaultLimit   = 20
	MaxLimit       = 50
	MaxQueryRunes  = 100
	minTitleRunes  = 5
	maxTitleRunes  = 200
	maxLocation    = 200
	maxDescription = 4000
	maxPrivateMsg  = 2000
	maxApplyMsg    = 500
	maxReason      = 500
	maxComment     = 1000
	minMembers     = 2
	maxMembers     = 100
)

var (
	errNotFound        = apperror.New(http.StatusNotFound, apperror.TypeBusinessLogic, "group_event_not_found", "找不到這個揪團")
	errAppNotFound     = apperror.New(http.StatusNotFound, apperror.TypeBusinessLogic, "application_not_found", "找不到這筆申請")
	errCommentNotFound = apperror.New(http.StatusNotFound, apperror.TypeBusinessLogic, "comment_not_found", "找不到這則留言")
	errForbidden       = apperror.New(http.StatusForbidden, apperror.TypeAuth, "forbidden", "沒有權限執行這個操作")
	errNotTripOwner    = apperror.New(http.StatusForbidden, apperror.TypeBusinessLogic, "not_trip_owner", "只能連結自己擔任團長的行程").WithParam("linked_trip_id")
	errHostApply       = apperror.New(http.StatusConflict, apperror.TypeBusinessLogic, "host_cannot_apply", "主辦人不能申請自己的揪團")
	errAlreadyApplied  = apperror.New(http.StatusConflict, apperror.TypeBusinessLogic, "already_applied", "你已經申請過了")
	errClosed          = apperror.New(http.StatusConflict, apperror.TypeBusinessLogic, "registration_closed", "這個揪團已停止報名")
	errFull            = apperror.New(http.StatusConflict, apperror.TypeBusinessLogic, "event_full", "人數已滿")
	errInvalidReview   = apperror.New(http.StatusConflict, apperror.TypeBusinessLogic, "invalid_review", "這筆申請目前不能執行此操作")
	errEventCancelled  = apperror.New(http.StatusConflict, apperror.TypeBusinessLogic, "event_cancelled", "揪團已取消，不能再編輯")
	errSnapshot        = apperror.New(http.StatusBadRequest, apperror.TypeValidation, "invalid_snapshot", "行程快照格式不正確").WithParam("trip_snapshot")

	errTitle       = apperror.New(http.StatusBadRequest, apperror.TypeValidation, "invalid_title", "標題長度必須介於 5 到 200 字").WithParam("title")
	errCategory    = apperror.New(http.StatusBadRequest, apperror.TypeValidation, "invalid_category", "分類必須是 hiking、camping、bouldering 或 other").WithParam("category")
	errLocation    = apperror.New(http.StatusBadRequest, apperror.TypeValidation, "invalid_location", "地點不可超過 200 字").WithParam("location")
	errDates       = apperror.New(http.StatusBadRequest, apperror.TypeValidation, "invalid_dates", "結束日期不可早於開始日期").WithParam("end_date")
	errMaxMembers  = apperror.New(http.StatusBadRequest, apperror.TypeValidation, "invalid_max_members", "人數上限必須介於 2 到 100").WithParam("max_members")
	errMaxBelow    = apperror.New(http.StatusBadRequest, apperror.TypeValidation, "invalid_max_members", "人數上限不可小於目前已通過的人數").WithParam("max_members")
	errDescription = apperror.New(http.StatusBadRequest, apperror.TypeValidation, "invalid_description", "說明不可超過 4000 字").WithParam("description")
	errPrivateMsg  = apperror.New(http.StatusBadRequest, apperror.TypeValidation, "invalid_private_message", "隊員私密留言不可超過 2000 字").WithParam("private_message")
	errApplyMsg    = apperror.New(http.StatusBadRequest, apperror.TypeValidation, "invalid_message", "報名訊息不可超過 500 字").WithParam("message")
	errReason      = apperror.New(http.StatusBadRequest, apperror.TypeValidation, "invalid_reason", "原因長度必須介於 1 到 500 字").WithParam("reason")
	errRejectLong  = apperror.New(http.StatusBadRequest, apperror.TypeValidation, "invalid_reason", "拒絕原因不可超過 500 字").WithParam("reason")
	errComment     = apperror.New(http.StatusBadRequest, apperror.TypeValidation, "invalid_comment", "留言長度必須介於 1 到 1000 字").WithParam("body")
	errStatus      = apperror.New(http.StatusBadRequest, apperror.TypeValidation, "invalid_status", "狀態不正確").WithParam("status")
	errScope       = apperror.New(http.StatusBadRequest, apperror.TypeValidation, "invalid_scope", "scope 必須是 all、upcoming、popular、joined 或 hosting").WithParam("scope")
	errLimit       = apperror.New(http.StatusBadRequest, apperror.TypeValidation, "invalid_limit", "limit 必須介於 1 到 50").WithParam("limit")
	errCursor      = apperror.New(http.StatusBadRequest, apperror.TypeValidation, "invalid_cursor", "cursor 不正確").WithParam("cursor")
	errQuery       = apperror.New(http.StatusBadRequest, apperror.TypeValidation, "invalid_query", "搜尋字串不可超過 100 字").WithParam("q")
	errTargetType  = apperror.New(http.StatusBadRequest, apperror.TypeValidation, "invalid_target_type", "舉報對象必須是 group_event 或 group_event_comment").WithParam("target_type")
)

// Options configures a Service. Nil limiters get defaults.
type Options struct {
	Comments     ratelimit.Limiter // per user
	Applications ratelimit.Limiter // per user
	Now          func() time.Time
}

// Service holds the business rules.
type Service struct {
	repo  Repository
	opts  Options
	newID func() uuid.UUID
}

func NewService(repo Repository, o Options) *Service {
	if o.Comments == nil {
		o.Comments = ratelimit.NewMemory(20, time.Minute)
	}
	if o.Applications == nil {
		o.Applications = ratelimit.NewMemory(20, 10*time.Minute)
	}
	if o.Now == nil {
		o.Now = time.Now
	}
	return &Service{repo: repo, opts: o, newID: uuid.New}
}

// taipei is the calendar used for "today" (Taiwan app, no tzdata dependency).
var taipei = time.FixedZone("UTC+8", 8*3600)

// today returns the current date in Taiwan as a date at 00:00 UTC.
func (s *Service) today() time.Time {
	n := s.opts.Now().In(taipei)
	return time.Date(n.Year(), n.Month(), n.Day(), 0, 0, 0, 0, time.UTC)
}

func parseDate(v string) (time.Time, error) { return time.Parse("2006-01-02", v) }

func dateOnly(t time.Time) time.Time {
	return time.Date(t.Year(), t.Month(), t.Day(), 0, 0, 0, 0, time.UTC)
}

func runes(s string) int { return utf8.RuneCountInString(s) }

func validCategory(c string) bool {
	switch c {
	case "hiking", "camping", "bouldering", "other":
		return true
	}
	return false
}

// canSee reports whether viewer may read the event at all (cancelled events are limited).
func canSee(e Event, viewer *uuid.UUID) bool {
	if e.Status != StatusCancelled {
		return true
	}
	return viewer != nil && (*viewer == e.HostID || e.MyStatus != "")
}

// finish fills the per-viewer fields and hides what the viewer may not read.
func finish(e Event, viewer *uuid.UUID) Event {
	e.IsHost = viewer != nil && *viewer == e.HostID
	e.PrivateMessageVisible = e.IsHost || e.MyStatus == AppApproved
	if !e.PrivateMessageVisible {
		e.PrivateMessage = ""
	}
	if !e.IsHost {
		e.LinkedTripID = nil
	}
	if e.MyStatus != AppRejected {
		e.MyRejection = ""
	}
	return e
}

// CreateInput is a create request.
type CreateInput struct {
	Title            string
	Category         string
	Location         string
	StartDate        time.Time
	EndDate          *time.Time
	MaxMembers       int
	ApprovalRequired bool
	Description      string
	PrivateMessage   string
	LinkedTripID     *uuid.UUID
	TripSnapshot     *Snapshot
}

func checkTitle(t string) (string, error) {
	t = strings.TrimSpace(t)
	if n := runes(t); n < minTitleRunes || n > maxTitleRunes {
		return "", errTitle
	}
	return t, nil
}

func checkMax(n int) error {
	if n < minMembers || n > maxMembers {
		return errMaxMembers
	}
	return nil
}

// Create validates and stores a new event hosted by host.
func (s *Service) Create(ctx context.Context, host uuid.UUID, in CreateInput) (Event, error) {
	title, err := checkTitle(in.Title)
	if err != nil {
		return Event{}, err
	}
	if !validCategory(in.Category) {
		return Event{}, errCategory
	}
	loc := strings.TrimSpace(in.Location)
	if runes(loc) > maxLocation {
		return Event{}, errLocation
	}
	start := dateOnly(in.StartDate)
	var end *time.Time
	if in.EndDate != nil {
		e := dateOnly(*in.EndDate)
		if e.Before(start) {
			return Event{}, errDates
		}
		end = &e
	}
	if err := checkMax(in.MaxMembers); err != nil {
		return Event{}, err
	}
	if runes(in.Description) > maxDescription {
		return Event{}, errDescription
	}
	if runes(in.PrivateMessage) > maxPrivateMsg {
		return Event{}, errPrivateMsg
	}
	ev := Event{
		ID: s.newID(), HostID: host, Title: title, Description: in.Description, Category: in.Category, Location: loc,
		StartDate: start, EndDate: end, MaxMembers: in.MaxMembers, ApprovalRequired: in.ApprovalRequired,
		PrivateMessage: in.PrivateMessage, Status: StatusOpen, LinkedTripID: in.LinkedTripID,
	}
	if in.TripSnapshot != nil {
		raw, err := normalizeSnapshot(in.TripSnapshot)
		if err != nil {
			return Event{}, err
		}
		now := s.opts.Now()
		ev.TripSnapshot, ev.SnapshotAt = raw, &now
	}
	err = s.repo.WithTx(ctx, func(tx Tx) error {
		if in.LinkedTripID != nil {
			ok, err := tx.IsTripOwner(ctx, *in.LinkedTripID, host)
			if err != nil {
				return err
			}
			if !ok {
				return errNotTripOwner
			}
		}
		return tx.InsertEvent(ctx, ev)
	})
	if err != nil {
		return Event{}, err
	}
	return s.Get(ctx, &host, ev.ID)
}

// Get returns the event as the viewer (nil = anonymous) may see it.
func (s *Service) Get(ctx context.Context, viewer *uuid.UUID, id uuid.UUID) (Event, error) {
	e, err := s.repo.Get(ctx, id, viewer)
	if errors.Is(err, ErrNotFound) {
		return Event{}, errNotFound
	}
	if err != nil {
		return Event{}, err
	}
	if !canSee(e, viewer) {
		return Event{}, errNotFound
	}
	return finish(e, viewer), nil
}

// UpdateInput is a PATCH request: nil pointers and unset Opt fields are left unchanged.
type UpdateInput struct {
	Title            *string
	Category         *string
	Location         *string
	StartDate        *time.Time
	EndDate          Opt[*time.Time]
	MaxMembers       *int
	ApprovalRequired *bool
	Description      *string
	PrivateMessage   *string
	Status           *string
	LinkedTripID     Opt[*uuid.UUID]
	TripSnapshot     Opt[*Snapshot]
}

// loadForUser locks the event row and applies the visibility rule; user is never nil here.
func (s *Service) loadForUser(ctx context.Context, tx Tx, id, user uuid.UUID) (Event, *Application, error) {
	e, err := tx.LockEvent(ctx, id)
	if errors.Is(err, ErrNotFound) {
		return Event{}, nil, errNotFound
	}
	if err != nil {
		return Event{}, nil, err
	}
	app, err := tx.GetApplication(ctx, id, user)
	if err != nil && !errors.Is(err, ErrNotFound) {
		return Event{}, nil, err
	}
	var pa *Application
	if err == nil {
		pa = &app
		e.MyStatus = app.Status
	}
	if !canSee(e, &user) {
		return Event{}, nil, errNotFound
	}
	return e, pa, nil
}

// Update edits an event hosted by user.
func (s *Service) Update(ctx context.Context, user, id uuid.UUID, in UpdateInput) (Event, error) {
	err := s.repo.WithTx(ctx, func(tx Tx) error {
		e, _, err := s.loadForUser(ctx, tx, id, user)
		if err != nil {
			return err
		}
		if e.HostID != user {
			return errForbidden
		}
		if e.Status == StatusCancelled {
			return errEventCancelled
		}
		if in.Title != nil {
			if e.Title, err = checkTitle(*in.Title); err != nil {
				return err
			}
		}
		if in.Category != nil {
			if !validCategory(*in.Category) {
				return errCategory
			}
			e.Category = *in.Category
		}
		if in.Location != nil {
			e.Location = strings.TrimSpace(*in.Location)
			if runes(e.Location) > maxLocation {
				return errLocation
			}
		}
		if in.StartDate != nil {
			e.StartDate = dateOnly(*in.StartDate)
		}
		if in.EndDate.Set {
			e.EndDate = nil
			if in.EndDate.Value != nil {
				d := dateOnly(*in.EndDate.Value)
				e.EndDate = &d
			}
		}
		if e.EndDate != nil && e.EndDate.Before(e.StartDate) {
			return errDates
		}
		if in.MaxMembers != nil {
			if err := checkMax(*in.MaxMembers); err != nil {
				return err
			}
			n, err := tx.ApprovedCount(ctx, id)
			if err != nil {
				return err
			}
			if *in.MaxMembers < n {
				return errMaxBelow
			}
			e.MaxMembers = *in.MaxMembers
		}
		if in.ApprovalRequired != nil {
			e.ApprovalRequired = *in.ApprovalRequired
		}
		if in.Description != nil {
			if runes(*in.Description) > maxDescription {
				return errDescription
			}
			e.Description = *in.Description
		}
		if in.PrivateMessage != nil {
			if runes(*in.PrivateMessage) > maxPrivateMsg {
				return errPrivateMsg
			}
			e.PrivateMessage = *in.PrivateMessage
		}
		if in.Status != nil {
			if *in.Status != StatusOpen && *in.Status != StatusClosed {
				return errStatus
			}
			e.Status = *in.Status
		}
		if in.LinkedTripID.Set {
			v := in.LinkedTripID.Value
			changed := v != nil && (e.LinkedTripID == nil || *e.LinkedTripID != *v)
			if changed {
				ok, err := tx.IsTripOwner(ctx, *v, user)
				if err != nil {
					return err
				}
				if !ok {
					return errNotTripOwner
				}
			}
			e.LinkedTripID = v
		}
		if in.TripSnapshot.Set {
			if in.TripSnapshot.Value == nil {
				e.TripSnapshot, e.SnapshotAt = nil, nil
			} else {
				raw, err := normalizeSnapshot(in.TripSnapshot.Value)
				if err != nil {
					return err
				}
				now := s.opts.Now()
				e.TripSnapshot, e.SnapshotAt = raw, &now
			}
		}
		return tx.SaveEvent(ctx, e)
	})
	if err != nil {
		return Event{}, err
	}
	return s.Get(ctx, &user, id)
}

// Cancel marks the event cancelled (idempotent). Trip members are left alone.
func (s *Service) Cancel(ctx context.Context, user, id uuid.UUID) error {
	return s.repo.WithTx(ctx, func(tx Tx) error {
		e, _, err := s.loadForUser(ctx, tx, id, user)
		if err != nil {
			return err
		}
		if e.HostID != user {
			return errForbidden
		}
		if e.Status == StatusCancelled {
			return nil
		}
		e.Status = StatusCancelled
		return tx.SaveEvent(ctx, e)
	})
}

func (s *Service) allow(l ratelimit.Limiter, user uuid.UUID) error {
	key := user.String()
	if !l.Allow(key) {
		return apperror.ErrTooManyRequests
	}
	l.Record(key)
	return nil
}

// Apply applies to join and returns the resulting application status.
func (s *Service) Apply(ctx context.Context, user, id uuid.UUID, message string) (string, error) {
	message = strings.TrimSpace(message)
	if runes(message) > maxApplyMsg {
		return "", errApplyMsg
	}
	if err := s.allow(s.opts.Applications, user); err != nil {
		return "", err
	}
	var result string
	err := s.repo.WithTx(ctx, func(tx Tx) error {
		e, app, err := s.loadForUser(ctx, tx, id, user)
		if err != nil {
			return err
		}
		if e.HostID == user {
			return errHostApply
		}
		if app != nil && (app.Status == AppPending || app.Status == AppApproved) {
			return errAlreadyApplied
		}
		if e.Status != StatusOpen || e.StartDate.Before(s.today()) {
			return errClosed
		}
		status := AppPending
		if !e.ApprovalRequired {
			n, err := tx.ApprovedCount(ctx, id)
			if err != nil {
				return err
			}
			if n >= e.MaxMembers {
				return errFull
			}
			status = AppApproved
		}
		if err := tx.SaveApplication(ctx, Application{
			ID: s.newID(), EventID: id, UserID: user, Status: status, Message: message,
		}); err != nil {
			return err
		}
		if status == AppApproved && e.LinkedTripID != nil {
			if err := tx.AddTripMember(ctx, *e.LinkedTripID, user, e.HostID); err != nil {
				return err
			}
		}
		result = status
		return nil
	})
	return result, err
}

// Withdraw cancels the caller's pending or approved application.
func (s *Service) Withdraw(ctx context.Context, user, id uuid.UUID) error {
	return s.repo.WithTx(ctx, func(tx Tx) error {
		e, app, err := s.loadForUser(ctx, tx, id, user)
		if err != nil {
			return err
		}
		if app == nil || (app.Status != AppPending && app.Status != AppApproved) {
			return errAppNotFound
		}
		if err := tx.SetApplicationStatus(ctx, app.ID, AppCancelled, ""); err != nil {
			return err
		}
		if app.Status == AppApproved && e.LinkedTripID != nil {
			return tx.RemoveTripMember(ctx, *e.LinkedTripID, user, e.HostID)
		}
		return nil
	})
}

// hostEvent loads a visible event and requires user to be its host.
func (s *Service) hostEvent(ctx context.Context, user, id uuid.UUID) (Event, error) {
	e, err := s.Get(ctx, &user, id)
	if err != nil {
		return Event{}, err
	}
	if !e.IsHost {
		return Event{}, errForbidden
	}
	return e, nil
}

// ListApplications returns the applications of a hosted event, oldest first.
// status "" means pending and approved.
func (s *Service) ListApplications(ctx context.Context, user, id uuid.UUID, status string) ([]Application, error) {
	statuses := []string{AppPending, AppApproved}
	if status != "" {
		switch status {
		case AppPending, AppApproved, AppRejected, AppCancelled:
			statuses = []string{status}
		default:
			return nil, errStatus
		}
	}
	if _, err := s.hostEvent(ctx, user, id); err != nil {
		return nil, err
	}
	return s.repo.ListApplications(ctx, id, statuses)
}

// Review approves or rejects a pending application.
func (s *Service) Review(ctx context.Context, user, id, appID uuid.UUID, approve bool, reason string) (Application, error) {
	reason = strings.TrimSpace(reason)
	if runes(reason) > maxReason {
		return Application{}, errRejectLong
	}
	var out Application
	err := s.repo.WithTx(ctx, func(tx Tx) error {
		e, _, err := s.loadForUser(ctx, tx, id, user)
		if err != nil {
			return err
		}
		if e.HostID != user {
			return errForbidden
		}
		app, err := tx.GetApplicationByID(ctx, id, appID)
		if errors.Is(err, ErrNotFound) {
			return errAppNotFound
		}
		if err != nil {
			return err
		}
		if app.Status != AppPending || e.Status == StatusCancelled {
			return errInvalidReview
		}
		if approve {
			n, err := tx.ApprovedCount(ctx, id)
			if err != nil {
				return err
			}
			if n >= e.MaxMembers {
				return errFull
			}
			app.Status, app.RejectionReason = AppApproved, ""
		} else {
			app.Status, app.RejectionReason = AppRejected, reason
		}
		if err := tx.SetApplicationStatus(ctx, app.ID, app.Status, app.RejectionReason); err != nil {
			return err
		}
		if approve && e.LinkedTripID != nil {
			if err := tx.AddTripMember(ctx, *e.LinkedTripID, app.UserID, e.HostID); err != nil {
				return err
			}
		}
		out = app
		return nil
	})
	return out, err
}

// RemoveMember removes an approved member (status becomes cancelled).
func (s *Service) RemoveMember(ctx context.Context, user, id, appID uuid.UUID) error {
	return s.repo.WithTx(ctx, func(tx Tx) error {
		e, _, err := s.loadForUser(ctx, tx, id, user)
		if err != nil {
			return err
		}
		if e.HostID != user {
			return errForbidden
		}
		app, err := tx.GetApplicationByID(ctx, id, appID)
		if errors.Is(err, ErrNotFound) {
			return errAppNotFound
		}
		if err != nil {
			return err
		}
		if app.Status != AppApproved {
			return errInvalidReview
		}
		if err := tx.SetApplicationStatus(ctx, app.ID, AppCancelled, ""); err != nil {
			return err
		}
		if e.LinkedTripID != nil {
			return tx.RemoveTripMember(ctx, *e.LinkedTripID, app.UserID, e.HostID)
		}
		return nil
	})
}

// ListInput selects a page of events.
type ListInput struct {
	Scope  string
	Q      string
	Limit  int // 0 = default
	Cursor string
}

// ListQuery is what the repository executes.
type ListQuery struct {
	Scope  string
	Viewer *uuid.UUID
	Q      string // unescaped substring
	Limit  int
	Today  time.Time
	After  *Cursor // keyset scopes
	Offset int     // popular
}

// Page is one page of events.
type Page struct {
	Events     []Event
	NextCursor string
}

// List returns summaries. joined and hosting need a viewer.
func (s *Service) List(ctx context.Context, viewer *uuid.UUID, in ListInput) (Page, error) {
	scope := in.Scope
	if scope == "" {
		scope = ScopeAll
	}
	switch scope {
	case ScopeAll, ScopeUpcoming, ScopePopular:
	case ScopeJoined, ScopeHosting:
		if viewer == nil {
			return Page{}, apperror.ErrUnauthorized
		}
	default:
		return Page{}, errScope
	}
	q := ListQuery{Scope: scope, Viewer: viewer, Q: strings.TrimSpace(in.Q), Limit: in.Limit, Today: s.today()}
	if q.Limit == 0 {
		q.Limit = DefaultLimit
	}
	if q.Limit < 1 || q.Limit > MaxLimit {
		return Page{}, errLimit
	}
	if runes(q.Q) > MaxQueryRunes {
		return Page{}, errQuery
	}
	if in.Cursor != "" {
		c, err := decodeCursor(scope, in.Cursor)
		if err != nil {
			return Page{}, errCursor
		}
		if scope == ScopePopular {
			q.Offset = c.Offset
		} else {
			q.After = &c
		}
	}
	want := q.Limit
	q.Limit = want + 1
	rows, err := s.repo.List(ctx, q)
	if err != nil {
		return Page{}, err
	}
	var page Page
	if len(rows) > want {
		rows = rows[:want]
		last := rows[want-1]
		c := Cursor{Offset: q.Offset + want, ID: last.ID, Time: last.CreatedAt}
		if scope == ScopeUpcoming {
			c.Time = last.StartDate
		}
		page.NextCursor = encodeCursor(scope, c)
	}
	for i := range rows {
		rows[i] = finish(rows[i], viewer)
		rows[i].PrivateMessage, rows[i].LinkedTripID = "", nil // never part of a summary
	}
	page.Events = rows
	return page, nil
}

// CommentPage is one page of comments.
type CommentPage struct {
	Comments   []Comment
	NextCursor string
}

func (s *Service) visibleEvent(ctx context.Context, viewer *uuid.UUID, id uuid.UUID) (Event, error) {
	return s.Get(ctx, viewer, id)
}

// ListComments returns public comments, oldest first.
func (s *Service) ListComments(ctx context.Context, viewer *uuid.UUID, id uuid.UUID, limit int, cursor string) (CommentPage, error) {
	if limit == 0 {
		limit = DefaultLimit
	}
	if limit < 1 || limit > MaxLimit {
		return CommentPage{}, errLimit
	}
	var after *Cursor
	if cursor != "" {
		c, err := decodeCursor("comments", cursor)
		if err != nil {
			return CommentPage{}, errCursor
		}
		after = &c
	}
	if _, err := s.visibleEvent(ctx, viewer, id); err != nil {
		return CommentPage{}, err
	}
	rows, err := s.repo.ListComments(ctx, id, limit+1, after)
	if err != nil {
		return CommentPage{}, err
	}
	var page CommentPage
	if len(rows) > limit {
		rows = rows[:limit]
		page.NextCursor = encodeCursor("comments", Cursor{Time: rows[limit-1].CreatedAt, ID: rows[limit-1].ID})
	}
	for i := range rows {
		rows[i].Mine = viewer != nil && *viewer == rows[i].UserID
	}
	page.Comments = rows
	return page, nil
}

// CreateComment posts a public comment.
func (s *Service) CreateComment(ctx context.Context, user, id uuid.UUID, body string) (Comment, error) {
	body = strings.TrimSpace(body)
	if n := runes(body); n < 1 || n > maxComment {
		return Comment{}, errComment
	}
	if _, err := s.visibleEvent(ctx, &user, id); err != nil {
		return Comment{}, err
	}
	if err := s.allow(s.opts.Comments, user); err != nil {
		return Comment{}, err
	}
	c, err := s.repo.CreateComment(ctx, Comment{ID: s.newID(), EventID: id, UserID: user, Body: body})
	if err != nil {
		return Comment{}, err
	}
	c.Mine = true
	return c, nil
}

// DeleteComment soft-deletes a comment; allowed for its author and the event host.
func (s *Service) DeleteComment(ctx context.Context, user, id, commentID uuid.UUID) error {
	e, err := s.visibleEvent(ctx, &user, id)
	if err != nil {
		return err
	}
	c, err := s.repo.GetComment(ctx, commentID)
	if errors.Is(err, ErrNotFound) || (err == nil && c.EventID != id) {
		return errCommentNotFound
	}
	if err != nil {
		return err
	}
	if c.UserID != user && !e.IsHost {
		return errForbidden
	}
	return s.repo.DeleteComment(ctx, commentID)
}

// SetLike likes or unlikes (idempotent) and returns the new state.
func (s *Service) SetLike(ctx context.Context, user, id uuid.UUID, liked bool) (LikeState, error) {
	if _, err := s.visibleEvent(ctx, &user, id); err != nil {
		return LikeState{}, err
	}
	n, err := s.repo.SetLike(ctx, id, user, liked)
	if err != nil {
		return LikeState{}, err
	}
	return LikeState{Liked: liked, LikeCount: n}, nil
}

// ReportInput is a report request.
type ReportInput struct {
	TargetType string
	TargetID   uuid.UUID
	Reason     string
}

// CreateReport stores a report; created is false when the caller already reported the target.
func (s *Service) CreateReport(ctx context.Context, user uuid.UUID, in ReportInput) (Report, bool, error) {
	reason := strings.TrimSpace(in.Reason)
	if n := runes(reason); n < 1 || n > maxReason {
		return Report{}, false, errReason
	}
	switch in.TargetType {
	case TargetEvent:
		if _, err := s.visibleEvent(ctx, &user, in.TargetID); err != nil {
			return Report{}, false, err
		}
	case TargetComment:
		c, err := s.repo.GetComment(ctx, in.TargetID)
		if errors.Is(err, ErrNotFound) {
			return Report{}, false, errCommentNotFound
		}
		if err != nil {
			return Report{}, false, err
		}
		if _, err := s.visibleEvent(ctx, &user, c.EventID); err != nil {
			return Report{}, false, errCommentNotFound
		}
	default:
		return Report{}, false, errTargetType
	}
	return s.repo.CreateReport(ctx, Report{
		ID: s.newID(), ReporterID: user, TargetType: in.TargetType, TargetID: in.TargetID, Reason: reason,
	})
}

// Cursor is the position after the last row of a page.
type Cursor struct {
	Time   time.Time // created_at, or start_date for upcoming
	ID     uuid.UUID
	Offset int // popular only
}

// encodeCursor binds the cursor to its scope so a cursor from another list is rejected.
func encodeCursor(scope string, c Cursor) string {
	var raw string
	if scope == ScopePopular {
		raw = "p|" + scope + "|" + strconv.Itoa(c.Offset)
	} else {
		raw = "k|" + scope + "|" + strconv.FormatInt(c.Time.UnixMicro(), 10) + "|" + c.ID.String()
	}
	return base64.RawURLEncoding.EncodeToString([]byte(raw))
}

func decodeCursor(scope, s string) (Cursor, error) {
	b, err := base64.RawURLEncoding.DecodeString(s)
	if err != nil {
		return Cursor{}, err
	}
	parts := strings.Split(string(b), "|")
	if len(parts) < 3 || parts[1] != scope {
		return Cursor{}, fmt.Errorf("bad cursor")
	}
	if parts[0] == "p" && len(parts) == 3 && scope == ScopePopular {
		n, err := strconv.Atoi(parts[2])
		if err != nil || n < 0 {
			return Cursor{}, fmt.Errorf("bad cursor")
		}
		return Cursor{Offset: n}, nil
	}
	if parts[0] == "k" && len(parts) == 4 && scope != ScopePopular {
		us, err := strconv.ParseInt(parts[2], 10, 64)
		if err != nil {
			return Cursor{}, err
		}
		id, err := uuid.Parse(parts[3])
		if err != nil {
			return Cursor{}, err
		}
		return Cursor{Time: time.UnixMicro(us).UTC(), ID: id}, nil
	}
	return Cursor{}, fmt.Errorf("bad cursor")
}

// SnapshotOf decodes a stored snapshot (nil when the event has none).
func SnapshotOf(raw json.RawMessage) (*Snapshot, error) {
	if len(raw) == 0 {
		return nil, nil
	}
	var sn Snapshot
	if err := json.Unmarshal(raw, &sn); err != nil {
		return nil, err
	}
	return &sn, nil
}
