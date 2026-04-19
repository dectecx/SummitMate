package trip

import (
	"context"

	"github.com/jackc/pgx/v5/pgxpool"
)

// TripMemberRepository 定義行程成員資料存取介面。
type TripMemberRepository interface {
	AddMember(ctx context.Context, tripID string, userID string) error
	RemoveMember(ctx context.Context, tripID string, userID string) error
	ListByTripID(ctx context.Context, tripID string) ([]*TripMember, error)
}

type tripMemberRepository struct {
	pool *pgxpool.Pool
}

func NewTripMemberRepository(pool *pgxpool.Pool) TripMemberRepository {
	return &tripMemberRepository{pool: pool}
}

// AddMember 新增一位成員到指定行程中。
func (repo *tripMemberRepository) AddMember(ctx context.Context, tripID string, userID string) error {
	query := `
		INSERT INTO trip_members (trip_id, user_id)
		VALUES ($1, $2)
		ON CONFLICT (trip_id, user_id) DO NOTHING
	`
	_, err := repo.pool.Exec(ctx, query, tripID, userID)
	return err
}

// RemoveMember 從指定行程中移除一位成員。
func (repo *tripMemberRepository) RemoveMember(ctx context.Context, tripID string, userID string) error {
	query := `
		DELETE FROM trip_members
		WHERE trip_id = $1 AND user_id = $2
	`
	_, err := repo.pool.Exec(ctx, query, tripID, userID)
	return err
}

// ListByTripID 取得行程的所有成員，同時結合 users 表的顯示名稱與 Email 等資訊。
func (repo *tripMemberRepository) ListByTripID(ctx context.Context, tripID string) ([]*TripMember, error) {
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

	var members []*TripMember
	for rows.Next() {
		var m TripMember
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
