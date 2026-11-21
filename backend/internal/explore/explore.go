// Package explore serves read-only mountain reference data for the app's Explore tab.
//
// The dataset is a static JSON file (mountains.json) embedded in the binary and served from memory:
// it is reference data that changes only with a deploy, so there is no database table or migration.
//
// DATA NOTICE: mountains.json is compiled from public sources (see each entry's `sources`). It has NOT been
// reviewed by a human: every entry has verified=false. Mountain information affects hikers' safety, so the
// data MUST be reviewed (elevation, coordinates, difficulty, permit wording) before it is released to users.
// Fields that no consulted source stated are null (name_en, permit) or false (beginner_friendly) on purpose.
package explore

import (
	"bytes"
	"crypto/sha256"
	_ "embed"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"net/url"
	"regexp"
	"slices"
	"strings"
	"time"
)

//go:embed mountains.json
var embeddedData []byte

// Allowed enum values.
const (
	CategoryBaiyue = "baiyue"
	CategoryOther  = "other"
)

var (
	validCategories   = []string{CategoryBaiyue, CategoryOther}
	validDifficulties = []string{"easy", "moderate", "hard", "expert"}
	slugRe            = regexp.MustCompile(`^[a-z0-9]+(-[a-z0-9]+)*$`)
)

// Mountain is one reference entry. JSON names match the API contract.
type Mountain struct {
	ID               string   `json:"id"`
	Name             string   `json:"name"`
	NameEN           *string  `json:"name_en"`
	Elevation        int      `json:"elevation"`
	Region           string   `json:"region"`
	Latitude         float64  `json:"latitude"`
	Longitude        float64  `json:"longitude"`
	Category         string   `json:"category"`
	Difficulty       *string  `json:"difficulty"`
	BeginnerFriendly bool     `json:"beginner_friendly"`
	Summary          string   `json:"summary"`
	Permit           *string  `json:"permit"`
	Verified         bool     `json:"verified"`
	Sources          []string `json:"sources"`
}

// Dataset is the whole file.
type Dataset struct {
	Version   string     `json:"version"`
	UpdatedAt time.Time  `json:"updated_at"`
	Mountains []Mountain `json:"mountains"`
}

// Parse decodes raw JSON strictly (unknown fields are errors) and validates it.
func Parse(raw []byte) (Dataset, error) {
	var d Dataset
	dec := json.NewDecoder(bytes.NewReader(raw))
	dec.DisallowUnknownFields()
	if err := dec.Decode(&d); err != nil {
		return Dataset{}, fmt.Errorf("explore: decode dataset: %w", err)
	}
	if err := d.Validate(); err != nil {
		return Dataset{}, err
	}
	return d, nil
}

// Validate checks every invariant of the dataset and reports all problems at once.
func (d Dataset) Validate() error {
	var errs []error
	add := func(format string, a ...any) { errs = append(errs, fmt.Errorf(format, a...)) }
	if strings.TrimSpace(d.Version) == "" {
		add("version is empty")
	}
	if d.UpdatedAt.IsZero() {
		add("updated_at is empty")
	}
	if len(d.Mountains) == 0 {
		add("no mountains")
	}
	seen := map[string]bool{}
	for i, m := range d.Mountains {
		at := fmt.Sprintf("mountains[%d] (%q)", i, m.ID)
		if !slugRe.MatchString(m.ID) {
			add("%s: id must be a lowercase ascii slug", at)
		}
		if seen[m.ID] {
			add("%s: duplicate id", at)
		}
		seen[m.ID] = true
		if strings.TrimSpace(m.Name) == "" {
			add("%s: name is empty", at)
		}
		if strings.TrimSpace(m.Region) == "" {
			add("%s: region is empty", at)
		}
		if strings.TrimSpace(m.Summary) == "" {
			add("%s: summary is empty", at)
		}
		if m.Elevation < 100 || m.Elevation > 4000 {
			add("%s: elevation %d outside 100..4000", at, m.Elevation)
		}
		if m.Latitude < 21.5 || m.Latitude > 25.5 {
			add("%s: latitude %v outside Taiwan (21.5..25.5)", at, m.Latitude)
		}
		if m.Longitude < 119.5 || m.Longitude > 122.5 {
			add("%s: longitude %v outside Taiwan (119.5..122.5)", at, m.Longitude)
		}
		if !slices.Contains(validCategories, m.Category) {
			add("%s: invalid category %q", at, m.Category)
		}
		if m.Difficulty != nil && !slices.Contains(validDifficulties, *m.Difficulty) {
			add("%s: invalid difficulty %q", at, *m.Difficulty)
		}
		if m.Verified {
			add("%s: verified must be false until a human has reviewed the entry", at)
		}
		if len(m.Sources) == 0 {
			add("%s: sources is empty", at)
		}
		for _, s := range m.Sources {
			if u, err := url.Parse(s); err != nil || (u.Scheme != "http" && u.Scheme != "https") || u.Host == "" {
				add("%s: source %q is not an http(s) URL", at, s)
			}
		}
	}
	return errors.Join(errs...)
}

// sortMountains orders by elevation descending, then id, so output is deterministic.
func sortMountains(ms []Mountain) {
	slices.SortFunc(ms, func(a, b Mountain) int {
		if a.Elevation != b.Elevation {
			return b.Elevation - a.Elevation
		}
		return strings.Compare(a.ID, b.ID)
	})
}

// etagOf derives a strong validator from the content (which includes the dataset version).
func etagOf(body []byte) string {
	sum := sha256.Sum256(body)
	return `"` + hex.EncodeToString(sum[:16]) + `"`
}
