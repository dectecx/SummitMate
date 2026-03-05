package auth

import "golang.org/x/crypto/bcrypt"

// HashPassword 使用 bcrypt 將明文密碼雜湊化。
// cost 設為 14 (高安全性，約 1 秒/次)。
func HashPassword(password string) (string, error) {
	bytes, err := bcrypt.GenerateFromPassword([]byte(password), 14)
	return string(bytes), err
}

// CheckPasswordHash 驗證明文密碼是否與 bcrypt 雜湊值相符。
func CheckPasswordHash(password, hash string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
	return err == nil
}
