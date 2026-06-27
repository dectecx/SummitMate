package cache

import (
	"context"
	"crypto/sha256"
	"fmt"
	"time"

	"github.com/redis/go-redis/v9"
)

// maxBlacklistKeyTTL is the safety-net TTL placed on each per-user blacklist
// key. It is set to slightly longer than the maximum refresh token lifetime
// (14 days) so the key is eventually reclaimed by Redis even if RevokeAll is
// never called.
const maxBlacklistKeyTTL = 15 * 24 * time.Hour

type redisTokenBlacklist struct {
	client *redis.Client
}

// NewRedisTokenBlacklist returns a Redis-backed TokenBlacklist that stores
// each user's revoked tokens in a sorted set keyed by expiry timestamp.
func NewRedisTokenBlacklist(client *redis.Client) TokenBlacklist {
	return &redisTokenBlacklist{client: client}
}

func (b *redisTokenBlacklist) userKey(userID string) string {
	return fmt.Sprintf("summitmate:auth:blacklist:user:%s", userID)
}

func tokenDigest(token string) string {
	return fmt.Sprintf("%x", sha256.Sum256([]byte(token)))
}

// Revoke atomically:
//  1. Adds the token digest with score = expiresAt unix timestamp.
//  2. Purges already-expired entries (lazy cleanup).
//  3. Refreshes the key TTL to maxBlacklistKeyTTL.
func (b *redisTokenBlacklist) Revoke(ctx context.Context, userID, token string, expiresAt time.Time) error {
	key := b.userKey(userID)
	digest := tokenDigest(token)
	nowUnix := fmt.Sprintf("%d", time.Now().Unix())

	pipe := b.client.Pipeline()
	pipe.ZAdd(ctx, key, redis.Z{Score: float64(expiresAt.Unix()), Member: digest})
	pipe.ZRemRangeByScore(ctx, key, "-inf", nowUnix)
	pipe.Expire(ctx, key, maxBlacklistKeyTTL)
	_, err := pipe.Exec(ctx)
	if err != nil {
		return fmt.Errorf("blacklist: revoke: %w", err)
	}
	return nil
}

// IsRevoked returns true when the token digest is present in the sorted set
// and its expiry score is still in the future.
func (b *redisTokenBlacklist) IsRevoked(ctx context.Context, userID, token string) (bool, error) {
	key := b.userKey(userID)
	digest := tokenDigest(token)

	score, err := b.client.ZScore(ctx, key, digest).Result()
	if err == redis.Nil {
		return false, nil
	}
	if err != nil {
		return false, fmt.Errorf("blacklist: is-revoked: %w", err)
	}

	expiresAt := time.Unix(int64(score), 0)
	return time.Now().Before(expiresAt), nil
}

// RevokeAll deletes the entire per-user blacklist key, effectively revoking
// all outstanding tokens for that user at once.
func (b *redisTokenBlacklist) RevokeAll(ctx context.Context, userID string) error {
	if err := b.client.Del(ctx, b.userKey(userID)).Err(); err != nil {
		return fmt.Errorf("blacklist: revoke-all: %w", err)
	}
	return nil
}

// Close is a no-op; the Redis client lifecycle is managed by the caller.
func (b *redisTokenBlacklist) Close() error { return nil }
