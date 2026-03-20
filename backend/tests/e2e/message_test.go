package e2e

import (
	"encoding/json"
	"fmt"
	"net/http"

	"summitmate/api"
)

func (s *APITestSuite) TestMessage_CRUD() {
	token, _ := s.registerAndLogin("留言測試者")
	tripID := s.createTripForTest(token)

	// 1. 列出留言（應為空）
	resp := s.sendAuthRequest("GET", fmt.Sprintf("/trips/%s/messages", tripID), token, nil)
	defer resp.Body.Close()
	s.Equal(http.StatusOK, resp.StatusCode)

	// 2. 新增留言
	c1 := "general"
	reqMsg := api.MessageRequest{Content: "第一則測試留言", Category: &c1}
	resp = s.sendAuthRequest("POST", fmt.Sprintf("/trips/%s/messages", tripID), token, reqMsg)
	defer resp.Body.Close()
	s.Equal(http.StatusCreated, resp.StatusCode)

	var createdMsg api.Message
	json.NewDecoder(resp.Body).Decode(&createdMsg)
	msgID := createdMsg.Id.String()
	s.Equal("第一則測試留言", createdMsg.Content)

	// 3. 更新留言
	c2 := "important"
	updMsg := api.MessageRequest{Content: "更新後的留言", Category: &c2}
	resp = s.sendAuthRequest("PUT", fmt.Sprintf("/trips/%s/messages/%s", tripID, msgID), token, updMsg)
	defer resp.Body.Close()
	s.Equal(http.StatusOK, resp.StatusCode)

	// 4. 再次列出
	resp = s.sendAuthRequest("GET", fmt.Sprintf("/trips/%s/messages", tripID), token, nil)
	defer resp.Body.Close()
	var messages []api.Message
	json.NewDecoder(resp.Body).Decode(&messages)
	s.Len(messages, 1)

	// 5. 刪除
	resp = s.sendAuthRequest("DELETE", fmt.Sprintf("/trips/%s/messages/%s", tripID, msgID), token, nil)
	defer resp.Body.Close()
	s.Equal(http.StatusNoContent, resp.StatusCode)
}

func (s *APITestSuite) TestMessage_Reply() {
	token, _ := s.registerAndLogin("回覆測試者")
	tripID := s.createTripForTest(token)

	// 建立父留言
	req1 := api.MessageRequest{Content: "父留言"}
	resp := s.sendAuthRequest("POST", fmt.Sprintf("/trips/%s/messages", tripID), token, req1)
	defer resp.Body.Close()
	var parent api.Message
	json.NewDecoder(resp.Body).Decode(&parent)
	parentID := parent.Id

	// 建立回覆
	req2 := api.MessageRequest{Content: "這是回覆", ParentId: &parentID}
	resp = s.sendAuthRequest("POST", fmt.Sprintf("/trips/%s/messages", tripID), token, req2)
	defer resp.Body.Close()
	s.Equal(http.StatusCreated, resp.StatusCode)

	// 驗證巢狀結構
	resp = s.sendAuthRequest("GET", fmt.Sprintf("/trips/%s/messages", tripID), token, nil)
	defer resp.Body.Close()
	var msgs []api.Message
	json.NewDecoder(resp.Body).Decode(&msgs)
	s.Len(msgs, 1)
	s.Require().NotNil(msgs[0].Replies)
	s.Len(*msgs[0].Replies, 1)
}
