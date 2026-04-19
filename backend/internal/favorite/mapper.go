package favorite

import (
	"summitmate/api"

	"github.com/google/uuid"
)

// ToFavoriteResponse converts Favorite to api.Favorite
func ToFavoriteResponse(f *Favorite) api.Favorite {
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
