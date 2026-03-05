package auth

import (
	"testing"
	"time"
)

const testSecret = "test-secret-key-for-jwt"

func TestGenerateAndParseToken(t *testing.T) {
	tm := NewTokenManager(testSecret)

	userID := "user-123"
	email := "test@example.com"

	token, err := tm.GenerateToken(userID, email, time.Hour)
	if err != nil {
		t.Fatalf("unexpected error generating token: %v", err)
	}
	if token == "" {
		t.Fatal("token should not be empty")
	}

	claims, err := tm.ParseToken(token)
	if err != nil {
		t.Fatalf("unexpected error parsing token: %v", err)
	}

	if claims.UserID != userID {
		t.Errorf("expected user_id=%s, got=%s", userID, claims.UserID)
	}
	if claims.Email != email {
		t.Errorf("expected email=%s, got=%s", email, claims.Email)
	}
}

func TestParseToken_InvalidToken(t *testing.T) {
	tm := NewTokenManager(testSecret)

	_, err := tm.ParseToken("this.is.not.a.valid.token")
	if err == nil {
		t.Fatal("expected error for invalid token")
	}
}

func TestParseToken_ExpiredToken(t *testing.T) {
	tm := NewTokenManager(testSecret)

	// Generate a token that expires immediately
	token, err := tm.GenerateToken("user-123", "test@example.com", -time.Hour)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	_, err = tm.ParseToken(token)
	if err == nil {
		t.Fatal("expected error for expired token")
	}
}

func TestParseToken_WrongSecret(t *testing.T) {
	tm1 := NewTokenManager("secret-one")
	tm2 := NewTokenManager("secret-two")

	token, err := tm1.GenerateToken("user-123", "test@example.com", time.Hour)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	_, err = tm2.ParseToken(token)
	if err == nil {
		t.Fatal("expected error when parsing with wrong secret")
	}
}
