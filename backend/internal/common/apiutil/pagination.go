package apiutil

import "summitmate/internal/apperror"

// 分頁預設值與上限
const (
	DefaultPage  = 1
	DefaultLimit = 20
	MaxLimit     = 200
)

// NormalizePagination 驗證並正規化分頁參數。
//
// 規則：
//   - page 未提供時預設為 1；limit 未提供時預設為 20。
//   - page 必須 >= 1，否則回傳 400 (ErrInvalidPage)。
//   - limit 必須介於 1 到 200，否則回傳 400 (ErrInvalidLimit)。
func NormalizePagination(page, limit *int) (int, int, error) {
	p := DefaultPage
	if page != nil {
		if *page < 1 {
			return 0, 0, apperror.ErrInvalidPage
		}
		p = *page
	}

	l := DefaultLimit
	if limit != nil {
		if *limit < 1 || *limit > MaxLimit {
			return 0, 0, apperror.ErrInvalidLimit
		}
		l = *limit
	}

	return p, l, nil
}
