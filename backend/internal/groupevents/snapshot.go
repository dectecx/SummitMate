package groupevents

import (
	"encoding/json"
	"fmt"
	"unicode/utf8"
)

// Snapshot limits.
const (
	MaxSnapshotNodes = 200
	MaxSnapshotBytes = 64 * 1024
	maxSnapshotName  = 200
	maxSnapshotTime  = 20
)

// normalizeSnapshot validates a client snapshot and returns the JSON to store.
func normalizeSnapshot(s *Snapshot) (json.RawMessage, error) {
	bad := func(format string, a ...any) error { return errSnapshot.WithMessage(fmt.Sprintf(format, a...)) }
	if utf8.RuneCountInString(s.Name) > maxSnapshotName {
		return nil, bad("行程名稱不可超過 200 字")
	}
	if len(s.Itinerary) > MaxSnapshotNodes {
		return nil, bad("行程節點最多 200 個")
	}
	for _, d := range []*string{s.StartDate, s.EndDate} {
		if d != nil {
			if _, err := parseDate(*d); err != nil {
				return nil, bad("行程日期格式必須是 YYYY-MM-DD")
			}
		}
	}
	if s.StartDate != nil && s.EndDate != nil && *s.EndDate < *s.StartDate {
		return nil, bad("行程結束日期不可早於開始日期")
	}
	if s.Itinerary == nil {
		s.Itinerary = []SnapshotNode{}
	}
	for i, n := range s.Itinerary {
		switch {
		case n.Day < 1:
			return nil, bad("第 %d 個節點的天數必須大於或等於 1", i+1)
		case utf8.RuneCountInString(n.Name) > maxSnapshotName:
			return nil, bad("第 %d 個節點的名稱不可超過 200 字", i+1)
		case n.Time != nil && utf8.RuneCountInString(*n.Time) > maxSnapshotTime:
			return nil, bad("第 %d 個節點的時間格式不正確", i+1)
		case n.Lat != nil && (*n.Lat < -90 || *n.Lat > 90):
			return nil, bad("第 %d 個節點的緯度不正確", i+1)
		case n.Lng != nil && (*n.Lng < -180 || *n.Lng > 180):
			return nil, bad("第 %d 個節點的經度不正確", i+1)
		}
	}
	raw, err := json.Marshal(s)
	if err != nil {
		return nil, err
	}
	if len(raw) > MaxSnapshotBytes {
		return nil, bad("行程快照不可超過 64 KB")
	}
	return raw, nil
}
