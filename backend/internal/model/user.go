package model

import "time"

// User 對應資料庫 users 表的實體。
type User struct {
	ID           string     // UUID 主鍵
	Email        string     // 登入用 Email (唯一)
	PasswordHash string     // bcrypt 雜湊後的密碼
	DisplayName  string     // 顯示名稱
	Avatar       string     // Emoji 頭像 (預設 🐻)
	RoleID       *string    // 角色 ID (FK → roles.id)
	IsActive     bool       // 帳號是否啟用
	IsVerified   bool       // Email 是否已驗證
	LastLoginAt  *time.Time // 最後登入時間 (Nullable)
	CreatedAt    time.Time  // 建立時間
	CreatedBy    *string    // 建立者 ID
	UpdatedAt    time.Time  // 更新時間
	UpdatedBy    *string    // 更新者 ID
}
