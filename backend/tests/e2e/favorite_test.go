package e2e

import (
	"encoding/json"
	"fmt"
	"net/http"

	"summitmate/api"

	"github.com/google/uuid"
)

func (s *APITestSuite) TestFavorite_CRUD() {
	token, _ := s.registerAndLogin("收藏測試者")
	tripID := s.createTripForTest(token)

	// 1. 新增收藏
	reqBody := api.FavoriteRequest{
		TargetId: uuid.MustParse(tripID),
		Type:     "trip",
	}
	resp := s.sendAuthRequest("POST", "/favorites", token, reqBody)
	defer resp.Body.Close()
	s.Equal(http.StatusCreated, resp.StatusCode)

	var createdFav api.Favorite
	json.NewDecoder(resp.Body).Decode(&createdFav)
	s.Equal("trip", createdFav.Type)

	// 2. 列出收藏
	resp = s.sendAuthRequest("GET", "/favorites", token, nil)
	defer resp.Body.Close()
	var listResp api.FavoritePaginationResponse
	json.NewDecoder(resp.Body).Decode(&listResp)
	s.Len(listResp.Items, 1)

	// 3. 移除收藏
	resp = s.sendAuthRequest("DELETE", fmt.Sprintf("/favorites/%s", tripID), token, nil)
	defer resp.Body.Close()
	s.Equal(http.StatusNoContent, resp.StatusCode)
}
