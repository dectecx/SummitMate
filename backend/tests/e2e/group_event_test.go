package e2e

import (
	"encoding/json"
	"fmt"
	"net/http"
)

func (s *APITestSuite) TestGroupEvent_CRUD() {
	token, _ := s.registerAndLogin("活動測試者")

	// 1. 建立活動
	resp := s.doRequest("POST", fmt.Sprintf("%s/group-events", s.baseURL),
		map[string]interface{}{
			"title":             "登山口集合點",
			"description":       "大家在登山口集合一起出發",
			"location":          "玉山登山口",
			"start_date":        "2026-05-20",
			"max_members":       15,
			"approval_required": false,
		}, token)
	defer resp.Body.Close()

	var event map[string]interface{}
	json.NewDecoder(resp.Body).Decode(&event)
	s.Require().Equal(http.StatusCreated, resp.StatusCode, fmt.Sprintf("期望 201 但得到 %d, body: %+v", resp.StatusCode, event))
	eventID := event["id"].(string)
	s.Equal("登山口集合點", event["title"])

	// 2. 取得活動列表
	resp = s.doRequest("GET", fmt.Sprintf("%s/group-events", s.baseURL), nil, "")
	defer resp.Body.Close()
	s.Equal(http.StatusOK, resp.StatusCode)

	var events []map[string]interface{}
	json.NewDecoder(resp.Body).Decode(&events)
	s.NotEmpty(events)

	// 3. 申請加入 (用另一個使用者)
	token2, _ := s.registerAndLogin("報名者A")
	resp = s.doRequest("POST", fmt.Sprintf("%s/group-events/%s/apply", s.baseURL, eventID),
		map[string]string{"message": "我想加入！"}, token2)
	defer resp.Body.Close()
	s.Equal(http.StatusCreated, resp.StatusCode)

	// 4. 留言
	resp = s.doRequest("POST", fmt.Sprintf("%s/group-events/%s/comments", s.baseURL, eventID),
		map[string]string{"content": "那天天氣會好嗎？"}, token2)
	defer resp.Body.Close()
	s.Equal(http.StatusCreated, resp.StatusCode)

	var comment map[string]interface{}
	json.NewDecoder(resp.Body).Decode(&comment)
	commentID := comment["id"].(string)

	// 5. 按讚
	resp = s.doRequest("POST", fmt.Sprintf("%s/group-events/%s/like", s.baseURL, eventID), nil, token2)
	defer resp.Body.Close()
	s.Equal(http.StatusOK, resp.StatusCode)

	var likeResp map[string]bool
	json.NewDecoder(resp.Body).Decode(&likeResp)
	s.True(likeResp["is_liked"])

	// 6. 刪除留言
	resp = s.doRequest("DELETE", fmt.Sprintf("%s/group-events/comments/%s", s.baseURL, commentID), nil, token2)
	defer resp.Body.Close()
	s.Equal(http.StatusNoContent, resp.StatusCode)

	// 7. 刪除活動 (回到測試者)
	resp = s.doRequest("DELETE", fmt.Sprintf("%s/group-events/%s", s.baseURL, eventID), nil, token)
	defer resp.Body.Close()
	s.Equal(http.StatusNoContent, resp.StatusCode)
}
