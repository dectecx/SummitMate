package sharedsets

import (
	"context"
	"encoding/base64"
	"sort"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"golang.org/x/crypto/bcrypt"

	"summitmate/internal/gearset"
	"summitmate/internal/platform/apperror"
	"summitmate/internal/platform/ratelimit"
)

type fakeRepo struct {
	sets  map[uuid.UUID]Set
	dead  map[uuid.UUID]bool
	names map[uuid.UUID]string
	clock time.Time
}

func newFake() *fakeRepo {
	return &fakeRepo{sets: map[uuid.UUID]Set{}, dead: map[uuid.UUID]bool{}, names: map[uuid.UUID]string{},
		clock: time.Date(2026, 1, 1, 0, 0, 0, 0, time.UTC)}
}

func (f *fakeRepo) Create(_ context.Context, s Set) error {
	f.clock = f.clock.Add(time.Second)
	s.CreatedAt = f.clock
	f.sets[s.ID] = s
	return nil
}
func (f *fakeRepo) Get(_ context.Context, id uuid.UUID) (Set, error) {
	s, ok := f.sets[id]
	if !ok || f.dead[id] {
		return Set{}, ErrNotFound
	}
	return s, nil
}
func (f *fakeRepo) List(_ context.Context, q ListQuery) ([]Set, error) {
	var out []Set
	for id, s := range f.sets {
		if f.dead[id] || (q.Mine && s.OwnerID != q.Owner) || (!q.Mine && s.Visibility == Private) {
			continue
		}
		if q.Q != "" && !strings.Contains(strings.ToLower(s.Title), strings.ToLower(q.Q)) {
			continue
		}
		if q.After != nil && !s.CreatedAt.Before(q.After.CreatedAt) {
			continue
		}
		out = append(out, s)
	}
	sort.Slice(out, func(i, j int) bool { return out[i].CreatedAt.After(out[j].CreatedAt) })
	if len(out) > q.Limit {
		out = out[:q.Limit]
	}
	return out, nil
}
func (f *fakeRepo) Delete(_ context.Context, id, owner uuid.UUID) (bool, error) {
	s, ok := f.sets[id]
	if !ok || f.dead[id] || s.OwnerID != owner {
		return false, nil
	}
	f.dead[id] = true
	return true, nil
}
func (f *fakeRepo) DisplayName(_ context.Context, id uuid.UUID) (string, error) {
	if n, ok := f.names[id]; ok {
		return n, nil
	}
	return "", ErrNotFound
}

func newSvc() (*Service, *fakeRepo, uuid.UUID) {
	r := newFake()
	owner := uuid.New()
	r.names[owner] = "阿山"
	return NewService(r, Options{BcryptCost: bcrypt.MinCost, WrongKeys: ratelimit.NewMemory(3, time.Minute)}), r, owner
}

func gear(name string, w float64, q int) gearset.Item {
	return gearset.Item{Kind: "gear", Name: name, Category: "sleep", Weight: w, Quantity: q}
}

func in(vis string, key *string) CreateInput {
	return CreateInput{Title: "三天兩夜", Visibility: vis, AccessKey: key, Items: []gearset.Item{
		gear("睡袋", 900, 1), gear("水壺", 100, 2), {Kind: "meal", Name: "飯糰", Category: "lunch", Weight: 180, Quantity: 2},
	}}
}

func ptr(s string) *string { return &s }

func code(t *testing.T, err error) string {
	t.Helper()
	ae, ok := apperror.As(err)
	require.True(t, ok, "not an apperror: %v", err)
	return ae.Code
}

func TestCreateComputesTotalsAndSnapshotsAuthor(t *testing.T) {
	svc, repo, owner := newSvc()
	set, err := svc.Create(context.Background(), owner, in(Public, nil))
	require.NoError(t, err)
	assert.Equal(t, 1100.0, set.TotalWeight, "gear weight x quantity only")
	assert.Equal(t, 2, set.GearCount)
	assert.Equal(t, 1, set.MealCount)
	assert.Equal(t, "阿山", set.AuthorName)
	repo.names[owner] = "新名字"
	got, _ := svc.Get(context.Background(), nil, set.ID, "", "ip")
	assert.Equal(t, "阿山", got.AuthorName, "snapshot")
}

func TestCreateValidation(t *testing.T) {
	svc, _, owner := newSvc()
	ctx := context.Background()
	mk := func(f func(*CreateInput)) CreateInput { c := in(Public, nil); f(&c); return c }
	many := make([]gearset.Item, 301)
	for i := range many {
		many[i] = gear("x", 1, 1)
	}
	cases := map[string]struct {
		in   CreateInput
		code string
	}{
		"empty title":      {mk(func(c *CreateInput) { c.Title = "  " }), "invalid_title"},
		"long title":       {mk(func(c *CreateInput) { c.Title = strings.Repeat("好", 201) }), "invalid_title"},
		"bad visibility":   {mk(func(c *CreateInput) { c.Visibility = "friends" }), "invalid_visibility"},
		"protected no key": {in(Protected, nil), "invalid_key_format"},
		"short key":        {in(Protected, ptr("abc")), "invalid_key_format"},
		"long key":         {in(Protected, ptr("abcdefghijklm")), "invalid_key_format"},
		"symbol key":       {in(Protected, ptr("abc-1234")), "invalid_key_format"},
		"cjk key":          {in(Protected, ptr("密碼密碼密碼")), "invalid_key_format"},
		"public with key":  {in(Public, ptr("abcd")), "key_not_allowed"},
		"private with key": {in(Private, ptr("abcd")), "key_not_allowed"},
		"no items":         {mk(func(c *CreateInput) { c.Items = nil }), "invalid_items"},
		"301 items":        {mk(func(c *CreateInput) { c.Items = many }), "invalid_items"},
		"bad kind":         {mk(func(c *CreateInput) { c.Items[0].Kind = "x" }), "invalid_items"},
		"empty name":       {mk(func(c *CreateInput) { c.Items[0].Name = "" }), "invalid_items"},
		"long name":        {mk(func(c *CreateInput) { c.Items[0].Name = strings.Repeat("a", 201) }), "invalid_items"},
		"neg weight":       {mk(func(c *CreateInput) { c.Items[0].Weight = -1 }), "invalid_items"},
		"neg qty":          {mk(func(c *CreateInput) { c.Items[0].Quantity = -1 }), "invalid_items"},
	}
	for name, c := range cases {
		_, err := svc.Create(ctx, owner, c.in)
		require.Error(t, err, name)
		assert.Equal(t, c.code, code(t, err), name)
	}
	_, err := svc.Create(ctx, owner, in(Protected, ptr("abCD12")))
	assert.NoError(t, err)
	_, err = svc.Create(ctx, owner, in(Public, ptr("")))
	assert.NoError(t, err, "empty key counts as none")
}

func TestVisibilityMatrix(t *testing.T) {
	svc, _, owner := newSvc()
	ctx := context.Background()
	stranger := uuid.New()
	pub, _ := svc.Create(ctx, owner, in(Public, nil))
	prot, _ := svc.Create(ctx, owner, in(Protected, ptr("secret1")))
	priv, _ := svc.Create(ctx, owner, in(Private, nil))
	assert.NotEqual(t, "secret1", prot.KeyHash, "stored hashed")

	get := func(viewer *uuid.UUID, id uuid.UUID, key string) error {
		_, err := svc.Get(ctx, viewer, id, key, "ip")
		return err
	}
	assert.NoError(t, get(nil, pub.ID, ""))
	assert.NoError(t, get(&stranger, pub.ID, ""))
	assert.NoError(t, get(&owner, priv.ID, ""))
	assert.Equal(t, "shared_set_not_found", code(t, get(nil, priv.ID, "")))
	assert.Equal(t, "shared_set_not_found", code(t, get(&stranger, priv.ID, "secret1")))
	assert.Equal(t, "shared_set_not_found", code(t, get(nil, uuid.New(), "")))

	assert.NoError(t, get(&owner, prot.ID, ""), "owner needs no key")
	assert.Equal(t, "access_key_required", code(t, get(nil, prot.ID, "")))
	assert.Equal(t, "invalid_access_key", code(t, get(&stranger, prot.ID, "nope")))
	assert.NoError(t, get(&stranger, prot.ID, "secret1"))
	assert.NoError(t, get(nil, prot.ID, "secret1"))
	assert.Equal(t, "invalid_access_key", code(t, get(nil, prot.ID, "SECRET1")), "case sensitive")
}

func TestWrongKeyRateLimit(t *testing.T) {
	svc, _, owner := newSvc()
	ctx := context.Background()
	prot, _ := svc.Create(ctx, owner, in(Protected, ptr("secret1")))
	for i := 0; i < 3; i++ {
		_, err := svc.Get(ctx, nil, prot.ID, "bad", "1.1.1.1")
		assert.Equal(t, "invalid_access_key", code(t, err))
	}
	_, err := svc.Get(ctx, nil, prot.ID, "bad", "1.1.1.1")
	assert.Equal(t, "too_many_requests", code(t, err))
	_, err = svc.Get(ctx, nil, prot.ID, "secret1", "1.1.1.1")
	assert.Equal(t, "too_many_requests", code(t, err), "even the right key waits")
	// Other clients and other sets are unaffected; missing key is never counted.
	_, err = svc.Get(ctx, nil, prot.ID, "secret1", "2.2.2.2")
	assert.NoError(t, err)
	_, err = svc.Get(ctx, nil, prot.ID, "", "3.3.3.3")
	assert.Equal(t, "access_key_required", code(t, err))
}

func TestListScopesPaginationAndDelete(t *testing.T) {
	svc, _, owner := newSvc()
	ctx := context.Background()
	other := uuid.New()
	svc.repo.(*fakeRepo).names[other] = "路人"
	var ids []uuid.UUID
	for i := 0; i < 5; i++ {
		s, _ := svc.Create(ctx, owner, in(Public, nil))
		ids = append(ids, s.ID)
	}
	priv, _ := svc.Create(ctx, owner, in(Private, nil))
	svc.Create(ctx, other, in(Protected, ptr("abcd")))

	_, err := svc.List(ctx, nil, ListInput{Mine: true})
	assert.Equal(t, "unauthorized", code(t, err))
	_, err = svc.List(ctx, nil, ListInput{Limit: 51})
	assert.Equal(t, "invalid_limit", code(t, err))
	_, err = svc.List(ctx, nil, ListInput{Cursor: "garbage!"})
	assert.Equal(t, "invalid_cursor", code(t, err))

	pubPage, err := svc.List(ctx, nil, ListInput{})
	require.NoError(t, err)
	assert.Len(t, pubPage.Sets, 6, "5 public + 1 protected, no private")
	for _, s := range pubPage.Sets {
		assert.NotEqual(t, priv.ID, s.ID)
	}

	var seen []uuid.UUID
	cursor := ""
	for {
		p, err := svc.List(ctx, &owner, ListInput{Mine: true, Limit: 2, Cursor: cursor})
		require.NoError(t, err)
		for _, s := range p.Sets {
			seen = append(seen, s.ID)
		}
		if p.NextCursor == "" {
			break
		}
		cursor = p.NextCursor
	}
	require.Len(t, seen, 6, "mine includes private")
	assert.Equal(t, priv.ID, seen[0], "newest first")

	// delete: owner only, hides from get and list
	assert.Equal(t, "shared_set_not_found", code(t, svc.Delete(ctx, other, ids[0])))
	require.NoError(t, svc.Delete(ctx, owner, ids[0]))
	assert.Equal(t, "shared_set_not_found", code(t, svc.Delete(ctx, owner, ids[0])))
	_, err = svc.Get(ctx, &owner, ids[0], "", "ip")
	assert.Equal(t, "shared_set_not_found", code(t, err))
}

func TestCursorRoundTrip(t *testing.T) {
	c := Cursor{CreatedAt: time.Date(2026, 5, 6, 7, 8, 9, 123456000, time.UTC), ID: uuid.New()}
	got, err := decodeCursor(encodeCursor(c))
	require.NoError(t, err)
	assert.True(t, c.CreatedAt.Equal(got.CreatedAt))
	assert.Equal(t, c.ID, got.ID)
	for _, bad := range []string{"", "!!", encodeCursorRaw("x"), encodeCursorRaw("1:notuuid")} {
		_, err := decodeCursor(bad)
		assert.Error(t, err, bad)
	}
}

func encodeCursorRaw(s string) string {
	return strings.TrimRight(base64URL(s), "=")
}

func base64URL(s string) string { return base64.RawURLEncoding.EncodeToString([]byte(s)) }
