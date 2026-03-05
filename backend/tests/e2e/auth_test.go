package e2e

import (
	"bytes"
	"encoding/json"
	"fmt"
	"math/rand"
	"net/http"
	"testing"
	"time"
)

const baseURL = "http://localhost:8080/api/v1"

type registerRequest struct {
	Email       string `json:"email"`
	Password    string `json:"password"`
	DisplayName string `json:"display_name"`
}

type loginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

type authResponse struct {
	Token string `json:"token"`
	User  struct {
		ID          string `json:"id"`
		Email       string `json:"email"`
		DisplayName string `json:"display_name"`
		Avatar      string `json:"avatar"`
		IsActive    bool   `json:"is_active"`
		IsVerified  bool   `json:"is_verified"`
		Role        string `json:"role"`
	} `json:"user"`
}

type errorResponse struct {
	Message string `json:"message"`
}

func randomEmail() string {
	return fmt.Sprintf("test_%d_%d@example.com", time.Now().UnixNano(), rand.Intn(10000))
}

// ============================================================
// Health Check
// ============================================================

func TestHealthCheck(t *testing.T) {
	resp, err := http.Get(baseURL + "/health")
	if err != nil {
		t.Fatalf("Failed to call health endpoint: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Fatalf("Expected 200, got %d", resp.StatusCode)
	}

	var body map[string]string
	json.NewDecoder(resp.Body).Decode(&body)

	if body["status"] != "ok" {
		t.Errorf("Expected status=ok, got=%s", body["status"])
	}
	t.Logf("✅ Health: status=%s, version=%s", body["status"], body["version"])
}

// ============================================================
// Register
// ============================================================

func TestRegister_Success(t *testing.T) {
	email := randomEmail()
	payload := registerRequest{
		Email:       email,
		Password:    "Password123!",
		DisplayName: "Test User",
	}

	body, _ := json.Marshal(payload)
	resp, err := http.Post(baseURL+"/auth/register", "application/json", bytes.NewReader(body))
	if err != nil {
		t.Fatalf("Register request failed: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusCreated {
		var errResp errorResponse
		json.NewDecoder(resp.Body).Decode(&errResp)
		t.Fatalf("Expected 201, got %d: %s", resp.StatusCode, errResp.Message)
	}

	var authResp authResponse
	json.NewDecoder(resp.Body).Decode(&authResp)

	if authResp.Token == "" {
		t.Fatal("Token should not be empty")
	}
	if authResp.User.Email != email {
		t.Errorf("Expected email=%s, got=%s", email, authResp.User.Email)
	}
	if authResp.User.DisplayName != "Test User" {
		t.Errorf("Expected display_name=Test User, got=%s", authResp.User.DisplayName)
	}
	if authResp.User.ID == "" {
		t.Fatal("User ID should not be empty")
	}

	t.Logf("✅ Register: id=%s, email=%s, token=%s...", authResp.User.ID, authResp.User.Email, authResp.Token[:20])
}

func TestRegister_DuplicateEmail(t *testing.T) {
	email := randomEmail()
	payload := registerRequest{
		Email:       email,
		Password:    "Password123!",
		DisplayName: "User One",
	}

	body, _ := json.Marshal(payload)

	// First registration
	resp, _ := http.Post(baseURL+"/auth/register", "application/json", bytes.NewReader(body))
	resp.Body.Close()

	// Second registration with same email
	body, _ = json.Marshal(payload)
	resp2, err := http.Post(baseURL+"/auth/register", "application/json", bytes.NewReader(body))
	if err != nil {
		t.Fatalf("Second register request failed: %v", err)
	}
	defer resp2.Body.Close()

	if resp2.StatusCode != http.StatusBadRequest {
		t.Fatalf("Expected 400 for duplicate email, got %d", resp2.StatusCode)
	}

	var errResp errorResponse
	json.NewDecoder(resp2.Body).Decode(&errResp)
	t.Logf("✅ Duplicate blocked: %s", errResp.Message)
}

func TestRegister_ShortPassword(t *testing.T) {
	payload := registerRequest{
		Email:       randomEmail(),
		Password:    "short",
		DisplayName: "User",
	}

	body, _ := json.Marshal(payload)
	resp, err := http.Post(baseURL+"/auth/register", "application/json", bytes.NewReader(body))
	if err != nil {
		t.Fatalf("Request failed: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusBadRequest {
		t.Fatalf("Expected 400 for short password, got %d", resp.StatusCode)
	}
	t.Log("✅ Short password rejected")
}

// ============================================================
// Login
// ============================================================

func TestLogin_Success(t *testing.T) {
	email := randomEmail()
	password := "MySecurePass99!"

	// Register first
	regPayload, _ := json.Marshal(registerRequest{
		Email: email, Password: password, DisplayName: "Login Tester",
	})
	regResp, _ := http.Post(baseURL+"/auth/register", "application/json", bytes.NewReader(regPayload))
	regResp.Body.Close()

	// Login
	loginPayload, _ := json.Marshal(loginRequest{Email: email, Password: password})
	resp, err := http.Post(baseURL+"/auth/login", "application/json", bytes.NewReader(loginPayload))
	if err != nil {
		t.Fatalf("Login request failed: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		var errResp errorResponse
		json.NewDecoder(resp.Body).Decode(&errResp)
		t.Fatalf("Expected 200, got %d: %s", resp.StatusCode, errResp.Message)
	}

	var authResp authResponse
	json.NewDecoder(resp.Body).Decode(&authResp)

	if authResp.Token == "" {
		t.Fatal("Token should not be empty")
	}
	if authResp.User.Email != email {
		t.Errorf("Expected email=%s, got=%s", email, authResp.User.Email)
	}
	t.Logf("✅ Login: email=%s, token=%s...", authResp.User.Email, authResp.Token[:20])
}

func TestLogin_WrongPassword(t *testing.T) {
	email := randomEmail()

	// Register
	regPayload, _ := json.Marshal(registerRequest{
		Email: email, Password: "CorrectPassword1!", DisplayName: "Wrong Pass User",
	})
	regResp, _ := http.Post(baseURL+"/auth/register", "application/json", bytes.NewReader(regPayload))
	regResp.Body.Close()

	// Login with wrong password
	loginPayload, _ := json.Marshal(loginRequest{Email: email, Password: "WrongPassword1!"})
	resp, err := http.Post(baseURL+"/auth/login", "application/json", bytes.NewReader(loginPayload))
	if err != nil {
		t.Fatalf("Login request failed: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusUnauthorized {
		t.Fatalf("Expected 401, got %d", resp.StatusCode)
	}
	t.Log("✅ Wrong password correctly rejected")
}

func TestLogin_NonExistentUser(t *testing.T) {
	loginPayload, _ := json.Marshal(loginRequest{
		Email: "nonexistent@example.com", Password: "SomePassword1!",
	})
	resp, err := http.Post(baseURL+"/auth/login", "application/json", bytes.NewReader(loginPayload))
	if err != nil {
		t.Fatalf("Login request failed: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusUnauthorized {
		t.Fatalf("Expected 401, got %d", resp.StatusCode)
	}
	t.Log("✅ Non-existent user correctly rejected")
}

// ============================================================
// Get Current User (/auth/me)
// ============================================================

func TestGetMe_WithValidToken(t *testing.T) {
	email := randomEmail()
	password := "TokenTestPass1!"

	// Register
	regPayload, _ := json.Marshal(registerRequest{
		Email: email, Password: password, DisplayName: "Me Tester",
	})
	regResp, _ := http.Post(baseURL+"/auth/register", "application/json", bytes.NewReader(regPayload))
	var authResp authResponse
	json.NewDecoder(regResp.Body).Decode(&authResp)
	regResp.Body.Close()

	// Call /auth/me
	req, _ := http.NewRequest("GET", baseURL+"/auth/me", nil)
	req.Header.Set("Authorization", "Bearer "+authResp.Token)

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatalf("Get me request failed: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		var errResp errorResponse
		json.NewDecoder(resp.Body).Decode(&errResp)
		t.Fatalf("Expected 200, got %d: %s", resp.StatusCode, errResp.Message)
	}

	var user struct {
		ID          string `json:"id"`
		Email       string `json:"email"`
		DisplayName string `json:"display_name"`
	}
	json.NewDecoder(resp.Body).Decode(&user)

	if user.Email != email {
		t.Errorf("Expected email=%s, got=%s", email, user.Email)
	}
	t.Logf("✅ GetMe: id=%s, email=%s, name=%s", user.ID, user.Email, user.DisplayName)
}

func TestGetMe_WithoutToken(t *testing.T) {
	resp, err := http.Get(baseURL + "/auth/me")
	if err != nil {
		t.Fatalf("Get me request failed: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusUnauthorized {
		t.Fatalf("Expected 401, got %d", resp.StatusCode)
	}
	t.Log("✅ GetMe without token correctly rejected")
}
