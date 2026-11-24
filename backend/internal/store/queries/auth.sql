-- name: CreateUser :one
INSERT INTO users (email, password_hash, display_name, avatar)
VALUES ($1, $2, $3, $4)
RETURNING *;

-- name: GetUserByEmail :one
SELECT * FROM users WHERE email = $1;

-- name: GetUserByID :one
SELECT * FROM users WHERE id = $1;

-- name: MarkUserVerified :exec
UPDATE users SET is_verified = TRUE WHERE id = $1;

-- name: TouchUserLogin :exec
UPDATE users SET last_login_at = clock_timestamp() WHERE id = $1;

-- name: UpdateUserProfile :one
UPDATE users
SET display_name = COALESCE(sqlc.narg('display_name'), display_name),
    avatar       = COALESCE(sqlc.narg('avatar'), avatar)
WHERE id = $1
RETURNING *;

-- name: UpdateUserPassword :exec
UPDATE users SET password_hash = $2 WHERE id = $1;

-- name: DeactivateUser :exec
UPDATE users SET is_active = FALSE WHERE id = $1;

-- name: UpsertVerification :exec
INSERT INTO email_verifications (user_id, code_hash, expires_at, attempts)
VALUES ($1, $2, $3, 0)
ON CONFLICT (user_id) DO UPDATE
SET code_hash = EXCLUDED.code_hash, expires_at = EXCLUDED.expires_at, attempts = 0, created_at = clock_timestamp();

-- name: GetVerification :one
SELECT * FROM email_verifications WHERE user_id = $1;

-- name: IncrementVerificationAttempts :one
UPDATE email_verifications SET attempts = attempts + 1 WHERE user_id = $1 RETURNING attempts;

-- name: DeleteVerification :exec
DELETE FROM email_verifications WHERE user_id = $1;

-- name: CreateRefreshToken :one
INSERT INTO refresh_tokens (user_id, token_hash, expires_at)
VALUES ($1, $2, $3)
RETURNING *;

-- name: GetRefreshTokenByHash :one
SELECT * FROM refresh_tokens WHERE token_hash = $1;

-- name: RevokeRefreshToken :exec
UPDATE refresh_tokens SET revoked_at = clock_timestamp(), replaced_by = sqlc.narg('replaced_by')
WHERE id = $1 AND revoked_at IS NULL;

-- name: RevokeAllRefreshTokens :exec
UPDATE refresh_tokens SET revoked_at = clock_timestamp()
WHERE user_id = $1 AND revoked_at IS NULL;

-- name: DeleteExpiredRefreshTokens :exec
DELETE FROM refresh_tokens WHERE expires_at < clock_timestamp() - INTERVAL '30 days';

-- name: DeleteFriendshipsOfUser :exec
DELETE FROM friendships WHERE requester_id = $1 OR addressee_id = $1;
