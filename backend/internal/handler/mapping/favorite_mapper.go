package mapping

import (
	"summitmate/api"
	"summitmate/internal/model"

	"github.com/google/uuid"
)

// ToFavoriteResponse converts model.Favorite to api.Favorite
func ToFavoriteResponse(f *model.Favorite) api.Favorite {
	return api.Favorite{
		Id:        uuid.MustParse(f.ID),
		TargetId:  uuid.MustParse(f.TargetID),
		Type:      f.Type,
		CreatedAt: f.CreatedAt,
		CreatedBy: uuid.MustParse(f.CreatedBy),
		UpdatedAt: f.UpdatedAt,
		UpdatedBy: uuid.MustParse(f.UpdatedBy),
	}
}
