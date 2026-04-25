package e2e

import (
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"summitmate/api"

	openapi_types "github.com/oapi-codegen/runtime/types"
)

func (s *APITestSuite) TestGroupEvent_CRUD() {
	token, _ := s.registerAndLogin("活動測試者")

	// 1. 建立活動
	maxMem := 15
	apprReq := false
	reqEvent := api.GroupEventRequest{
		Title:            "登山口集合點",
		Description:      "大家在登山口集合一起出發",
		Location:         "玉山登山口",
		StartDate:        openapi_types.Date{Time: time.Date(2026, 5, 20, 0, 0, 0, 0, time.UTC)},
		MaxMembers:       &maxMem,
		ApprovalRequired: &apprReq,
	}

	resp := s.sendAuthRequest("POST", "/group-events", token, reqEvent)
	defer resp.Body.Close()

	var event api.GroupEvent
	json.NewDecoder(resp.Body).Decode(&event)
	s.Require().Equal(http.StatusCreated, resp.StatusCode, fmt.Sprintf("期望 201 但得到 %d", resp.StatusCode))
	eventID := event.Id.String()
	s.Equal("登山口集合點", event.Title)

	// 2. 取得活動列表
	resp = s.sendAuthRequest("GET", "/group-events", "", nil)
	defer resp.Body.Close()
	s.Equal(http.StatusOK, resp.StatusCode)

	var listResp api.GroupEventPaginationResponse
	json.NewDecoder(resp.Body).Decode(&listResp)
	s.NotEmpty(listResp.Items)

	// 3. 申請加入 (用另一個使用者)
	token2, _ := s.registerAndLogin("報名者A")
	msg := "我想加入！"
	reqApp := api.GroupEventApplicationRequest{Message: msg}
	resp = s.sendAuthRequest("POST", fmt.Sprintf("/group-events/%s/apply", eventID), token2, reqApp)
	defer resp.Body.Close()
	s.Equal(http.StatusCreated, resp.StatusCode)

	// 4. 留言
	reqCom := api.GroupEventCommentRequest{Content: "那天天氣會好嗎？"}
	resp = s.sendAuthRequest("POST", fmt.Sprintf("/group-events/%s/comments", eventID), token2, reqCom)
	defer resp.Body.Close()
	s.Equal(http.StatusCreated, resp.StatusCode)

	var comment api.GroupEventComment
	json.NewDecoder(resp.Body).Decode(&comment)
	commentID := comment.Id.String()

	// 5. 按讚
	resp = s.sendAuthRequest("POST", fmt.Sprintf("/group-events/%s/like", eventID), token2, nil)
	defer resp.Body.Close()
	s.Equal(http.StatusOK, resp.StatusCode)

	var likeResp map[string]bool
	json.NewDecoder(resp.Body).Decode(&likeResp)
	s.True(likeResp["is_liked"])

	// 6. 刪除留言
	resp = s.sendAuthRequest("DELETE", fmt.Sprintf("/group-events/comments/%s", commentID), token2, nil)
	defer resp.Body.Close()
	s.Equal(http.StatusNoContent, resp.StatusCode)

	// 7. 刪除活動 (回到測試者)
	resp = s.sendAuthRequest("DELETE", fmt.Sprintf("/group-events/%s", eventID), token, nil)
	defer resp.Body.Close()
	s.Equal(http.StatusNoContent, resp.StatusCode)
}
