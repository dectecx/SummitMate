package groupevents

import (
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"time"

	"github.com/google/uuid"
	openapi_types "github.com/oapi-codegen/runtime/types"

	"summitmate/api"
	"summitmate/internal/auth"
	"summitmate/internal/platform/apperror"
	"summitmate/internal/platform/httpx"
)

// Handler adapts the Service to the generated API. Embed it in the server type.
type Handler struct{ svc *Service }

func NewHandler(svc *Service) *Handler { return &Handler{svc: svc} }

// viewer returns the authenticated user, if the middleware found a valid token.
func viewer(r *http.Request) *uuid.UUID {
	if id, ok := auth.UserID(r.Context()); ok {
		return &id
	}
	return nil
}

// caller returns the authenticated user or writes a 401.
func caller(w http.ResponseWriter, r *http.Request) (uuid.UUID, bool) {
	v := viewer(r)
	if v == nil {
		httpx.WriteError(w, r, apperror.ErrUnauthorized)
		return uuid.Nil, false
	}
	return *v, true
}

// readBody decodes the JSON body into v and, when raw is set, also into a key map so that
// an explicit null can be told apart from an absent key. An empty body is only allowed when optional.
func readBody(r *http.Request, v any, raw *map[string]json.RawMessage, optional bool) error {
	b, err := io.ReadAll(r.Body)
	if err != nil {
		var mbe *http.MaxBytesError
		if errors.As(err, &mbe) {
			return apperror.ErrPayloadTooLarge
		}
		return apperror.ErrBadRequest.Wrap(err)
	}
	if len(b) == 0 && optional {
		return nil
	}
	if err := json.Unmarshal(b, v); err != nil {
		return apperror.ErrBadRequest.Wrap(err)
	}
	if raw != nil {
		if err := json.Unmarshal(b, raw); err != nil {
			return apperror.ErrBadRequest.Wrap(err)
		}
	}
	return nil
}

func dateOut(t *time.Time) *openapi_types.Date {
	if t == nil {
		return nil
	}
	return &openapi_types.Date{Time: *t}
}

func dateIn(d *openapi_types.Date) *time.Time {
	if d == nil {
		return nil
	}
	t := d.Time
	return &t
}

func dateStr(d *openapi_types.Date) *string {
	if d == nil {
		return nil
	}
	s := d.Time.Format("2006-01-02")
	return &s
}

func strOrNil(s string) *string {
	if s == "" {
		return nil
	}
	return &s
}

func summary(e Event) api.GroupEventSummary {
	return api.GroupEventSummary{
		Id: e.ID, Title: e.Title, Category: api.GroupEventCategory(e.Category), Location: e.Location,
		StartDate: openapi_types.Date{Time: e.StartDate}, EndDate: dateOut(e.EndDate), MaxMembers: e.MaxMembers,
		ApprovedCount: e.ApprovedCount, LikeCount: e.LikeCount, CommentCount: e.CommentCount,
		Status: api.GroupEventStatus(e.Status), ApprovalRequired: e.ApprovalRequired,
		Host:      api.EventUser{Id: e.HostID, DisplayName: e.HostName, Avatar: e.HostAvatar},
		CreatedAt: e.CreatedAt, Liked: e.Liked, MyStatus: strOrNil(e.MyStatus), IsHost: e.IsHost,
	}
}

func detail(e Event) (api.GroupEventDetail, error) {
	s := summary(e)
	d := api.GroupEventDetail{
		ApprovalRequired: s.ApprovalRequired, ApprovedCount: s.ApprovedCount, Category: s.Category,
		CommentCount: s.CommentCount, CreatedAt: s.CreatedAt, EndDate: s.EndDate, Host: s.Host, Id: s.Id,
		IsHost: s.IsHost, LikeCount: s.LikeCount, Liked: s.Liked, Location: s.Location, MaxMembers: s.MaxMembers,
		MyStatus: s.MyStatus, StartDate: s.StartDate, Status: s.Status, Title: s.Title,
		Description: e.Description, PrivateMessageLocked: !e.PrivateMessageVisible,
		MyRejectionReason: strOrNil(e.MyRejection), SnapshotUpdatedAt: e.SnapshotAt,
	}
	if e.PrivateMessageVisible {
		pm := e.PrivateMessage
		d.PrivateMessage = &pm
	}
	if e.LinkedTripID != nil {
		id := *e.LinkedTripID
		d.LinkedTripId = &id
	}
	sn, err := SnapshotOf(e.TripSnapshot)
	if err != nil {
		return d, err
	}
	if sn != nil {
		out := api.TripSnapshot{Name: sn.Name, Itinerary: make([]api.TripSnapshotNode, 0, len(sn.Itinerary))}
		out.StartDate, out.EndDate = parseDatePtr(sn.StartDate), parseDatePtr(sn.EndDate)
		for _, n := range sn.Itinerary {
			out.Itinerary = append(out.Itinerary, api.TripSnapshotNode{
				Day: n.Day, Name: n.Name, Time: n.Time, Altitude: n.Altitude, Lat: n.Lat, Lng: n.Lng,
			})
		}
		d.TripSnapshot = &out
	}
	return d, nil
}

func parseDatePtr(s *string) *openapi_types.Date {
	if s == nil {
		return nil
	}
	t, err := parseDate(*s)
	if err != nil {
		return nil
	}
	return &openapi_types.Date{Time: t}
}

func snapshotIn(s *api.TripSnapshot) *Snapshot {
	if s == nil {
		return nil
	}
	out := &Snapshot{Name: s.Name, StartDate: dateStr(s.StartDate), EndDate: dateStr(s.EndDate), Itinerary: make([]SnapshotNode, 0, len(s.Itinerary))}
	for _, n := range s.Itinerary {
		out.Itinerary = append(out.Itinerary, SnapshotNode{Day: n.Day, Name: n.Name, Time: n.Time, Altitude: n.Altitude, Lat: n.Lat, Lng: n.Lng})
	}
	return out
}

func writeDetail(w http.ResponseWriter, r *http.Request, status int, e Event) {
	d, err := detail(e)
	if err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	httpx.WriteJSON(w, status, d)
}

func (h *Handler) ListGroupEvents(w http.ResponseWriter, r *http.Request, p api.ListGroupEventsParams) {
	in := ListInput{}
	if p.Scope != nil {
		if !p.Scope.Valid() {
			httpx.WriteError(w, r, errScope)
			return
		}
		in.Scope = string(*p.Scope)
	}
	if p.Q != nil {
		in.Q = *p.Q
	}
	if p.Limit != nil {
		in.Limit = *p.Limit
		if in.Limit == 0 {
			in.Limit = -1 // an explicit 0 is invalid
		}
	}
	if p.Cursor != nil {
		in.Cursor = *p.Cursor
	}
	page, err := h.svc.List(r.Context(), viewer(r), in)
	if err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	out := api.GroupEventPage{Items: make([]api.GroupEventSummary, 0, len(page.Events))}
	for _, e := range page.Events {
		out.Items = append(out.Items, summary(e))
	}
	if page.NextCursor != "" {
		c := page.NextCursor
		out.NextCursor = &c
	}
	httpx.WriteJSON(w, http.StatusOK, out)
}

func (h *Handler) CreateGroupEvent(w http.ResponseWriter, r *http.Request) {
	user, ok := caller(w, r)
	if !ok {
		return
	}
	var req api.CreateGroupEventRequest
	if err := readBody(r, &req, nil, false); err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	in := CreateInput{
		Title: req.Title, Category: string(req.Category), StartDate: req.StartDate.Time, EndDate: dateIn(req.EndDate),
		MaxMembers: req.MaxMembers, ApprovalRequired: true, LinkedTripID: req.LinkedTripId, TripSnapshot: snapshotIn(req.TripSnapshot),
	}
	if req.Location != nil {
		in.Location = *req.Location
	}
	if req.ApprovalRequired != nil {
		in.ApprovalRequired = *req.ApprovalRequired
	}
	if req.Description != nil {
		in.Description = *req.Description
	}
	if req.PrivateMessage != nil {
		in.PrivateMessage = *req.PrivateMessage
	}
	e, err := h.svc.Create(r.Context(), user, in)
	if err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	writeDetail(w, r, http.StatusCreated, e)
}

func (h *Handler) GetGroupEvent(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	e, err := h.svc.Get(r.Context(), viewer(r), id)
	if err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	writeDetail(w, r, http.StatusOK, e)
}

func (h *Handler) UpdateGroupEvent(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	user, ok := caller(w, r)
	if !ok {
		return
	}
	var req api.UpdateGroupEventRequest
	raw := map[string]json.RawMessage{}
	if err := readBody(r, &req, &raw, false); err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	in := UpdateInput{
		Title: req.Title, Location: req.Location, MaxMembers: req.MaxMembers, ApprovalRequired: req.ApprovalRequired,
		Description: req.Description, PrivateMessage: req.PrivateMessage,
	}
	if req.Category != nil {
		c := string(*req.Category)
		in.Category = &c
	}
	if req.Status != nil {
		s := string(*req.Status)
		in.Status = &s
	}
	if req.StartDate != nil {
		in.StartDate = dateIn(req.StartDate)
	}
	_, in.EndDate.Set = raw["end_date"]
	in.EndDate.Value = dateIn(req.EndDate)
	_, in.LinkedTripID.Set = raw["linked_trip_id"]
	in.LinkedTripID.Value = req.LinkedTripId
	_, in.TripSnapshot.Set = raw["trip_snapshot"]
	in.TripSnapshot.Value = snapshotIn(req.TripSnapshot)
	e, err := h.svc.Update(r.Context(), user, id, in)
	if err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	writeDetail(w, r, http.StatusOK, e)
}

func (h *Handler) CancelGroupEvent(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	user, ok := caller(w, r)
	if !ok {
		return
	}
	if err := h.svc.Cancel(r.Context(), user, id); err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) ApplyGroupEvent(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	user, ok := caller(w, r)
	if !ok {
		return
	}
	var req api.ApplyRequest
	if err := readBody(r, &req, nil, true); err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	msg := ""
	if req.Message != nil {
		msg = *req.Message
	}
	status, err := h.svc.Apply(r.Context(), user, id, msg)
	if err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, api.ApplyResponse{MyStatus: api.ApplicationStatus(status)})
}

func (h *Handler) WithdrawGroupEventApplication(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	user, ok := caller(w, r)
	if !ok {
		return
	}
	if err := h.svc.Withdraw(r.Context(), user, id); err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func application(a Application) api.Application {
	return api.Application{
		Id: a.ID, User: api.EventUser{Id: a.UserID, DisplayName: a.UserName, Avatar: a.UserAvatar},
		Status: api.ApplicationStatus(a.Status), Message: a.Message, CreatedAt: a.CreatedAt,
	}
}

func (h *Handler) ListGroupEventApplications(w http.ResponseWriter, r *http.Request, id openapi_types.UUID, p api.ListGroupEventApplicationsParams) {
	user, ok := caller(w, r)
	if !ok {
		return
	}
	status := ""
	if p.Status != nil {
		if !p.Status.Valid() {
			httpx.WriteError(w, r, errStatus)
			return
		}
		status = string(*p.Status)
	}
	apps, err := h.svc.ListApplications(r.Context(), user, id, status)
	if err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	out := api.ApplicationList{Items: make([]api.Application, 0, len(apps))}
	for _, a := range apps {
		out.Items = append(out.Items, application(a))
	}
	httpx.WriteJSON(w, http.StatusOK, out)
}

func (h *Handler) ReviewGroupEventApplication(w http.ResponseWriter, r *http.Request, id, appID openapi_types.UUID) {
	user, ok := caller(w, r)
	if !ok {
		return
	}
	var req api.ReviewRequest
	if err := readBody(r, &req, nil, false); err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	reason := ""
	if req.Reason != nil {
		reason = *req.Reason
	}
	a, err := h.svc.Review(r.Context(), user, id, appID, req.Approve, reason)
	if err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, application(a))
}

func (h *Handler) RemoveGroupEventMember(w http.ResponseWriter, r *http.Request, id, appID openapi_types.UUID) {
	user, ok := caller(w, r)
	if !ok {
		return
	}
	if err := h.svc.RemoveMember(r.Context(), user, id, appID); err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func comment(c Comment) api.Comment {
	return api.Comment{
		Id: c.ID, User: api.EventUser{Id: c.UserID, DisplayName: c.UserName, Avatar: c.UserAvatar},
		Body: c.Body, CreatedAt: c.CreatedAt, Mine: c.Mine,
	}
}

func (h *Handler) ListGroupEventComments(w http.ResponseWriter, r *http.Request, id openapi_types.UUID, p api.ListGroupEventCommentsParams) {
	limit, cursor := 0, ""
	if p.Limit != nil {
		limit = *p.Limit
		if limit == 0 {
			limit = -1
		}
	}
	if p.Cursor != nil {
		cursor = *p.Cursor
	}
	page, err := h.svc.ListComments(r.Context(), viewer(r), id, limit, cursor)
	if err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	out := api.CommentPage{Items: make([]api.Comment, 0, len(page.Comments))}
	for _, c := range page.Comments {
		out.Items = append(out.Items, comment(c))
	}
	if page.NextCursor != "" {
		c := page.NextCursor
		out.NextCursor = &c
	}
	httpx.WriteJSON(w, http.StatusOK, out)
}

func (h *Handler) CreateGroupEventComment(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	user, ok := caller(w, r)
	if !ok {
		return
	}
	var req api.CreateCommentRequest
	if err := readBody(r, &req, nil, false); err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	c, err := h.svc.CreateComment(r.Context(), user, id, req.Body)
	if err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusCreated, comment(c))
}

func (h *Handler) DeleteGroupEventComment(w http.ResponseWriter, r *http.Request, id, commentID openapi_types.UUID) {
	user, ok := caller(w, r)
	if !ok {
		return
	}
	if err := h.svc.DeleteComment(r.Context(), user, id, commentID); err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) setLike(w http.ResponseWriter, r *http.Request, id uuid.UUID, liked bool) {
	user, ok := caller(w, r)
	if !ok {
		return
	}
	st, err := h.svc.SetLike(r.Context(), user, id, liked)
	if err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	httpx.WriteJSON(w, http.StatusOK, api.LikeState{Liked: st.Liked, LikeCount: st.LikeCount})
}

func (h *Handler) LikeGroupEvent(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	h.setLike(w, r, id, true)
}

func (h *Handler) UnlikeGroupEvent(w http.ResponseWriter, r *http.Request, id openapi_types.UUID) {
	h.setLike(w, r, id, false)
}

func (h *Handler) CreateReport(w http.ResponseWriter, r *http.Request) {
	user, ok := caller(w, r)
	if !ok {
		return
	}
	var req api.CreateReportRequest
	if err := readBody(r, &req, nil, false); err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	rp, created, err := h.svc.CreateReport(r.Context(), user, ReportInput{
		TargetType: string(req.TargetType), TargetID: req.TargetId, Reason: req.Reason,
	})
	if err != nil {
		httpx.WriteError(w, r, err)
		return
	}
	status := http.StatusOK
	if created {
		status = http.StatusCreated
	}
	httpx.WriteJSON(w, status, api.Report{
		Id: rp.ID, TargetType: api.ReportTargetType(rp.TargetType), TargetId: rp.TargetID, CreatedAt: rp.CreatedAt,
	})
}
