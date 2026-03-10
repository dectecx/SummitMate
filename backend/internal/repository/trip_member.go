package repository

import (
	"context"

	"github.com/jackc/pgx/v5/pgxpool"

	"summitmate/internal/model"
)

// TripMemberRepository 封裝 trip_members 表的資料庫存取操作。
type TripMemberRepository struct {
	pool *pgxpool.Pool
}

// NewTripMemberRepository 建立 TripMemberRepository 實例。
func NewTripMemberRepository(pool *pgxpool.Pool) *TripMemberRepository {
	return &TripMemberRepository{pool: pool}
}

// AddMember 新增一位成員到指定行程中。
func (repo *TripMemberRepository) AddMember(ctx context.Context, tripID string, userID string) error {
	query := `
		INSERT INTO trip_members (trip_id, user_id)
		VALUES ($1, $2)
		ON CONFLICT (trip_id, user_id) DO NOTHING
	`
	_, err := repo.pool.Exec(ctx, query, tripID, userID)
	return err
}

// RemoveMember 從指定行程中移除一位成員。
func (repo *TripMemberRepository) RemoveMember(ctx context.Context, tripID string, userID string) error {
	query := `
		DELETE FROM trip_members
		WHERE trip_id = $1 AND user_id = $2
	`
	_, err := repo.pool.Exec(ctx, query, tripID, userID)
	return err
}

// ListByTripID 取得行程的所有成員，同時結合 users 表的顯示名稱與 Email 等資訊。
func (repo *TripMemberRepository) ListByTripID(ctx context.Context, tripID string) ([]*model.TripMember, error) {
	query := `
		SELECT tm.trip_id, tm.user_id, tm.joined_at, u.email, u.display_name, u.avatar
		FROM trip_members tm
		JOIN users u ON tm.user_id = u.id
		WHERE tm.trip_id = $1
		ORDER BY tm.joined_at ASC
	`
	rows, err := repo.pool.Query(ctx, query, tripID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var members []*model.TripMember
	for rows.Next() {
		var m model.TripMember
		err := rows.Scan(
			&m.TripID, &m.UserID, &m.JoinedAt,
			&m.UserEmail, &m.UserDisplayName, &m.UserAvatar,
		)
		if err != nil {
			return nil, err
		}
		members = append(members, &m)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}
	return members, nil
}
