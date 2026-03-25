package auth

import (
	"crypto/rand"
	"math/big"
)

// GenerateVerificationCode 產生 6 位數的隨機驗證碼。
func GenerateVerificationCode() (string, error) {
	const digits = "0123456789"
	result := make([]byte, 6)
	for i := 0; i < 6; i++ {
		num, err := rand.Int(rand.Reader, big.NewInt(int64(len(digits))))
		if err != nil {
			return "", err
		}
		result[i] = digits[num.Int64()]
	}
	return string(result), nil
}
