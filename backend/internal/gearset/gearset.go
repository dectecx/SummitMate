// Package gearset defines the item format shared by templates (sync) and cloud shared sets.
package gearset

import (
	"encoding/json"
	"errors"
	"fmt"
	"math"
	"unicode/utf8"
)

const (
	MaxItems       = 300
	MaxNameRunes   = 200
	MaxCategory    = 50
	MaxNoteRunes   = 1000
	MaxQuantity    = 9999
	MaxDay         = 60
	KindGear       = "gear"
	KindMeal       = "meal"
	maxItemsErrFmt = "items 最多 %d 項"
)

// Item is one gear or meal entry.
type Item struct {
	Kind     string   `json:"kind"`
	Name     string   `json:"name"`
	Category string   `json:"category"`
	Weight   float64  `json:"weight"`
	Quantity int      `json:"quantity"`
	Calories *float64 `json:"calories,omitempty"`
	Day      *int     `json:"day,omitempty"`
	Note     string   `json:"note"`
}

// Validate checks one item.
func (it *Item) Validate() error {
	if it.Kind != KindGear && it.Kind != KindMeal {
		return errors.New("kind 必須是 gear 或 meal")
	}
	if n := utf8.RuneCountInString(it.Name); n == 0 || n > MaxNameRunes {
		return fmt.Errorf("name 長度必須介於 1 到 %d 字", MaxNameRunes)
	}
	if it.Category == "" {
		it.Category = "other"
	}
	if utf8.RuneCountInString(it.Category) > MaxCategory {
		return fmt.Errorf("category 不可超過 %d 字", MaxCategory)
	}
	if bad(it.Weight) || it.Weight < 0 {
		return errors.New("weight 必須是不小於 0 的數字")
	}
	if it.Quantity < 0 || it.Quantity > MaxQuantity {
		return fmt.Errorf("quantity 必須介於 0 到 %d", MaxQuantity)
	}
	if it.Calories != nil && (bad(*it.Calories) || *it.Calories < 0) {
		return errors.New("calories 必須是不小於 0 的數字")
	}
	if it.Day != nil && (*it.Day < 1 || *it.Day > MaxDay) {
		return fmt.Errorf("day 必須介於 1 到 %d", MaxDay)
	}
	if utf8.RuneCountInString(it.Note) > MaxNoteRunes {
		return fmt.Errorf("note 不可超過 %d 字", MaxNoteRunes)
	}
	return nil
}

func bad(f float64) bool { return math.IsNaN(f) || math.IsInf(f, 0) }

// ValidateAll checks a list (1..MaxItems when requireNonEmpty, else 0..MaxItems).
func ValidateAll(items []Item, requireNonEmpty bool) error {
	if len(items) > MaxItems {
		return fmt.Errorf(maxItemsErrFmt, MaxItems)
	}
	if requireNonEmpty && len(items) == 0 {
		return errors.New("items 至少需要 1 項")
	}
	for i := range items {
		if err := items[i].Validate(); err != nil {
			return fmt.Errorf("items[%d] %w", i, err)
		}
	}
	return nil
}

// ValidateJSON checks the JSON text stored in templates.items: an array of at most
// MaxItems objects. Unknown keys are tolerated; known keys must have the right type.
func ValidateJSON(text string) error {
	var arr []map[string]any
	if err := json.Unmarshal([]byte(text), &arr); err != nil {
		return errors.New("items 必須是物件陣列的 JSON")
	}
	if len(arr) > MaxItems {
		return fmt.Errorf(maxItemsErrFmt, MaxItems)
	}
	items := make([]Item, 0, len(arr))
	for i, m := range arr {
		if m == nil {
			return fmt.Errorf("items[%d] 必須是物件", i)
		}
		it, err := fromMap(m)
		if err != nil {
			return fmt.Errorf("items[%d] %w", i, err)
		}
		items = append(items, it)
	}
	return ValidateAll(items, false)
}

func fromMap(m map[string]any) (Item, error) {
	it := Item{Quantity: 1}
	var err error
	if it.Kind, err = str(m, "kind"); err != nil {
		return it, err
	}
	if it.Name, err = str(m, "name"); err != nil {
		return it, err
	}
	if it.Category, err = str(m, "category"); err != nil {
		return it, err
	}
	if it.Note, err = str(m, "note"); err != nil {
		return it, err
	}
	if it.Weight, _, err = num(m, "weight"); err != nil {
		return it, err
	}
	if q, ok, err := num(m, "quantity"); err != nil {
		return it, err
	} else if ok {
		if q != math.Trunc(q) {
			return it, errors.New("quantity 必須是整數")
		}
		it.Quantity = int(q)
	}
	if c, ok, err := num(m, "calories"); err != nil {
		return it, err
	} else if ok {
		it.Calories = &c
	}
	if d, ok, err := num(m, "day"); err != nil {
		return it, err
	} else if ok {
		if d != math.Trunc(d) {
			return it, errors.New("day 必須是整數")
		}
		v := int(d)
		it.Day = &v
	}
	return it, nil
}

func str(m map[string]any, k string) (string, error) {
	v, ok := m[k]
	if !ok || v == nil {
		return "", nil
	}
	s, ok := v.(string)
	if !ok {
		return "", fmt.Errorf("%s 必須是字串", k)
	}
	return s, nil
}

func num(m map[string]any, k string) (float64, bool, error) {
	v, ok := m[k]
	if !ok || v == nil {
		return 0, false, nil
	}
	f, ok := v.(float64)
	if !ok {
		return 0, false, fmt.Errorf("%s 必須是數字", k)
	}
	return f, true, nil
}

// Totals returns total gear weight (weight x quantity) and the gear and meal counts.
func Totals(items []Item) (weight float64, gear, meal int) {
	for _, it := range items {
		if it.Kind == KindGear {
			weight += it.Weight * float64(it.Quantity)
			gear++
		} else {
			meal++
		}
	}
	return
}
