package auth

import (
	"testing"
)

func TestHashPassword_Success(t *testing.T) {
	hash, err := HashPassword("mySecurePass123")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if hash == "" {
		t.Fatal("hash should not be empty")
	}

	if hash == "mySecurePass123" {
		t.Fatal("hash should not equal the plain password")
	}
}

func TestCheckPasswordHash_Valid(t *testing.T) {
	password := "testPass!@#456"
	hash, err := HashPassword(password)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if !CheckPasswordHash(password, hash) {
		t.Fatal("password should match its own hash")
	}
}

func TestCheckPasswordHash_Invalid(t *testing.T) {
	hash, _ := HashPassword("correctPassword")

	if CheckPasswordHash("wrongPassword", hash) {
		t.Fatal("wrong password should not match")
	}
}

func TestHashPassword_DifferentHashesForSameInput(t *testing.T) {
	h1, _ := HashPassword("samePassword")
	h2, _ := HashPassword("samePassword")

	if h1 == h2 {
		t.Fatal("bcrypt should produce different hashes each time due to salting")
	}
}
