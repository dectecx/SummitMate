package explore

import (
	"bytes"
	_ "embed"
	"encoding/json"
	"errors"
	"fmt"
	"net/url"
	"regexp"
	"slices"
	"strings"
	"time"
)

//go:embed shops.json
var embeddedShops []byte

// Shop categories (what a shop sells).
var validShopCategories = []string{"登山裝備", "服飾", "食物", "露營", "潛水", "攀岩", "其他"}

var phoneRe = regexp.MustCompile(`^[0-9+()\-#\s]{6,30}$`)

// Shop is one outdoor-gear store. JSON names match the API contract.
// Only stores whose Google Maps rating was 4.0 or higher when checked are listed.
type Shop struct {
	ID            string   `json:"id"`
	Name          string   `json:"name"`
	City          string   `json:"city"`
	District      string   `json:"district"`
	Address       string   `json:"address"`
	Phone         *string  `json:"phone"`
	GoogleMapsURL string   `json:"google_maps_url"`
	Hours         *string  `json:"hours"`
	Categories    []string `json:"categories"`
	Rating        float64  `json:"rating"`
	RatingCount   *int     `json:"rating_count"`
	CheckedOn     string   `json:"checked_on"`
}

// ShopDataset is the whole shop list with its version.
type ShopDataset struct {
	Version   string    `json:"version"`
	UpdatedAt time.Time `json:"updated_at"`
	Shops     []Shop    `json:"shops"`
}

// ParseShops decodes raw JSON strictly and validates it.
func ParseShops(raw []byte) (ShopDataset, error) {
	var d ShopDataset
	dec := json.NewDecoder(bytes.NewReader(raw))
	dec.DisallowUnknownFields()
	if err := dec.Decode(&d); err != nil {
		return ShopDataset{}, fmt.Errorf("explore: decode shops: %w", err)
	}
	if err := d.Validate(); err != nil {
		return ShopDataset{}, err
	}
	return d, nil
}

// Validate checks every invariant and reports all problems at once.
func (d ShopDataset) Validate() error {
	var errs []error
	add := func(format string, a ...any) { errs = append(errs, fmt.Errorf(format, a...)) }
	if strings.TrimSpace(d.Version) == "" {
		add("shops: version is empty")
	}
	if d.UpdatedAt.IsZero() {
		add("shops: updated_at is empty")
	}
	if len(d.Shops) == 0 {
		add("shops: no shops")
	}
	seen := map[string]bool{}
	for i, s := range d.Shops {
		at := fmt.Sprintf("shops[%d] (%q)", i, s.ID)
		if !slugRe.MatchString(s.ID) {
			add("%s: id must be a lowercase slug", at)
		}
		if seen[s.ID] {
			add("%s: duplicate id", at)
		}
		seen[s.ID] = true
		for field, v := range map[string]string{"name": s.Name, "city": s.City, "address": s.Address} {
			if strings.TrimSpace(v) == "" {
				add("%s: %s is empty", at, field)
			}
		}
		if s.Rating < 4.0 || s.Rating > 5.0 {
			add("%s: rating %.1f is outside 4.0..5.0 (only well-rated shops are listed)", at, s.Rating)
		}
		if s.RatingCount != nil && *s.RatingCount < 0 {
			add("%s: rating_count is negative", at)
		}
		if u, err := url.Parse(s.GoogleMapsURL); err != nil || u.Scheme != "https" || u.Host == "" {
			add("%s: google_maps_url must be an https address", at)
		}
		if s.Phone != nil && !phoneRe.MatchString(*s.Phone) {
			add("%s: phone %q looks wrong", at, *s.Phone)
		}
		if len(s.Categories) == 0 {
			add("%s: no categories", at)
		}
		for _, c := range s.Categories {
			if !slices.Contains(validShopCategories, c) {
				add("%s: unknown category %q", at, c)
			}
		}
		if _, err := time.Parse("2006-01-02", s.CheckedOn); err != nil {
			add("%s: checked_on must be YYYY-MM-DD", at)
		}
	}
	return errors.Join(errs...)
}

// ShopService serves the validated shop list from memory, with a pre-encoded body and ETag.
type ShopService struct {
	dataset ShopDataset
	body    []byte
	etag    string
}

// NewShopService validates d, sorts shops by city then name, and pre-encodes the response.
func NewShopService(d ShopDataset) (*ShopService, error) {
	if err := d.Validate(); err != nil {
		return nil, err
	}
	d.Shops = slices.Clone(d.Shops)
	slices.SortFunc(d.Shops, func(a, b Shop) int {
		if c := strings.Compare(a.City, b.City); c != 0 {
			return c
		}
		return strings.Compare(a.ID, b.ID)
	})
	body, err := json.Marshal(d)
	if err != nil {
		return nil, fmt.Errorf("explore: encode shops: %w", err)
	}
	return &ShopService{dataset: d, body: body, etag: etagOf(body)}, nil
}

// NewDefaultShopService loads the shops embedded in the binary; invalid data stops the server at startup.
func NewDefaultShopService() (*ShopService, error) {
	d, err := ParseShops(embeddedShops)
	if err != nil {
		return nil, err
	}
	return NewShopService(d)
}

func (s *ShopService) Dataset() ShopDataset { return s.dataset }
func (s *ShopService) Body() []byte         { return s.body }
func (s *ShopService) ETag() string         { return s.etag }
