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
// (14 days) so keys are eventually reclaimed by Redis.
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

func (b *redisTokenBlacklist) cutoffKey(userID string) string {
	return fmt.Sprintf("summitmate:auth:blacklist:cutoff:%s", userID)
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

// IsRevoked returns true when the token was issued at or before the user's
// RevokeAll cutoff, or when its digest is present in the sorted set and its
// expiry score is still in the future.
func (b *redisTokenBlacklist) IsRevoked(ctx context.Context, userID, token string, issuedAt time.Time) (bool, error) {
	cutoff, err := b.client.Get(ctx, b.cutoffKey(userID)).Int64()
	switch {
	case err == nil:
		if issuedAt.Unix() <= cutoff {
			return true, nil
		}
	case err != redis.Nil:
		return false, fmt.Errorf("blacklist: read cutoff: %w", err)
	}

	score, err := b.client.ZScore(ctx, b.userKey(userID), tokenDigest(token)).Result()
	if err == redis.Nil {
		return false, nil
	}
	if err != nil {
		return false, fmt.Errorf("blacklist: is-revoked: %w", err)
	}

	return time.Now().Before(time.Unix(int64(score), 0)), nil
}

// RevokeAll stores "now" as the user's cutoff; every token issued at or before
// it is rejected. The key expires after the longest possible token lifetime.
func (b *redisTokenBlacklist) RevokeAll(ctx context.Context, userID string) error {
	if err := b.client.Set(ctx, b.cutoffKey(userID), time.Now().Unix(), maxBlacklistKeyTTL).Err(); err != nil {
		return fmt.Errorf("blacklist: revoke-all: %w", err)
	}
	return nil
}

// Close is a no-op; the Redis client lifecycle is managed by the caller.
func (b *redisTokenBlacklist) Close() error { return nil }
