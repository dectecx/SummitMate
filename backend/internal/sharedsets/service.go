// Package sharedsets implements cloud sharing of gear sets (online only, not part of sync).
package sharedsets

import (
	"context"
	"encoding/base64"
	"errors"
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"

	"summitmate/internal/gearset"
	"summitmate/internal/platform/apperror"
	"summitmate/internal/platform/ratelimit"
)

// Visibility values.
const (
	Public    = "public"
	Protected = "protected"
	Private   = "private"
)

const (
	MaxTitleRunes = 200
	DefaultLimit  = 20
	MaxLimit      = 50
	MaxQueryRunes = 100
	maxAuthorName = 100
)

var (
	ErrSetNotFound      = apperror.New(http.StatusNotFound, apperror.TypeBusinessLogic, "shared_set_not_found", "找不到這份組合")
	ErrAccessKeyNeeded  = apperror.New(http.StatusForbidden, apperror.TypeAuth, "access_key_required", "這份組合受 Key 保護，請輸入 Key")
	ErrInvalidAccessKey = apperror.New(http.StatusForbidden, apperror.TypeAuth, "invalid_access_key", "Key 不正確")
	errTitle            = apperror.New(http.StatusBadRequest, apperror.TypeValidation, "invalid_title", "標題長度必須介於 1 到 200 字").WithParam("title")
	errVisibility       = apperror.New(http.StatusBadRequest, apperror.TypeValidation, "invalid_visibility", "可見性必須是 public、protected 或 private").WithParam("visibility")
	errKeyFormat        = apperror.New(http.StatusBadRequest, apperror.TypeValidation, "invalid_key_format", "Key 必須是 4 到 12 個英文字母或數字").WithParam("access_key")
	errKeyNotAllowed    = apperror.New(http.StatusBadRequest, apperror.TypeValidation, "key_not_allowed", "只有受保護的組合可以設定 Key").WithParam("access_key")
	errItems            = apperror.New(http.StatusBadRequest, apperror.TypeValidation, "invalid_items", "項目格式不正確").WithParam("items")
	errScope            = apperror.New(http.StatusBadRequest, apperror.TypeValidation, "invalid_scope", "scope 必須是 public 或 mine").WithParam("scope")
	errLimit            = apperror.New(http.StatusBadRequest, apperror.TypeValidation, "invalid_limit", "limit 必須介於 1 到 50").WithParam("limit")
	errCursor           = apperror.New(http.StatusBadRequest, apperror.TypeValidation, "invalid_cursor", "cursor 不正確").WithParam("cursor")
	errQuery            = apperror.New(http.StatusBadRequest, apperror.TypeValidation, "invalid_query", "搜尋字串不可超過 100 字").WithParam("q")
)

// Options configures a Service.
type Options struct {
	BcryptCost int
	// WrongKeys limits wrong access-key attempts per client and set (nil = a default).
	WrongKeys ratelimit.Limiter
}

// Service holds the business rules.
type Service struct {
	repo  Repository
	opts  Options
	newID func() uuid.UUID
}

func NewService(repo Repository, o Options) *Service {
	if o.BcryptCost == 0 {
		o.BcryptCost = bcrypt.DefaultCost
	}
	if o.WrongKeys == nil {
		o.WrongKeys = ratelimit.NewMemory(10, 15*time.Minute)
	}
	return &Service{repo: repo, opts: o, newID: uuid.New}
}

// CreateInput is a validated-on-entry share request.
type CreateInput struct {
	Title      string
	Visibility string
	AccessKey  *string
	Items      []gearset.Item
}

func validKey(k string) bool {
	if len(k) < 4 || len(k) > 12 {
		return false
	}
	for i := 0; i < len(k); i++ {
		c := k[i]
		if !(c >= '0' && c <= '9' || c >= 'a' && c <= 'z' || c >= 'A' && c <= 'Z') {
			return false
		}
	}
	return true
}

// Create validates and stores a new set owned by owner.
func (s *Service) Create(ctx context.Context, owner uuid.UUID, in CreateInput) (Set, error) {
	title := strings.TrimSpace(in.Title)
	if n := utf8.RuneCountInString(title); n < 1 || n > MaxTitleRunes {
		return Set{}, errTitle
	}
	var keyHash string
	switch in.Visibility {
	case Public, Private:
		if in.AccessKey != nil && *in.AccessKey != "" {
			return Set{}, errKeyNotAllowed
		}
	case Protected:
		if in.AccessKey == nil || !validKey(*in.AccessKey) {
			return Set{}, errKeyFormat
		}
		h, err := bcrypt.GenerateFromPassword([]byte(*in.AccessKey), s.opts.BcryptCost)
		if err != nil {
			return Set{}, err
		}
		keyHash = string(h)
	default:
		return Set{}, errVisibility
	}
	if err := gearset.ValidateAll(in.Items, true); err != nil {
		return Set{}, errItems.WithMessage(err.Error())
	}
	name, err := s.repo.DisplayName(ctx, owner)
	if err != nil {
		return Set{}, err
	}
	if r := []rune(name); len(r) > maxAuthorName {
		name = string(r[:maxAuthorName])
	}
	weight, gear, meal := gearset.Totals(in.Items)
	set := Set{
		ID: s.newID(), OwnerID: owner, Title: title, AuthorName: name, Visibility: in.Visibility, KeyHash: keyHash,
		Items: in.Items, TotalWeight: weight, GearCount: gear, MealCount: meal,
	}
	if err := s.repo.Create(ctx, set); err != nil {
		return Set{}, err
	}
	// Re-read for the stored created_at (the repository stamps it).
	return s.repo.Get(ctx, set.ID)
}

// Get returns a set with items if the viewer (nil = anonymous) may read it.
// clientID identifies the caller for rate limiting wrong keys (e.g. its IP).
func (s *Service) Get(ctx context.Context, viewer *uuid.UUID, id uuid.UUID, key, clientID string) (Set, error) {
	set, err := s.repo.Get(ctx, id)
	if errors.Is(err, ErrNotFound) {
		return Set{}, ErrSetNotFound
	}
	if err != nil {
		return Set{}, err
	}
	if viewer != nil && *viewer == set.OwnerID {
		return set, nil
	}
	switch set.Visibility {
	case Public:
		return set, nil
	case Protected:
		if key == "" {
			return Set{}, ErrAccessKeyNeeded
		}
		limitKey := clientID + "|" + id.String()
		if !s.opts.WrongKeys.Allow(limitKey) {
			return Set{}, apperror.ErrTooManyRequests
		}
		// bcrypt compares in constant time with respect to the hash.
		if bcrypt.CompareHashAndPassword([]byte(set.KeyHash), []byte(key)) != nil {
			s.opts.WrongKeys.Record(limitKey)
			return Set{}, ErrInvalidAccessKey
		}
		s.opts.WrongKeys.Reset(limitKey)
		return set, nil
	}
	return Set{}, ErrSetNotFound // private
}

// ListInput selects a page.
type ListInput struct {
	Mine   bool
	Q      string
	Limit  int // 0 = default
	Cursor string
}

// Page is one page of summaries.
type Page struct {
	Sets       []Set
	NextCursor string
}

// List returns summaries. Mine requires a non-nil viewer.
func (s *Service) List(ctx context.Context, viewer *uuid.UUID, in ListInput) (Page, error) {
	q := ListQuery{Mine: in.Mine, Limit: in.Limit, Q: strings.TrimSpace(in.Q)}
	if in.Mine {
		if viewer == nil {
			return Page{}, apperror.ErrUnauthorized
		}
		q.Owner = *viewer
	}
	if q.Limit == 0 {
		q.Limit = DefaultLimit
	}
	if q.Limit < 1 || q.Limit > MaxLimit {
		return Page{}, errLimit
	}
	if utf8.RuneCountInString(q.Q) > MaxQueryRunes {
		return Page{}, errQuery
	}
	if in.Cursor != "" {
		c, err := decodeCursor(in.Cursor)
		if err != nil {
			return Page{}, errCursor
		}
		q.After = &c
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
		page.NextCursor = encodeCursor(Cursor{CreatedAt: rows[want-1].CreatedAt, ID: rows[want-1].ID})
	}
	page.Sets = rows
	return page, nil
}

// Delete soft-deletes a set owned by owner; other callers get not-found.
func (s *Service) Delete(ctx context.Context, owner, id uuid.UUID) error {
	ok, err := s.repo.Delete(ctx, id, owner)
	if err != nil {
		return err
	}
	if !ok {
		return ErrSetNotFound
	}
	return nil
}

func encodeCursor(c Cursor) string {
	return base64.RawURLEncoding.EncodeToString([]byte(strconv.FormatInt(c.CreatedAt.UnixMicro(), 10) + ":" + c.ID.String()))
}

func decodeCursor(s string) (Cursor, error) {
	raw, err := base64.RawURLEncoding.DecodeString(s)
	if err != nil {
		return Cursor{}, err
	}
	ts, id, ok := strings.Cut(string(raw), ":")
	if !ok {
		return Cursor{}, fmt.Errorf("bad cursor")
	}
	us, err := strconv.ParseInt(ts, 10, 64)
	if err != nil {
		return Cursor{}, err
	}
	u, err := uuid.Parse(id)
	if err != nil {
		return Cursor{}, err
	}
	return Cursor{CreatedAt: time.UnixMicro(us).UTC(), ID: u}, nil
}
