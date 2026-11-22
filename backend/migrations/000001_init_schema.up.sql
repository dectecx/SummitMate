-- SummitMate schema (rebuild).
-- During initial development, edit this file directly (no incremental migrations).
-- Requires PostgreSQL 18+ (uuidv7()).

-- ============================================================
-- Shared helpers
-- ============================================================

-- Sets updated_at on every write. Uses clock_timestamp() (not now()) so that the
-- value reflects the actual write time, which the sync cursor relies on.
-- Clients can never supply updated_at.
CREATE FUNCTION set_updated_at() RETURNS trigger AS $$
BEGIN
    NEW.updated_at = clock_timestamp();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- Auth
-- ============================================================

CREATE TABLE users (
    id            UUID PRIMARY KEY DEFAULT uuidv7(),
    email         VARCHAR(255) NOT NULL UNIQUE CHECK (email = LOWER(email)),
    password_hash TEXT         NOT NULL,
    display_name  VARCHAR(100) NOT NULL,
    avatar        VARCHAR(255) NOT NULL DEFAULT '🐻',
    is_verified   BOOLEAN      NOT NULL DEFAULT FALSE,
    is_active     BOOLEAN      NOT NULL DEFAULT TRUE,
    last_login_at TIMESTAMPTZ,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT clock_timestamp(),
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT clock_timestamp()
);

CREATE TRIGGER trg_users_updated_at BEFORE INSERT OR UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Opaque refresh tokens, stored hashed. Rotated on every refresh.
CREATE TABLE refresh_tokens (
    id          UUID PRIMARY KEY DEFAULT uuidv7(),
    user_id     UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash  TEXT        NOT NULL UNIQUE,
    expires_at  TIMESTAMPTZ NOT NULL,
    revoked_at  TIMESTAMPTZ,
    replaced_by UUID REFERENCES refresh_tokens(id) ON DELETE SET NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp()
);

CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens(user_id);

-- One active 6-digit email verification code per user.
CREATE TABLE email_verifications (
    user_id    UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    code_hash  TEXT        NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    attempts   INT         NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp()
);

-- ============================================================
-- Syncable data
-- Every table below has: client-generated UUID id, server-assigned updated_at,
-- and a deleted_at tombstone. Rows are never hard-deleted.
-- ============================================================

CREATE TABLE trips (
    id          UUID PRIMARY KEY,
    owner_id    UUID         NOT NULL REFERENCES users(id),
    name        VARCHAR(200) NOT NULL,
    description TEXT         NOT NULL DEFAULT '',
    start_date  DATE         NOT NULL,
    end_date    DATE,
    -- Main mountain of the trip (an id from the explore list); weather and map hints follow it.
    mountain_id VARCHAR(64),
    cover_image TEXT,
    deleted_at  TIMESTAMPTZ,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT clock_timestamp(),
    created_by  UUID         NOT NULL REFERENCES users(id),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT clock_timestamp(),
    updated_by  UUID         NOT NULL REFERENCES users(id),
    CHECK (end_date IS NULL OR end_date >= start_date)
);

CREATE INDEX idx_trips_updated_at ON trips(updated_at);
CREATE INDEX idx_trips_owner_id   ON trips(owner_id);

-- id is a surrogate so membership can be synced like any other entity.
CREATE TABLE trip_members (
    id         UUID PRIMARY KEY,
    trip_id    UUID        NOT NULL REFERENCES trips(id),
    user_id    UUID        NOT NULL REFERENCES users(id),
    role       VARCHAR(10) NOT NULL DEFAULT 'member' CHECK (role IN ('owner', 'guide', 'member')),
    deleted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    created_by UUID        NOT NULL REFERENCES users(id),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    updated_by UUID        NOT NULL REFERENCES users(id),
    UNIQUE (trip_id, user_id)
);

CREATE INDEX idx_trip_members_user_id    ON trip_members(user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_trip_members_updated_at ON trip_members(updated_at);

CREATE TABLE itinerary_items (
    id            UUID PRIMARY KEY,
    trip_id       UUID             NOT NULL REFERENCES trips(id),
    day_index     SMALLINT         NOT NULL DEFAULT 0 CHECK (day_index >= 0),
    name          VARCHAR(200)     NOT NULL DEFAULT '',
    est_minutes   SMALLINT         CHECK (est_minutes IS NULL OR est_minutes BETWEEN 0 AND 1439),
    altitude      INT              NOT NULL DEFAULT 0,
    distance      DOUBLE PRECISION NOT NULL DEFAULT 0,
    lat           DOUBLE PRECISION CHECK (lat IS NULL OR lat BETWEEN -90 AND 90),
    lng           DOUBLE PRECISION CHECK (lng IS NULL OR lng BETWEEN -180 AND 180),
    note          TEXT             NOT NULL DEFAULT '',
    checked_in_at TIMESTAMPTZ,
    deleted_at    TIMESTAMPTZ,
    created_at    TIMESTAMPTZ      NOT NULL DEFAULT clock_timestamp(),
    created_by    UUID             NOT NULL REFERENCES users(id),
    updated_at    TIMESTAMPTZ      NOT NULL DEFAULT clock_timestamp(),
    updated_by    UUID             NOT NULL REFERENCES users(id)
);

CREATE INDEX idx_itinerary_items_trip_updated ON itinerary_items(trip_id, updated_at);
CREATE INDEX idx_itinerary_items_updated_at   ON itinerary_items(updated_at);

-- Personal data: each row belongs to one member (user_id) and only that member may write it.
CREATE TABLE gear_items (
    id         UUID PRIMARY KEY,
    trip_id    UUID             NOT NULL REFERENCES trips(id),
    user_id    UUID             NOT NULL REFERENCES users(id),
    name       VARCHAR(200)     NOT NULL DEFAULT '',
    weight     DOUBLE PRECISION NOT NULL DEFAULT 0 CHECK (weight >= 0),
    category   VARCHAR(50)      NOT NULL DEFAULT 'other',
    quantity   INT              NOT NULL DEFAULT 1 CHECK (quantity >= 0),
    is_checked BOOLEAN          NOT NULL DEFAULT FALSE,
    sort_order INT              NOT NULL DEFAULT 0,
    deleted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ      NOT NULL DEFAULT clock_timestamp(),
    created_by UUID             NOT NULL REFERENCES users(id),
    updated_at TIMESTAMPTZ      NOT NULL DEFAULT clock_timestamp(),
    updated_by UUID             NOT NULL REFERENCES users(id)
);

CREATE INDEX idx_gear_items_user_updated ON gear_items(user_id, updated_at);

CREATE TABLE meal_plan_days (
    id         UUID PRIMARY KEY,
    trip_id    UUID        NOT NULL REFERENCES trips(id),
    user_id    UUID        NOT NULL REFERENCES users(id),
    name       VARCHAR(50) NOT NULL DEFAULT '',
    day_index  SMALLINT    NOT NULL DEFAULT 0 CHECK (day_index >= 0),
    deleted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    created_by UUID        NOT NULL REFERENCES users(id),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    updated_by UUID        NOT NULL REFERENCES users(id)
);

CREATE INDEX idx_meal_plan_days_user_updated ON meal_plan_days(user_id, updated_at);

CREATE TABLE meal_items (
    id               UUID PRIMARY KEY,
    trip_id          UUID             NOT NULL REFERENCES trips(id),
    user_id          UUID             NOT NULL REFERENCES users(id),
    meal_plan_day_id UUID             NOT NULL REFERENCES meal_plan_days(id),
    meal_type        VARCHAR(20)      NOT NULL DEFAULT 'other',
    name             VARCHAR(200)     NOT NULL DEFAULT '',
    weight           DOUBLE PRECISION NOT NULL DEFAULT 0 CHECK (weight >= 0),
    calories         DOUBLE PRECISION NOT NULL DEFAULT 0 CHECK (calories >= 0),
    quantity         INT              NOT NULL DEFAULT 1 CHECK (quantity >= 0),
    note             TEXT             NOT NULL DEFAULT '',
    deleted_at       TIMESTAMPTZ,
    created_at       TIMESTAMPTZ      NOT NULL DEFAULT clock_timestamp(),
    created_by       UUID             NOT NULL REFERENCES users(id),
    updated_at       TIMESTAMPTZ      NOT NULL DEFAULT clock_timestamp(),
    updated_by       UUID             NOT NULL REFERENCES users(id)
);

CREATE INDEX idx_meal_items_user_updated ON meal_items(user_id, updated_at);

CREATE TRIGGER trg_trips_updated_at           BEFORE INSERT OR UPDATE ON trips           FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_trip_members_updated_at    BEFORE INSERT OR UPDATE ON trip_members    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_itinerary_items_updated_at BEFORE INSERT OR UPDATE ON itinerary_items FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_gear_items_updated_at      BEFORE INSERT OR UPDATE ON gear_items      FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_meal_plan_days_updated_at  BEFORE INSERT OR UPDATE ON meal_plan_days  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_meal_items_updated_at      BEFORE INSERT OR UPDATE ON meal_items      FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Idempotency record for POST /sync/push.
CREATE TABLE processed_ops (
    op_id      UUID PRIMARY KEY,
    user_id    UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    result     JSONB       NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp()
);

CREATE INDEX idx_processed_ops_created_at ON processed_ops(created_at);
