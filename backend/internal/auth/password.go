package auth

import (
	"crypto/rand"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/hex"
	"math/big"
	"net/mail"
	"strings"
	"unicode"

	"golang.org/x/crypto/bcrypt"

	"summitmate/internal/platform/apperror"
)

// bcrypt silently ignores bytes past 72, so the API limits passwords to 72 bytes.
const maxPasswordBytes = 72

func hashPassword(pw string, cost int) (string, error) {
	b, err := bcrypt.GenerateFromPassword([]byte(pw), cost)
	return string(b), err
}

func checkPassword(pw, hash string) bool {
	return bcrypt.CompareHashAndPassword([]byte(hash), []byte(pw)) == nil
}

func validatePassword(pw string) error {
	if len(pw) < 8 {
		return apperror.ErrPasswordTooShort
	}
	if len(pw) > maxPasswordBytes {
		return apperror.ErrPasswordTooShort.WithMessage("密碼長度不可超過 72 個位元組")
	}
	var letter, digit bool
	for _, r := range pw {
		letter = letter || unicode.IsLetter(r)
		digit = digit || unicode.IsDigit(r)
	}
	if !letter || !digit {
		return apperror.ErrPasswordTooWeak
	}
	return nil
}

// normalizeEmail lowercases and validates an email address.
func normalizeEmail(s string) (string, error) {
	s = strings.ToLower(strings.TrimSpace(s))
	a, err := mail.ParseAddress(s)
	if err != nil || a.Address != s || len(s) > 255 {
		return "", apperror.ErrInvalidEmail
	}
	return s, nil
}

// newVerificationCode returns a random 6-digit code.
func newVerificationCode() (string, error) {
	var sb strings.Builder
	for i := 0; i < 6; i++ {
		n, err := rand.Int(rand.Reader, big.NewInt(10))
		if err != nil {
			return "", err
		}
		sb.WriteByte(byte('0' + n.Int64()))
	}
	return sb.String(), nil
}

func hashCode(userID, code string) string {
	sum := sha256.Sum256([]byte(userID + ":" + code))
	return hex.EncodeToString(sum[:])
}

func codesEqual(a, b string) bool { return subtle.ConstantTimeCompare([]byte(a), []byte(b)) == 1 }
