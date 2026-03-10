package e2e

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"

	"summitmate/api"
)

// Helper: 註冊並取得一個帶有 Token 且準備好可以呼叫需要 Auth API 的 Client 資訊
type testClientConfig struct {
	Token  string
	UserID string
	Email  string
}

func (s *APITestSuite) setupTestUser() testClientConfig {
	email := randomEmail()
	password := "TestUserPass123!"

	// 註冊
	regPayload, _ := json.Marshal(registerRequest{
		Email:       email,
		Password:    password,
		DisplayName: "Trip 測試者",
	})
	regResp, err := http.Post(s.baseURL+"/auth/register", "application/json", bytes.NewReader(regPayload))
	s.Require().NoError(err)
	defer regResp.Body.Close()

	s.Require().Equal(http.StatusCreated, regResp.StatusCode)

	var authResp authResponse
	json.NewDecoder(regResp.Body).Decode(&authResp)

	s.Require().NotEmpty(authResp.Token)
	s.Require().NotEmpty(authResp.User.ID)

	return testClientConfig{
		Token:  authResp.Token,
		UserID: authResp.User.ID,
		Email:  email,
	}
}

// 發送需要 Auth 的 HTTP Request
func (s *APITestSuite) sendAuthRequest(method, path string, token string, body interface{}) *http.Response {
	var bodyReader *bytes.Reader
	if body != nil {
		b, _ := json.Marshal(body)
		bodyReader = bytes.NewReader(b)
	} else {
		bodyReader = bytes.NewReader([]byte{})
	}

	req, err := http.NewRequest(method, s.baseURL+path, bodyReader)
	s.Require().NoError(err)
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	req.Header.Set("Authorization", "Bearer "+token)

	resp, err := http.DefaultClient.Do(req)
	s.Require().NoError(err)

	if resp.StatusCode >= 400 {
		var bodyBytes []byte
		if resp.Body != nil {
			buf := new(bytes.Buffer)
			buf.ReadFrom(resp.Body)
			bodyBytes = buf.Bytes()
			// recreate body
			resp.Body = io.NopCloser(bytes.NewReader(bodyBytes))
		}
		s.T().Logf("⚠️ HTTP Error %d on %s %s: body=%s", resp.StatusCode, method, path, string(bodyBytes))
	}

	return resp
}

// ============================================================
// Trips CRUD E2E Tests
// ============================================================

func (s *APITestSuite) TestTrip_CreateAndGet() {
	client := s.setupTestUser()

	// 1. 建立 Trip
	endDateStr := time.Now().AddDate(0, 0, 3).Format("2006-01-02")
	createPayload := map[string]interface{}{
		"name":        "百岳挑戰",
		"description": "玉山三天兩夜",
		"start_date":  time.Now().Format("2006-01-02"),
		"end_date":    endDateStr,
		"cover_image": "http://example.com/yushan.jpg",
	}

	resp := s.sendAuthRequest("POST", "/trips", client.Token, createPayload)
	defer resp.Body.Close()
	s.Require().Equal(http.StatusCreated, resp.StatusCode)

	var trip api.Trip
	err := json.NewDecoder(resp.Body).Decode(&trip)
	s.Require().NoError(err)

	s.NotEmpty(trip.Id)
	s.Equal("百岳挑戰", trip.Name)
	s.Equal("玉山三天兩夜", *trip.Description)
	s.Equal("http://example.com/yushan.jpg", *trip.CoverImage)
	s.Equal(client.UserID, trip.UserId.String())
	s.False(trip.IsActive)

	// 2. 獲取單一 Trip
	getResp := s.sendAuthRequest("GET", fmt.Sprintf("/trips/%s", trip.Id.String()), client.Token, nil)
	defer getResp.Body.Close()
	s.Require().Equal(http.StatusOK, getResp.StatusCode)

	var getTrip api.Trip
	json.NewDecoder(getResp.Body).Decode(&getTrip)
	s.Equal(trip.Id, getTrip.Id)
	s.Equal(trip.Name, getTrip.Name)
	s.Equal(*trip.Description, *getTrip.Description)
}

func (s *APITestSuite) TestTrip_ListMyTrips() {
	client := s.setupTestUser()

	// 建立兩筆 Trip
	s.sendAuthRequest("POST", "/trips", client.Token, map[string]interface{}{
		"name": "Trip 1", "start_date": "2026-05-01",
	})
	s.sendAuthRequest("POST", "/trips", client.Token, map[string]interface{}{
		"name": "Trip 2", "start_date": "2026-06-01",
	})

	// List Trips
	resp := s.sendAuthRequest("GET", "/trips", client.Token, nil)
	defer resp.Body.Close()
	s.Require().Equal(http.StatusOK, resp.StatusCode)

	var trips []api.Trip
	err := json.NewDecoder(resp.Body).Decode(&trips)
	s.Require().NoError(err)
	s.Len(trips, 2, "應該回傳兩筆資料")
}

func (s *APITestSuite) TestTrip_Update() {
	client := s.setupTestUser()

	// Create
	createResp := s.sendAuthRequest("POST", "/trips", client.Token, map[string]interface{}{
		"name": "Old Trip Name", "start_date": "2026-05-01",
	})
	var trip api.Trip
	json.NewDecoder(createResp.Body).Decode(&trip)
	createResp.Body.Close()

	// Update
	updatePayload := map[string]interface{}{
		"name":        "New Trip Name",
		"description": "Updated Description",
	}
	updateResp := s.sendAuthRequest("PUT", fmt.Sprintf("/trips/%s", trip.Id.String()), client.Token, updatePayload)
	defer updateResp.Body.Close()
	s.Require().Equal(http.StatusOK, updateResp.StatusCode)

	var updatedTrip api.Trip
	json.NewDecoder(updateResp.Body).Decode(&updatedTrip)
	s.Equal("New Trip Name", updatedTrip.Name)
	s.Equal("Updated Description", *updatedTrip.Description)
}

func (s *APITestSuite) TestTrip_Delete() {
	client := s.setupTestUser()

	// Create
	createResp := s.sendAuthRequest("POST", "/trips", client.Token, map[string]interface{}{
		"name": "To be deleted", "start_date": "2026-05-01",
	})
	var trip api.Trip
	json.NewDecoder(createResp.Body).Decode(&trip)
	createResp.Body.Close()

	// Delete
	deleteResp := s.sendAuthRequest("DELETE", fmt.Sprintf("/trips/%s", trip.Id.String()), client.Token, nil)
	defer deleteResp.Body.Close()
	s.Require().Equal(http.StatusNoContent, deleteResp.StatusCode)

	// Get again to ensure it's deleted
	getResp := s.sendAuthRequest("GET", fmt.Sprintf("/trips/%s", trip.Id.String()), client.Token, nil)
	defer getResp.Body.Close()
	s.Require().Equal(http.StatusNotFound, getResp.StatusCode)
}

// ============================================================
// Trip Members E2E Tests
// ============================================================

func (s *APITestSuite) TestTrip_Members() {
	ownerClient := s.setupTestUser()
	targetClient := s.setupTestUser()

	// 1. Owner creates trip
	createResp := s.sendAuthRequest("POST", "/trips", ownerClient.Token, map[string]interface{}{
		"name": "Member Test Trip", "start_date": "2026-05-01",
	})
	var trip api.Trip
	json.NewDecoder(createResp.Body).Decode(&trip)
	createResp.Body.Close()

	tripID := trip.Id.String()

	// 2. Add member (targetClient Email)
	addPayload := map[string]interface{}{
		"email": targetClient.Email,
	}
	addResp := s.sendAuthRequest("POST", fmt.Sprintf("/trips/%s/members", tripID), ownerClient.Token, addPayload)
	defer addResp.Body.Close()
	s.Require().Equal(http.StatusCreated, addResp.StatusCode)

	// 3. List members
	listResp := s.sendAuthRequest("GET", fmt.Sprintf("/trips/%s/members", tripID), ownerClient.Token, nil)
	defer listResp.Body.Close()
	s.Require().Equal(http.StatusOK, listResp.StatusCode)

	var members []api.TripMember
	json.NewDecoder(listResp.Body).Decode(&members)

	// Ensure targetClient is in the list
	found := false
	for _, m := range members {
		if m.UserId.String() == targetClient.UserID {
			found = true
			break
		}
	}
	s.True(found, "應該在成員列表中找到剛加入的 UserID")

	// 4. Remove member
	removeResp := s.sendAuthRequest("DELETE", fmt.Sprintf("/trips/%s/members/%s", tripID, targetClient.UserID), ownerClient.Token, nil)
	defer removeResp.Body.Close()
	s.Require().Equal(http.StatusNoContent, removeResp.StatusCode)
}

// ============================================================
// Itinerary E2E Tests
// ============================================================

func (s *APITestSuite) TestTrip_Itinerary() {
	client := s.setupTestUser()

	// 1. Create trip
	createResp := s.sendAuthRequest("POST", "/trips", client.Token, map[string]interface{}{
		"name": "Itinerary Test Trip", "start_date": "2026-05-01",
	})
	var trip api.Trip
	json.NewDecoder(createResp.Body).Decode(&trip)
	createResp.Body.Close()
	tripID := trip.Id.String()

	// 2. Add Itinerary Item
	itemPayload := map[string]interface{}{
		"name":     "登上主峰",
		"day":      "1",
		"est_time": "06:00",
		"note":     "Itinerary Note",
	}
	addResp := s.sendAuthRequest("POST", fmt.Sprintf("/trips/%s/itinerary", tripID), client.Token, itemPayload)
	defer addResp.Body.Close()
	s.Require().Equal(http.StatusCreated, addResp.StatusCode)

	var item struct {
		Id   string `json:"id"`
		Name string `json:"name"`
	}
	json.NewDecoder(addResp.Body).Decode(&item)
	s.NotEmpty(item.Id)
	itemID := item.Id

	// 3. List Itinerary Items
	listResp := s.sendAuthRequest("GET", fmt.Sprintf("/trips/%s/itinerary", tripID), client.Token, nil)
	defer listResp.Body.Close()
	s.Require().Equal(http.StatusOK, listResp.StatusCode)

	var items []map[string]interface{}
	json.NewDecoder(listResp.Body).Decode(&items)
	s.Len(items, 1)
	s.Equal("登上主峰", items[0]["name"])

	// 4. Update Itinerary Item
	updatePayload := map[string]interface{}{
		"name": "改成登上前峰",
		"day":  "2",
		"est_time": "07:00",
	}
	updateResp := s.sendAuthRequest("PUT", fmt.Sprintf("/trips/%s/itinerary/%s", tripID, itemID), client.Token, updatePayload)
	defer updateResp.Body.Close()
	s.Require().Equal(http.StatusOK, updateResp.StatusCode)

	// Double check the update value
	listResp2 := s.sendAuthRequest("GET", fmt.Sprintf("/trips/%s/itinerary", tripID), client.Token, nil)
	var updatedItems []map[string]interface{}
	json.NewDecoder(listResp2.Body).Decode(&updatedItems)
	listResp2.Body.Close()
	s.Equal("改成登上前峰", updatedItems[0]["name"])
	s.Equal("2", updatedItems[0]["day"])

	// 5. Delete Itinerary Item
	deleteResp := s.sendAuthRequest("DELETE", fmt.Sprintf("/trips/%s/itinerary/%s", tripID, itemID), client.Token, nil)
	defer deleteResp.Body.Close()
	s.Require().Equal(http.StatusNoContent, deleteResp.StatusCode)

	// List again should be empty
	listResp3 := s.sendAuthRequest("GET", fmt.Sprintf("/trips/%s/itinerary", tripID), client.Token, nil)
	defer listResp3.Body.Close()
	var finalItems []map[string]interface{}
	json.NewDecoder(listResp3.Body).Decode(&finalItems)
	s.Len(finalItems, 0)
}
