package e2e

import (
	"encoding/json"
	"fmt"
	"net/http"
)

func (s *APITestSuite) TestFavorite_CRUD() {
	token, _ := s.registerAndLogin("收藏測試者")
	tripID := s.createTripForTest(token)

	// 1. 新增收藏
	resp := s.doRequest("POST", s.baseURL+"/favorites",
		map[string]interface{}{"target_id": tripID, "type": "trip"}, token)
	defer resp.Body.Close()
	s.Equal(http.StatusCreated, resp.StatusCode)

	// 2. 列出收藏
	resp = s.doRequest("GET", s.baseURL+"/favorites", nil, token)
	defer resp.Body.Close()
	var favs []map[string]interface{}
	json.NewDecoder(resp.Body).Decode(&favs)
	s.Len(favs, 1)

	// 3. 移除收藏
	resp = s.doRequest("DELETE", fmt.Sprintf("%s/favorites/%s", s.baseURL, tripID), nil, token)
	defer resp.Body.Close()
	s.Equal(http.StatusNoContent, resp.StatusCode)
}
