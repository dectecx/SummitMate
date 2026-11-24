// Package sync implements the offline-first sync endpoints (pull changes, push operations).
//
// All SQL here is built only from the static table and column names in this file;
// user input is only ever passed as bind parameters.
package sync

import (
	"fmt"
	"math"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"

	"summitmate/internal/gearset"
)

type kind int

const (
	kText kind = iota
	kInt
	kFloat
	kBool
	kDate
	kTime
	kUUID
)

type column struct {
	kind      kind
	nullable  bool
	required  bool // must be present when creating the row (no usable default)
	immutable bool // set at creation, ignored in later patches
}

// access decides who may write an entity.
type access int

const (
	accessRoot     access = iota // trips
	accessMember                 // trip_members
	accessShared                 // trip content: owner or guide
	accessPersonal               // belongs to one member (user_id)
	accessOwner                  // belongs to one user (user_id), no trip involved
	accessAuthor                 // trip_messages: member-written, author edits, author or editor deletes
	accessOption                 // poll_options: editors, or members for options they created
	accessVote                   // poll_votes: deterministic id, only the voter writes
)

type entity struct {
	table  string
	access access
	cols   map[string]column
	// validate checks business rules on the coerced values of a patch (nil = none).
	validate func(vals map[string]any) string
}

var entities = map[string]entity{
	"trips": {table: "trips", access: accessRoot, cols: map[string]column{
		"name":        {kind: kText, required: true},
		"description": {kind: kText},
		"start_date":  {kind: kDate, required: true},
		"end_date":    {kind: kDate, nullable: true},
		"mountain_id": {kind: kText, nullable: true},
		"track":       {kind: kText, nullable: true},
		"cover_image": {kind: kText, nullable: true},
	}},
	"trip_members": {table: "trip_members", access: accessMember, cols: map[string]column{
		"trip_id": {kind: kUUID, required: true, immutable: true},
		"user_id": {kind: kUUID, required: true, immutable: true},
		"role":    {kind: kText},
	}},
	"itinerary_items": {table: "itinerary_items", access: accessShared, cols: map[string]column{
		"trip_id":       {kind: kUUID, required: true, immutable: true},
		"day_index":     {kind: kInt},
		"name":          {kind: kText},
		"est_minutes":   {kind: kInt, nullable: true},
		"altitude":      {kind: kInt},
		"distance":      {kind: kFloat},
		"lat":           {kind: kFloat, nullable: true},
		"lng":           {kind: kFloat, nullable: true},
		"note":          {kind: kText},
		"checked_in_at": {kind: kTime, nullable: true},
	}},
	"gear_items": {table: "gear_items", access: accessPersonal, cols: map[string]column{
		"trip_id":    {kind: kUUID, required: true, immutable: true},
		"name":       {kind: kText},
		"weight":     {kind: kFloat},
		"category":   {kind: kText},
		"quantity":   {kind: kInt},
		"is_checked": {kind: kBool},
		"sort_order": {kind: kInt},
	}},
	"meal_plan_days": {table: "meal_plan_days", access: accessPersonal, cols: map[string]column{
		"trip_id":   {kind: kUUID, required: true, immutable: true},
		"name":      {kind: kText},
		"day_index": {kind: kInt},
	}},
	"meal_items": {table: "meal_items", access: accessPersonal, cols: map[string]column{
		"trip_id":          {kind: kUUID, required: true, immutable: true},
		"meal_plan_day_id": {kind: kUUID, required: true, immutable: true},
		"meal_type":        {kind: kText},
		"name":             {kind: kText},
		"weight":           {kind: kFloat},
		"calories":         {kind: kFloat},
		"quantity":         {kind: kInt},
		"note":             {kind: kText},
	}},
	"library_items": {table: "library_items", access: accessOwner, validate: validateLibraryItem, cols: map[string]column{
		"kind":     {kind: kText, required: true, immutable: true},
		"name":     {kind: kText},
		"category": {kind: kText},
		"weight":   {kind: kFloat},
		"calories": {kind: kFloat},
		"note":     {kind: kText},
	}},
	"templates": {table: "templates", access: accessOwner, validate: validateTemplate, cols: map[string]column{
		"title": {kind: kText},
		"note":  {kind: kText},
		"items": {kind: kText},
	}},
	"trip_messages": {table: "trip_messages", access: accessAuthor, validate: validateMessage, cols: map[string]column{
		"trip_id":   {kind: kUUID, required: true, immutable: true},
		"parent_id": {kind: kUUID, nullable: true, immutable: true},
		"body":      {kind: kText, required: true},
	}},
	"polls": {table: "polls", access: accessShared, validate: validatePoll, cols: map[string]column{
		"trip_id":          {kind: kUUID, required: true, immutable: true},
		"title":            {kind: kText, required: true},
		"description":      {kind: kText},
		"deadline":         {kind: kTime, nullable: true},
		"allow_multiple":   {kind: kBool},
		"allow_add_option": {kind: kBool},
		"blind":            {kind: kBool},
		"status":           {kind: kText},
	}},
	"poll_options": {table: "poll_options", access: accessOption, validate: validatePollOption, cols: map[string]column{
		"poll_id":    {kind: kUUID, required: true, immutable: true},
		"trip_id":    {kind: kUUID, required: true, immutable: true},
		"text":       {kind: kText, required: true},
		"sort_order": {kind: kInt},
	}},
	"poll_votes": {table: "poll_votes", access: accessVote, cols: map[string]column{
		"poll_id":   {kind: kUUID, required: true, immutable: true},
		"option_id": {kind: kUUID, required: true, immutable: true},
		"trip_id":   {kind: kUUID, required: true, immutable: true},
	}},
	"favorites": {table: "favorites", access: accessOwner, validate: validateFavorite, cols: map[string]column{
		"kind":      {kind: kText, required: true, immutable: true},
		"target_id": {kind: kText, required: true, immutable: true},
	}},
}

// textLen reports whether v (if present as a string) has 1..max characters.
func textLen(vals map[string]any, key string, max int) bool {
	s, ok := vals[key].(string)
	if !ok {
		return true
	}
	n := utf8.RuneCountInString(s)
	return n >= 1 && n <= max
}

func validateMessage(vals map[string]any) string {
	if !textLen(vals, "body", 1000) {
		return "留言內容需為 1～1000 字"
	}
	return ""
}

func validatePoll(vals map[string]any) string {
	if !textLen(vals, "title", 200) {
		return "投票標題需為 1～200 字"
	}
	if st, ok := vals["status"].(string); ok && st != "open" && st != "closed" {
		return "status must be open or closed"
	}
	return ""
}

func validatePollOption(vals map[string]any) string {
	if !textLen(vals, "text", 100) {
		return "選項需為 1～100 字"
	}
	return ""
}

func validateFavorite(vals map[string]any) string {
	if k, ok := vals["kind"].(string); ok && k != "mountain" && k != "group_event" {
		return "kind must be mountain or group_event"
	}
	if !textLen(vals, "target_id", 100) {
		return "target_id must be 1 to 100 characters"
	}
	return ""
}

// validateLibraryItem checks library_items values.
func validateLibraryItem(vals map[string]any) string {
	if k, ok := vals["kind"].(string); ok && k != gearset.KindGear && k != gearset.KindMeal {
		return "kind must be gear or meal"
	}
	return ""
}

// validateTemplate checks templates values.
func validateTemplate(vals map[string]any) string {
	if t, ok := vals["items"].(string); ok {
		if err := gearset.ValidateJSON(t); err != nil {
			return err.Error()
		}
	}
	return ""
}

// pullOrder is the order entities are returned (parents before children).
var pullOrder = []string{"trips", "trip_members", "itinerary_items", "meal_plan_days", "gear_items", "meal_items", "library_items", "templates",
	"trip_messages", "polls", "poll_options", "poll_votes", "favorites"}

// memberNamespace seeds deterministic trip_members IDs:
// id = UUIDv5(memberNamespace, "<trip_id>:<user_id>"). Clients must use the same rule,
// which lets a removed member be re-invited by reviving the same row.
var memberNamespace = uuid.MustParse("6f1c2a52-6d3a-4f5e-9d9a-3b9d8c0a7e11")

// MemberID returns the deterministic trip_members ID for a (trip, user) pair.
func MemberID(tripID, userID uuid.UUID) uuid.UUID {
	return uuid.NewSHA1(memberNamespace, []byte(tripID.String()+":"+userID.String()))
}

// voteNamespace seeds deterministic poll_votes IDs:
// id = UUIDv5(voteNamespace, "<option_id>:<user_id>"). Clients must use the same rule,
// so retracting and re-voting reuses one row.
var voteNamespace = uuid.MustParse("b3a7d1f4-2c58-4e0a-8f6b-5d1e9c3a7b42")

// VoteID returns the deterministic poll_votes ID for an (option, user) pair.
func VoteID(optionID, userID uuid.UUID) uuid.UUID {
	return uuid.NewSHA1(voteNamespace, []byte(optionID.String()+":"+userID.String()))
}

// coerce converts a decoded JSON value to the Go type pgx should bind for c.
func coerce(c column, v any) (any, error) {
	if v == nil {
		if !c.nullable {
			return nil, fmt.Errorf("must not be null")
		}
		return nil, nil
	}
	switch c.kind {
	case kText:
		s, ok := v.(string)
		if !ok {
			return nil, fmt.Errorf("must be a string")
		}
		return s, nil
	case kInt:
		f, ok := v.(float64)
		if !ok || f != math.Trunc(f) || math.Abs(f) > math.MaxInt32 {
			return nil, fmt.Errorf("must be an integer")
		}
		return int64(f), nil
	case kFloat:
		f, ok := v.(float64)
		if !ok || math.IsNaN(f) || math.IsInf(f, 0) {
			return nil, fmt.Errorf("must be a number")
		}
		return f, nil
	case kBool:
		b, ok := v.(bool)
		if !ok {
			return nil, fmt.Errorf("must be a boolean")
		}
		return b, nil
	case kDate:
		s, ok := v.(string)
		if !ok {
			return nil, fmt.Errorf("must be a YYYY-MM-DD string")
		}
		t, err := time.Parse("2006-01-02", s)
		if err != nil {
			return nil, fmt.Errorf("must be a YYYY-MM-DD string")
		}
		return t, nil
	case kTime:
		s, ok := v.(string)
		if !ok {
			return nil, fmt.Errorf("must be an RFC 3339 timestamp")
		}
		t, err := time.Parse(time.RFC3339Nano, s)
		if err != nil {
			return nil, fmt.Errorf("must be an RFC 3339 timestamp")
		}
		return t, nil
	case kUUID:
		s, ok := v.(string)
		if !ok {
			return nil, fmt.Errorf("must be a UUID")
		}
		u, err := uuid.Parse(s)
		if err != nil {
			return nil, fmt.Errorf("must be a UUID")
		}
		return u, nil
	}
	return nil, fmt.Errorf("unsupported column kind")
}
