package e2e

import (
	"encoding/json"
	"fmt"
	"net/http"
)

func (s *APITestSuite) TestMessage_CRUD() {
	token, _ := s.registerAndLogin("留言測試者")
	tripID := s.createTripForTest(token)

	// 1. 列出留言（應為空）
	resp := s.doRequest("GET", fmt.Sprintf("%s/trips/%s/messages", s.baseURL, tripID), nil, token)
	defer resp.Body.Close()
	s.Equal(http.StatusOK, resp.StatusCode)

	// 2. 新增留言
	resp = s.doRequest("POST", fmt.Sprintf("%s/trips/%s/messages", s.baseURL, tripID),
		map[string]interface{}{"content": "第一則測試留言", "category": "general"}, token)
	defer resp.Body.Close()
	s.Equal(http.StatusCreated, resp.StatusCode)

	var createdMsg map[string]interface{}
	json.NewDecoder(resp.Body).Decode(&createdMsg)
	msgID := createdMsg["id"].(string)
	s.Equal("第一則測試留言", createdMsg["content"])

	// 3. 更新留言
	resp = s.doRequest("PUT", fmt.Sprintf("%s/trips/%s/messages/%s", s.baseURL, tripID, msgID),
		map[string]interface{}{"content": "更新後的留言", "category": "important"}, token)
	defer resp.Body.Close()
	s.Equal(http.StatusOK, resp.StatusCode)

	// 4. 再次列出
	resp = s.doRequest("GET", fmt.Sprintf("%s/trips/%s/messages", s.baseURL, tripID), nil, token)
	defer resp.Body.Close()
	var messages []map[string]interface{}
	json.NewDecoder(resp.Body).Decode(&messages)
	s.Len(messages, 1)

	// 5. 刪除
	resp = s.doRequest("DELETE", fmt.Sprintf("%s/trips/%s/messages/%s", s.baseURL, tripID, msgID), nil, token)
	defer resp.Body.Close()
	s.Equal(http.StatusNoContent, resp.StatusCode)
}

func (s *APITestSuite) TestMessage_Reply() {
	token, _ := s.registerAndLogin("回覆測試者")
	tripID := s.createTripForTest(token)

	// 建立父留言
	resp := s.doRequest("POST", fmt.Sprintf("%s/trips/%s/messages", s.baseURL, tripID),
		map[string]interface{}{"content": "父留言"}, token)
	defer resp.Body.Close()
	var parent map[string]interface{}
	json.NewDecoder(resp.Body).Decode(&parent)
	parentID := parent["id"].(string)

	// 建立回覆
	resp = s.doRequest("POST", fmt.Sprintf("%s/trips/%s/messages", s.baseURL, tripID),
		map[string]interface{}{"content": "這是回覆", "parent_id": parentID}, token)
	defer resp.Body.Close()
	s.Equal(http.StatusCreated, resp.StatusCode)

	// 驗證巢狀結構
	resp = s.doRequest("GET", fmt.Sprintf("%s/trips/%s/messages", s.baseURL, tripID), nil, token)
	defer resp.Body.Close()
	var msgs []map[string]interface{}
	json.NewDecoder(resp.Body).Decode(&msgs)
	s.Len(msgs, 1)
	replies := msgs[0]["replies"].([]interface{})
	s.Len(replies, 1)
}
