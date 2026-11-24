package friends

import (
	"context"
	"errors"
	"net/http"
	"time"

	"github.com/google/uuid"

	"summitmate/internal/platform/apperror"
	"summitmate/internal/platform/ratelimit"
)

// Limits.
const (
	MaxRequestsPerHour = 20
	MaxPendingOutgoing = 100
)

var (
	errSelf         = apperror.New(http.StatusBadRequest, apperror.TypeValidation, "cannot_friend_self", "不能加自己為好友").WithParam("user_id")
	errUserNotFound = apperror.New(http.StatusNotFound, apperror.TypeBusinessLogic, "user_not_found", "找不到這位使用者")
	errReqNotFound  = apperror.New(http.StatusNotFound, apperror.TypeBusinessLogic, "friend_request_not_found", "找不到這筆好友邀請")
	errForbidden    = apperror.New(http.StatusForbidden, apperror.TypeAuth, "forbidden", "沒有權限執行這個操作")
	errTooManyReqs  = apperror.New(http.StatusTooManyRequests, apperror.TypeAuth, "too_many_requests", "好友邀請送出太頻繁，請稍後再試")
	errTooPending   = apperror.New(http.StatusConflict, apperror.TypeBusinessLogic, "too_many_pending_requests", "等待回覆的好友邀請已達上限")
)

// Options configures a Service. A nil limiter gets the default (20 per hour per user).
type Options struct {
	Requests ratelimit.Limiter // per user, counts new requests only
	Now      func() time.Time
}

// Service holds the business rules.
type Service struct {
	repo  Repository
	opts  Options
	newID func() uuid.UUID
}

func NewService(repo Repository, o Options) *Service {
	if o.Requests == nil {
		o.Requests = ratelimit.NewMemory(MaxRequestsPerHour, time.Hour)
	}
	if o.Now == nil {
		o.Now = time.Now
	}
	return &Service{repo: repo, opts: o, newID: uuid.New}
}

// List returns my friends and the requests I received and sent.
func (s *Service) List(ctx context.Context, me uuid.UUID) (Lists, error) {
	return s.repo.List(ctx, me)
}

// Send asks target to be friends. A request that crosses an incoming one is accepted at once.
func (s *Service) Send(ctx context.Context, me, target uuid.UUID) (SendResult, error) {
	if me == target {
		return SendResult{}, errSelf
	}
	key := me.String()
	var res SendResult
	err := s.repo.WithTx(ctx, func(tx Tx) error {
		if err := tx.LockPair(ctx, me, target); err != nil {
			return err
		}
		ok, err := tx.UserAvailable(ctx, target)
		if err != nil {
			return err
		}
		if !ok {
			return errUserNotFound
		}
		f, err := tx.GetByPair(ctx, me, target)
		switch {
		case err == nil:
			switch {
			case f.Status == StatusAccepted:
				res = SendResult{Status: StatusAccepted, RequestID: f.ID}
			case f.Requester == me:
				res = SendResult{Status: StatusPending, RequestID: f.ID}
			default: // the other person already asked me
				if err := tx.Accept(ctx, f.ID, s.opts.Now()); err != nil {
					return err
				}
				res = SendResult{Status: StatusAccepted, RequestID: f.ID, Created: true}
			}
			return nil
		case !errors.Is(err, ErrNotFound):
			return err
		}
		if !s.opts.Requests.Allow(key) {
			return errTooManyReqs
		}
		n, err := tx.CountPendingOutgoing(ctx, me)
		if err != nil {
			return err
		}
		if n >= MaxPendingOutgoing {
			return errTooPending
		}
		id := s.newID()
		if err := tx.Insert(ctx, Friendship{ID: id, Requester: me, Addressee: target, Status: StatusPending, CreatedAt: s.opts.Now()}); err != nil {
			return err
		}
		res = SendResult{Status: StatusPending, RequestID: id, Created: true}
		return nil
	})
	if err != nil {
		return SendResult{}, err
	}
	if res.Created && res.Status == StatusPending {
		s.opts.Requests.Record(key)
	}
	return res, nil
}

// Accept lets the addressee accept a pending request.
func (s *Service) Accept(ctx context.Context, me, requestID uuid.UUID) error {
	return s.repo.WithTx(ctx, func(tx Tx) error {
		f, err := tx.GetByID(ctx, requestID)
		if err != nil {
			return notFound(err)
		}
		if f.Status != StatusPending {
			return errReqNotFound
		}
		if f.Addressee != me {
			return errForbidden
		}
		return tx.Accept(ctx, f.ID, s.opts.Now())
	})
}

// Remove lets the addressee decline or the requester cancel a pending request. The row is deleted.
func (s *Service) Remove(ctx context.Context, me, requestID uuid.UUID) error {
	return s.repo.WithTx(ctx, func(tx Tx) error {
		f, err := tx.GetByID(ctx, requestID)
		if err != nil {
			return notFound(err)
		}
		if f.Status != StatusPending || (f.Requester != me && f.Addressee != me) {
			return errReqNotFound
		}
		return tx.Delete(ctx, f.ID)
	})
}

// Unfriend removes an accepted friendship; it is idempotent.
func (s *Service) Unfriend(ctx context.Context, me, other uuid.UUID) error {
	return s.repo.WithTx(ctx, func(tx Tx) error {
		if err := tx.LockPair(ctx, me, other); err != nil {
			return err
		}
		return tx.DeleteAccepted(ctx, me, other)
	})
}

func notFound(err error) error {
	if errors.Is(err, ErrNotFound) {
		return errReqNotFound
	}
	return err
}
