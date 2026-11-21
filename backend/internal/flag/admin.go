package flag

import "context"

// AdminChecker 判斷使用者是否具備系統管理員身分。
//
// 以介面注入，避免 flag 套件依賴 auth 套件（auth 已依賴 flag）。
type AdminChecker interface {
	IsAdmin(ctx context.Context, userID string) (bool, error)
}

// dangerousFlags 是會降低系統安全性的旗標，正式環境禁止開啟。
var dangerousFlags = map[string]bool{
	SkipVerificationCode: true,
}
