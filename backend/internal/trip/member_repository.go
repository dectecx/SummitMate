package trip

import (
	"context"
	"fmt"

	"summitmate/internal/database"
)

// TripMemberRepository 定義行程成員資料存取介面。
type TripMemberRepository interface {
	AddMember(ctx context.Context, tripID string, userID string) error
	RemoveMember(ctx context.Context, tripID string, userID string) error
	ListByTripID(ctx context.Context, tripID string) ([]*TripMember, error)
	IsMember(ctx context.Context, tripID string, userID string) (bool, error)
}

type tripMemberRepository struct {
	db database.DB
}

func NewTripMemberRepository(db database.DB) TripMemberRepository {
	return &tripMemberRepository{db: db}
}

// AddMember 新增一位成員到指定行程中。
func (repo *tripMemberRepository) AddMember(ctx context.Context, tripID string, userID string) error {
	query := `
		INSERT INTO trip_members (trip_id, user_id)
		VALUES ($1, $2)
		ON CONFLICT (trip_id, user_id) DO NOTHING
	`
	db := database.GetQuerier(ctx, repo.db)
	_, err := db.Exec(ctx, query, tripID, userID)
	if err != nil {
		return fmt.Errorf("add member %s to trip %s: %w", userID, tripID, err)
	}
	return nil
}

// RemoveMember 從指定行程中移除一位成員。
func (repo *tripMemberRepository) RemoveMember(ctx context.Context, tripID string, userID string) error {
	query := `
		DELETE FROM trip_members
		WHERE trip_id = $1 AND user_id = $2
	`
	db := database.GetQuerier(ctx, repo.db)
	_, err := db.Exec(ctx, query, tripID, userID)
	if err != nil {
		return fmt.Errorf("remove member %s from trip %s: %w", userID, tripID, err)
	}
	return nil
}

// IsMember 回傳指定使用者是否為行程成員。
func (repo *tripMemberRepository) IsMember(ctx context.Context, tripID string, userID string) (bool, error) {
	query := `SELECT EXISTS(SELECT 1 FROM trip_members WHERE trip_id = $1 AND user_id = $2)`
	db := database.GetQuerier(ctx, repo.db)
	var exists bool
	err := db.QueryRow(ctx, query, tripID, userID).Scan(&exists)
	if err != nil {
		return false, fmt.Errorf("check membership for user %s in trip %s: %w", userID, tripID, err)
	}
	return exists, nil
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
	db := database.GetQuerier(ctx, repo.db)
	rows, err := db.Query(ctx, query, tripID)
	if err != nil {
		return nil, fmt.Errorf("query trip members for trip %s: %w", tripID, err)
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
			return nil, fmt.Errorf("scan trip member row: %w", err)
		}
		members = append(members, &m)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate trip member rows: %w", err)
	}
	return members, nil
}
