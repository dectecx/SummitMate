package e2e

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"

	"summitmate/api"
)

func (s *APITestSuite) TestPoll_CRUD() {
	token, _ := s.registerAndLogin("投票測試者")
	tripID := s.createTripForTest(token)

	// 1. 建立投票
	allowMul := true
	allowAdd := true
	reqBody := api.PollRequest{
		Title:              "午餐吃什麼？",
		AllowMultipleVotes: &allowMul,
		IsAllowAddOption:   &allowAdd,
	}
	resp := s.sendAuthRequest("POST", fmt.Sprintf("/trips/%s/polls", tripID), token, reqBody)
	defer resp.Body.Close()

	var poll api.Poll
	json.NewDecoder(resp.Body).Decode(&poll)
	s.Require().Equal(http.StatusCreated, resp.StatusCode, fmt.Sprintf("期望 201 但得到 %d", resp.StatusCode))
	pollID := poll.Id.String()

	// 2. 新增選項
	optReq := api.PollOptionRequest{Text: "便當"}
	resp = s.sendAuthRequest("POST", fmt.Sprintf("/trips/%s/polls/%s/options", tripID, pollID), token, optReq)
	defer resp.Body.Close()
	s.Equal(http.StatusOK, resp.StatusCode)

	// 3. 投票
	var pollWithOpt api.Poll
	bodyBytes, _ := io.ReadAll(resp.Body)
	fmt.Printf("🔎 Poll With Options Response: %s\n", string(bodyBytes))
	json.Unmarshal(bodyBytes, &pollWithOpt)

	s.Require().NotEmpty(pollWithOpt.Options, "options 陣列不應為空")
	optionID := pollWithOpt.Options[0].Id.String()

	resp = s.sendAuthRequest("POST", fmt.Sprintf("/trips/%s/polls/%s/options/%s/vote", tripID, pollID, optionID), token, nil)
	defer resp.Body.Close()
	s.Equal(http.StatusOK, resp.StatusCode)

	// 4. 刪除
	resp = s.sendAuthRequest("DELETE", fmt.Sprintf("/trips/%s/polls/%s", tripID, pollID), token, nil)
	defer resp.Body.Close()
	s.Equal(http.StatusNoContent, resp.StatusCode)
}
