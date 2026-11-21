package explore

import (
	"encoding/json"
	"fmt"
	"slices"
)

// Service holds the validated, sorted dataset in memory together with its pre-encoded JSON and ETag.
type Service struct {
	dataset Dataset
	body    []byte
	etag    string
}

// NewService validates and sorts d (a copy is kept) and pre-encodes the response.
func NewService(d Dataset) (*Service, error) {
	if err := d.Validate(); err != nil {
		return nil, err
	}
	d.Mountains = slices.Clone(d.Mountains)
	sortMountains(d.Mountains)
	body, err := json.Marshal(d)
	if err != nil {
		return nil, fmt.Errorf("explore: encode dataset: %w", err)
	}
	return &Service{dataset: d, body: body, etag: etagOf(body)}, nil
}

// NewServiceFromJSON parses raw JSON (strictly) into a Service.
func NewServiceFromJSON(raw []byte) (*Service, error) {
	d, err := Parse(raw)
	if err != nil {
		return nil, err
	}
	return NewService(d)
}

// NewDefaultService loads the dataset embedded in the binary. It fails when the data is invalid,
// so a bad dataset stops the server at startup instead of reaching users.
func NewDefaultService() (*Service, error) { return NewServiceFromJSON(embeddedData) }

// Dataset returns the dataset (callers must not modify it).
func (s *Service) Dataset() Dataset { return s.dataset }

// Body is the JSON response body (callers must not modify it).
func (s *Service) Body() []byte { return s.body }

// ETag is the strong validator, quoted as it appears in the header.
func (s *Service) ETag() string { return s.etag }
