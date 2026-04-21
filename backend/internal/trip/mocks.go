package trip

import (
	"context"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/stretchr/testify/mock"
)

// MockBeginner is a mock implementation of the database.Beginner interface
type MockBeginner struct {
	mock.Mock
}

func (m *MockBeginner) Begin(ctx context.Context) (pgx.Tx, error) {
	args := m.Called(ctx)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(pgx.Tx), args.Error(1)
}

// MockTx is a minimal mock for pgx.Tx
type MockTx struct {
	mock.Mock
}

func (m *MockTx) Begin(ctx context.Context) (pgx.Tx, error) { return nil, nil }
func (m *MockTx) Commit(ctx context.Context) error        { return m.Called(ctx).Error(0) }
func (m *MockTx) Rollback(ctx context.Context) error      { return m.Called(ctx).Error(0) }
func (m *MockTx) CopyFrom(ctx context.Context, tableName pgx.Identifier, columnNames []string, rowSrc pgx.CopyFromSource) (int64, error) {
	return 0, nil
}
func (m *MockTx) SendBatch(ctx context.Context, b *pgx.Batch) pgx.BatchResults { return nil }
func (m *MockTx) LargeObjects() pgx.LargeObjects              { return pgx.LargeObjects{} }
func (m *MockTx) Prepare(ctx context.Context, name, sql string) (*pgconn.StatementDescription, error) {
	return nil, nil
}
func (m *MockTx) Exec(ctx context.Context, sql string, arguments ...any) (pgconn.CommandTag, error) {
	return pgconn.CommandTag{}, nil
}
func (m *MockTx) Query(ctx context.Context, sql string, args ...any) (pgx.Rows, error) {
	return nil, nil
}
func (m *MockTx) QueryRow(ctx context.Context, sql string, args ...any) pgx.Row {
	return nil
}
func (m *MockTx) Conn() *pgx.Conn { return nil }

// MockTripRepository is a mock implementation of the TripRepository interface
type MockTripRepository struct {
	mock.Mock
}

func (m *MockTripRepository) Create(ctx context.Context, trip *Trip) (*Trip, error) {
	args := m.Called(ctx, trip)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*Trip), args.Error(1)
}

func (m *MockTripRepository) GetByID(ctx context.Context, id string) (*Trip, error) {
	args := m.Called(ctx, id)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*Trip), args.Error(1)
}

func (m *MockTripRepository) ListByUserID(ctx context.Context, userID string) ([]*Trip, error) {
	args := m.Called(ctx, userID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]*Trip), args.Error(1)
}

func (m *MockTripRepository) Update(ctx context.Context, trip *Trip) (*Trip, error) {
	args := m.Called(ctx, trip)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*Trip), args.Error(1)
}

func (m *MockTripRepository) DeleteByID(ctx context.Context, id string) error {
	args := m.Called(ctx, id)
	return args.Error(0)
}

// MockTripMemberRepository is a mock implementation of the TripMemberRepository interface
type MockTripMemberRepository struct {
	mock.Mock
}

func (m *MockTripMemberRepository) AddMember(ctx context.Context, tripID, userID string) error {
	args := m.Called(ctx, tripID, userID)
	return args.Error(0)
}

func (m *MockTripMemberRepository) RemoveMember(ctx context.Context, tripID, userID string) error {
	args := m.Called(ctx, tripID, userID)
	return args.Error(0)
}

func (m *MockTripMemberRepository) IsMember(ctx context.Context, tripID, userID string) (bool, error) {
	args := m.Called(ctx, tripID, userID)
	return args.Bool(0), args.Error(1)
}

func (m *MockTripMemberRepository) ListByTripID(ctx context.Context, tripID string) ([]*TripMember, error) {
	args := m.Called(ctx, tripID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]*TripMember), args.Error(1)
}

// MockItineraryRepository is a mock implementation of the ItineraryRepository interface
type MockItineraryRepository struct {
	mock.Mock
}

func (m *MockItineraryRepository) Create(ctx context.Context, item *ItineraryItem) (*ItineraryItem, error) {
	args := m.Called(ctx, item)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*ItineraryItem), args.Error(1)
}

func (m *MockItineraryRepository) GetByID(ctx context.Context, id string) (*ItineraryItem, error) {
	args := m.Called(ctx, id)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*ItineraryItem), args.Error(1)
}

func (m *MockItineraryRepository) ListByTripID(ctx context.Context, tripID string) ([]*ItineraryItem, error) {
	args := m.Called(ctx, tripID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]*ItineraryItem), args.Error(1)
}

func (m *MockItineraryRepository) Update(ctx context.Context, item *ItineraryItem) (*ItineraryItem, error) {
	args := m.Called(ctx, item)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*ItineraryItem), args.Error(1)
}

func (m *MockItineraryRepository) DeleteByID(ctx context.Context, id string) error {
	args := m.Called(ctx, id)
	return args.Error(0)
}


