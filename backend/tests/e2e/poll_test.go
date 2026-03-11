package e2e

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
)

func (s *APITestSuite) TestPoll_CRUD() {
	token, _ := s.registerAndLogin("投票測試者")
	tripID := s.createTripForTest(token)

	// 1. 建立投票
	resp := s.doRequest("POST", fmt.Sprintf("%s/trips/%s/polls", s.baseURL, tripID),
		map[string]interface{}{
			"title":                "午餐吃什麼？",
			"allow_multiple_votes": true,
			"is_allow_add_option":  true,
		}, token)
	defer resp.Body.Close()

	var poll map[string]interface{}
	json.NewDecoder(resp.Body).Decode(&poll)
	s.Require().Equal(http.StatusCreated, resp.StatusCode, fmt.Sprintf("期望 201 但得到 %d, body: %+v", resp.StatusCode, poll))
	pollID := poll["id"].(string)

	// 2. 新增選項
	resp = s.doRequest("POST", fmt.Sprintf("%s/trips/%s/polls/%s/options", s.baseURL, tripID, pollID),
		map[string]string{"text": "便當"}, token)
	defer resp.Body.Close()
	s.Equal(http.StatusCreated, resp.StatusCode)

	// 3. 投票
	var pollWithOpt map[string]interface{}
	bodyBytes, _ := io.ReadAll(resp.Body)
	fmt.Printf("🔎 Poll With Options Response: %s\n", string(bodyBytes))
	json.Unmarshal(bodyBytes, &pollWithOpt)

	options, ok := pollWithOpt["options"].([]interface{})
	s.Require().True(ok, "回傳應包含 options 陣列")
	s.Require().NotEmpty(options, "options 陣列不應為空")
	optionID := options[0].(map[string]interface{})["id"].(string)

	resp = s.doRequest("POST", fmt.Sprintf("%s/trips/%s/polls/%s/options/%s/vote", s.baseURL, tripID, pollID, optionID), nil, token)
	defer resp.Body.Close()
	s.Equal(http.StatusOK, resp.StatusCode)

	// 4. 刪除
	resp = s.doRequest("DELETE", fmt.Sprintf("%s/trips/%s/polls/%s", s.baseURL, tripID, pollID), nil, token)
	defer resp.Body.Close()
	s.Equal(http.StatusNoContent, resp.StatusCode)
}
