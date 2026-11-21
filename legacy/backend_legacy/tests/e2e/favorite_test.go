//go:build integration

package e2e

import (
	"encoding/json"
	"fmt"
	"net/http"

	"summitmate/api"

	"github.com/google/uuid"
)

func (s *APITestSuite) TestFavorite_CRUD() {
	s.Run("Given default context, When calling Favorite CRUD, Then it should perform successfully", func() {
		token, _ := s.registerAndLogin("收藏測試者")
		// 收藏對象為任意 UUID（例如山岳 ID），不一定是行程
		targetID := uuid.NewString()

		// 1. 新增收藏
		reqBody := api.FavoriteRequest{
			TargetId: uuid.MustParse(targetID),
			Type:     api.FavoriteTypeMountain,
		}
		resp := s.sendAuthRequest("POST", "/favorites", token, reqBody)
		defer resp.Body.Close()
		s.Equal(http.StatusCreated, resp.StatusCode)

		var createdFav api.Favorite
		json.NewDecoder(resp.Body).Decode(&createdFav)
		s.Equal(api.FavoriteTypeMountain, createdFav.Type)

		// 2. 列出收藏
		resp = s.sendAuthRequest("GET", "/favorites", token, nil)
		defer resp.Body.Close()
		var listResp api.FavoritePaginationResponse
		json.NewDecoder(resp.Body).Decode(&listResp)
		s.Len(listResp.Items, 1)

		// 3. 移除收藏
		resp = s.sendAuthRequest("DELETE", fmt.Sprintf("/favorites/%s?type=%s", targetID, api.FavoriteTypeMountain), token, nil)
		defer resp.Body.Close()
		s.Equal(http.StatusNoContent, resp.StatusCode)
	})
}
