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
    -- Simplified GPX track of the trip as compact JSON [[lat,lng,ele],...] (about 500 points at most).
    track       TEXT,
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

-- Personal data that belongs to no trip: a row is only visible to and writable by its user_id.
CREATE TABLE library_items (
    id         UUID PRIMARY KEY,
    user_id    UUID             NOT NULL REFERENCES users(id),
    kind       VARCHAR(10)      NOT NULL CHECK (kind IN ('gear', 'meal')),
    name       VARCHAR(200)     NOT NULL DEFAULT '',
    category   VARCHAR(50)      NOT NULL DEFAULT 'other',
    weight     DOUBLE PRECISION NOT NULL DEFAULT 0 CHECK (weight >= 0),
    calories   DOUBLE PRECISION NOT NULL DEFAULT 0 CHECK (calories >= 0),
    note       TEXT             NOT NULL DEFAULT '',
    deleted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ      NOT NULL DEFAULT clock_timestamp(),
    created_by UUID             NOT NULL REFERENCES users(id),
    updated_at TIMESTAMPTZ      NOT NULL DEFAULT clock_timestamp(),
    updated_by UUID             NOT NULL REFERENCES users(id)
);

CREATE INDEX idx_library_items_user_updated ON library_items(user_id, updated_at);

-- items is a JSON array (max 300 elements, validated by the sync service).
CREATE TABLE templates (
    id         UUID PRIMARY KEY,
    user_id    UUID         NOT NULL REFERENCES users(id),
    title      VARCHAR(200) NOT NULL DEFAULT '',
    note       TEXT         NOT NULL DEFAULT '',
    items      TEXT         NOT NULL DEFAULT '[]',
    deleted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT clock_timestamp(),
    created_by UUID         NOT NULL REFERENCES users(id),
    updated_at TIMESTAMPTZ  NOT NULL DEFAULT clock_timestamp(),
    updated_by UUID         NOT NULL REFERENCES users(id)
);

CREATE INDEX idx_templates_user_updated ON templates(user_id, updated_at);

-- Trip discussion. Rows are shared by all active members of the trip (trip_id); user_id is the
-- author / voter and is forced to the pushing user. Row-level rules live in the sync service.
-- parent_id allows one level of replies only (the parent itself has no parent).
CREATE TABLE trip_messages (
    id         UUID PRIMARY KEY,
    trip_id    UUID          NOT NULL REFERENCES trips(id),
    user_id    UUID          NOT NULL REFERENCES users(id),
    parent_id  UUID          REFERENCES trip_messages(id),
    body       VARCHAR(1000) NOT NULL CHECK (char_length(body) >= 1),
    deleted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ   NOT NULL DEFAULT clock_timestamp(),
    created_by UUID          NOT NULL REFERENCES users(id),
    updated_at TIMESTAMPTZ   NOT NULL DEFAULT clock_timestamp(),
    updated_by UUID          NOT NULL REFERENCES users(id)
);

CREATE INDEX idx_trip_messages_trip_updated ON trip_messages(trip_id, updated_at);

CREATE TABLE polls (
    id               UUID PRIMARY KEY,
    trip_id          UUID         NOT NULL REFERENCES trips(id),
    title            VARCHAR(200) NOT NULL CHECK (char_length(title) >= 1),
    description      TEXT         NOT NULL DEFAULT '',
    deadline         TIMESTAMPTZ,
    allow_multiple   BOOLEAN      NOT NULL DEFAULT FALSE,
    allow_add_option BOOLEAN      NOT NULL DEFAULT FALSE,
    blind            BOOLEAN      NOT NULL DEFAULT FALSE,
    status           VARCHAR(10)  NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'closed')),
    deleted_at       TIMESTAMPTZ,
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT clock_timestamp(),
    created_by       UUID         NOT NULL REFERENCES users(id),
    updated_at       TIMESTAMPTZ  NOT NULL DEFAULT clock_timestamp(),
    updated_by       UUID         NOT NULL REFERENCES users(id)
);

CREATE INDEX idx_polls_trip_updated ON polls(trip_id, updated_at);

CREATE TABLE poll_options (
    id         UUID PRIMARY KEY,
    poll_id    UUID         NOT NULL REFERENCES polls(id),
    trip_id    UUID         NOT NULL REFERENCES trips(id),
    text       VARCHAR(100) NOT NULL CHECK (char_length(text) >= 1),
    sort_order INT          NOT NULL DEFAULT 0,
    deleted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT clock_timestamp(),
    created_by UUID         NOT NULL REFERENCES users(id),
    updated_at TIMESTAMPTZ  NOT NULL DEFAULT clock_timestamp(),
    updated_by UUID         NOT NULL REFERENCES users(id)
);

CREATE INDEX idx_poll_options_trip_updated ON poll_options(trip_id, updated_at);

-- One user's vote for one option. id = UUIDv5(voteNamespace, "<option_id>:<user_id>"), so
-- re-voting revives the same row; deleted_at means the vote was retracted.
CREATE TABLE poll_votes (
    id         UUID PRIMARY KEY,
    poll_id    UUID        NOT NULL REFERENCES polls(id),
    option_id  UUID        NOT NULL REFERENCES poll_options(id),
    trip_id    UUID        NOT NULL REFERENCES trips(id),
    user_id    UUID        NOT NULL REFERENCES users(id),
    deleted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    created_by UUID        NOT NULL REFERENCES users(id),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    updated_by UUID        NOT NULL REFERENCES users(id)
);

CREATE INDEX idx_poll_votes_trip_updated ON poll_votes(trip_id, updated_at);

-- Favorites: personal, belongs to no trip. target_id is the mountain id for kind 'mountain'.
CREATE TABLE favorites (
    id         UUID PRIMARY KEY,
    user_id    UUID         NOT NULL REFERENCES users(id),
    kind       VARCHAR(20)  NOT NULL CHECK (kind IN ('mountain')),
    target_id  VARCHAR(100) NOT NULL CHECK (char_length(target_id) >= 1),
    deleted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT clock_timestamp(),
    created_by UUID         NOT NULL REFERENCES users(id),
    updated_at TIMESTAMPTZ  NOT NULL DEFAULT clock_timestamp(),
    updated_by UUID         NOT NULL REFERENCES users(id)
);

CREATE INDEX idx_favorites_user_updated ON favorites(user_id, updated_at);

CREATE TRIGGER trg_trips_updated_at           BEFORE INSERT OR UPDATE ON trips           FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_trip_members_updated_at    BEFORE INSERT OR UPDATE ON trip_members    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_itinerary_items_updated_at BEFORE INSERT OR UPDATE ON itinerary_items FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_gear_items_updated_at      BEFORE INSERT OR UPDATE ON gear_items      FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_meal_plan_days_updated_at  BEFORE INSERT OR UPDATE ON meal_plan_days  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_meal_items_updated_at      BEFORE INSERT OR UPDATE ON meal_items      FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_library_items_updated_at   BEFORE INSERT OR UPDATE ON library_items   FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_templates_updated_at       BEFORE INSERT OR UPDATE ON templates       FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_trip_messages_updated_at BEFORE INSERT OR UPDATE ON trip_messages FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_polls_updated_at BEFORE INSERT OR UPDATE ON polls FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_poll_options_updated_at BEFORE INSERT OR UPDATE ON poll_options FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_poll_votes_updated_at BEFORE INSERT OR UPDATE ON poll_votes FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_favorites_updated_at BEFORE INSERT OR UPDATE ON favorites FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Idempotency record for POST /sync/push.
CREATE TABLE processed_ops (
    op_id      UUID PRIMARY KEY,
    user_id    UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    result     JSONB       NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp()
);

CREATE INDEX idx_processed_ops_created_at ON processed_ops(created_at);

-- Cloud sharing (online only, not synced). Items use the same JSON format as templates.items.
CREATE TABLE shared_sets (
    id              UUID PRIMARY KEY,
    owner_id        UUID             NOT NULL REFERENCES users(id),
    title           VARCHAR(200)     NOT NULL,
    author_name     VARCHAR(100)     NOT NULL,
    visibility      VARCHAR(10)      NOT NULL CHECK (visibility IN ('public', 'protected', 'private')),
    access_key_hash TEXT,
    items           JSONB            NOT NULL,
    total_weight    DOUBLE PRECISION NOT NULL DEFAULT 0,
    gear_count      INT              NOT NULL DEFAULT 0,
    meal_count      INT              NOT NULL DEFAULT 0,
    deleted_at      TIMESTAMPTZ,
    created_at      TIMESTAMPTZ      NOT NULL DEFAULT clock_timestamp()
);

CREATE INDEX idx_shared_sets_public ON shared_sets(created_at DESC) WHERE visibility <> 'private' AND deleted_at IS NULL;
CREATE INDEX idx_shared_sets_owner  ON shared_sets(owner_id, created_at DESC) WHERE deleted_at IS NULL;

-- ============================================================
-- Group events (online only, not synced)
-- ============================================================

-- Events are never hard-deleted: the host cancels them (status = 'cancelled').
-- trip_snapshot is a display-only copy of a trip plan (validated by the service).
CREATE TABLE group_events (
    id                  UUID PRIMARY KEY,
    host_id             UUID         NOT NULL REFERENCES users(id),
    title               VARCHAR(200) NOT NULL,
    description         TEXT         NOT NULL DEFAULT '',
    category            VARCHAR(20)  NOT NULL CHECK (category IN ('hiking', 'camping', 'bouldering', 'other')),
    location            VARCHAR(200) NOT NULL DEFAULT '',
    start_date          DATE         NOT NULL,
    end_date            DATE,
    max_members         INT          NOT NULL CHECK (max_members BETWEEN 2 AND 100),
    approval_required   BOOLEAN      NOT NULL DEFAULT TRUE,
    -- Only the host and approved applicants may read this; never selected by list queries.
    private_message     TEXT         NOT NULL DEFAULT '',
    status              VARCHAR(10)  NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'closed', 'cancelled')),
    linked_trip_id      UUID         REFERENCES trips(id),
    trip_snapshot       JSONB,
    snapshot_updated_at TIMESTAMPTZ,
    deleted_at          TIMESTAMPTZ,
    created_at          TIMESTAMPTZ  NOT NULL DEFAULT clock_timestamp(),
    updated_at          TIMESTAMPTZ  NOT NULL DEFAULT clock_timestamp(),
    CHECK (end_date IS NULL OR end_date >= start_date)
);

CREATE INDEX idx_group_events_created_at ON group_events(created_at DESC, id DESC) WHERE deleted_at IS NULL;
CREATE INDEX idx_group_events_start_date ON group_events(start_date, id) WHERE deleted_at IS NULL;
CREATE INDEX idx_group_events_host_id    ON group_events(host_id, created_at DESC) WHERE deleted_at IS NULL;

CREATE TRIGGER trg_group_events_updated_at BEFORE INSERT OR UPDATE ON group_events
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- One row per (event, user); applying again after a rejection or cancellation updates the same row.
CREATE TABLE group_event_applications (
    id               UUID PRIMARY KEY,
    event_id         UUID         NOT NULL REFERENCES group_events(id),
    user_id          UUID         NOT NULL REFERENCES users(id),
    status           VARCHAR(10)  NOT NULL CHECK (status IN ('pending', 'approved', 'rejected', 'cancelled')),
    message          VARCHAR(500) NOT NULL DEFAULT '',
    rejection_reason VARCHAR(500) NOT NULL DEFAULT '',
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT clock_timestamp(),
    updated_at       TIMESTAMPTZ  NOT NULL DEFAULT clock_timestamp(),
    UNIQUE (event_id, user_id)
);

CREATE INDEX idx_group_event_applications_event_status ON group_event_applications(event_id, status, created_at);
CREATE INDEX idx_group_event_applications_user_status  ON group_event_applications(user_id, status);

CREATE TRIGGER trg_group_event_applications_updated_at BEFORE INSERT OR UPDATE ON group_event_applications
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE group_event_comments (
    id         UUID PRIMARY KEY,
    event_id   UUID          NOT NULL REFERENCES group_events(id),
    user_id    UUID          NOT NULL REFERENCES users(id),
    body       VARCHAR(1000) NOT NULL,
    deleted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ   NOT NULL DEFAULT clock_timestamp()
);

CREATE INDEX idx_group_event_comments_event_created ON group_event_comments(event_id, created_at, id) WHERE deleted_at IS NULL;

CREATE TABLE group_event_likes (
    event_id   UUID        NOT NULL REFERENCES group_events(id),
    user_id    UUID        NOT NULL REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY (event_id, user_id)
);

-- Stored for operators to read directly (no review UI yet); one report per reporter and target.
CREATE TABLE reports (
    id          UUID PRIMARY KEY,
    reporter_id UUID         NOT NULL REFERENCES users(id),
    target_type VARCHAR(20)  NOT NULL CHECK (target_type IN ('group_event', 'group_event_comment')),
    target_id   UUID         NOT NULL,
    reason      VARCHAR(500) NOT NULL,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT clock_timestamp(),
    UNIQUE (reporter_id, target_type, target_id)
);

CREATE INDEX idx_reports_target ON reports(target_type, target_id);
