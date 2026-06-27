-- ============================================================
-- SummitMate PostgreSQL Schema
-- Migration: 000001_init_schema
-- ============================================================

-- 3.1 Auth & RBAC
-- ============================================================

CREATE TABLE roles (
    id          UUID PRIMARY KEY DEFAULT uuidv7(),
    code        VARCHAR(20)  NOT NULL UNIQUE,
    name        VARCHAR(50)  NOT NULL,
    description TEXT,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE permissions (
    id          UUID PRIMARY KEY DEFAULT uuidv7(),
    code        VARCHAR(50) NOT NULL UNIQUE,
    category    VARCHAR(50),
    description TEXT
);

CREATE TABLE role_permissions (
    role_id       UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    permission_id UUID NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, permission_id)
);

CREATE TABLE users (
    id                  UUID PRIMARY KEY DEFAULT uuidv7(),
    email               VARCHAR(255) NOT NULL UNIQUE,
    password_hash       TEXT         NOT NULL,
    display_name        VARCHAR(100) NOT NULL,
    avatar              VARCHAR(255) NOT NULL DEFAULT '🐻',
    role_id             UUID REFERENCES roles(id),
    is_active           BOOLEAN      NOT NULL DEFAULT TRUE,
    is_verified         BOOLEAN      NOT NULL DEFAULT FALSE,
    last_login_at       TIMESTAMPTZ,
    created_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    created_by          UUID,
    updated_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_by          UUID
);

CREATE INDEX idx_users_role_id ON users(role_id);

-- 3.2 Core
-- ============================================================

CREATE TABLE trips (
    id          UUID PRIMARY KEY DEFAULT uuidv7(),
    user_id     UUID         NOT NULL REFERENCES users(id),
    name        VARCHAR(200) NOT NULL,
    description TEXT,
    start_date  DATE         NOT NULL,
    end_date    DATE,
    cover_image TEXT,
    is_active   BOOLEAN      NOT NULL DEFAULT FALSE,
    day_names   TEXT[]       NOT NULL DEFAULT '{}',
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    created_by  UUID         NOT NULL REFERENCES users(id),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_by  UUID         NOT NULL REFERENCES users(id)
);

CREATE INDEX idx_trips_user_id ON trips(user_id);

CREATE TABLE trip_meal_plan_days (
    id UUID PRIMARY KEY DEFAULT uuidv7(),
    trip_id UUID NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    name VARCHAR(50) NOT NULL,
    linked_itinerary_day VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_trip_meal_plan_days_trip_id ON trip_meal_plan_days(trip_id);


CREATE TABLE trip_members (
    trip_id   UUID        NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    user_id   UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_code VARCHAR(20) NOT NULL DEFAULT 'member',
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (trip_id, user_id)
);

CREATE TABLE itinerary_items (
    id            UUID PRIMARY KEY DEFAULT uuidv7(),
    trip_id       UUID             NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    day           VARCHAR(10)      NOT NULL DEFAULT '',
    name          VARCHAR(200)     NOT NULL DEFAULT '',
    est_time      VARCHAR(5)       NOT NULL DEFAULT '',
    actual_time   TIMESTAMPTZ,
    altitude      INT              NOT NULL DEFAULT 0,
    distance      DOUBLE PRECISION NOT NULL DEFAULT 0,
    note          TEXT             NOT NULL DEFAULT '',
    image_asset   VARCHAR(200),
    is_checked_in BOOLEAN          NOT NULL DEFAULT FALSE,
    checked_in_at TIMESTAMPTZ,
    created_at    TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
    created_by    UUID             REFERENCES users(id),
    updated_at    TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
    updated_by    UUID             REFERENCES users(id)
);

CREATE INDEX idx_itinerary_items_trip_id ON itinerary_items(trip_id);

CREATE TABLE messages (
    id         UUID PRIMARY KEY DEFAULT uuidv7(),
    trip_id    UUID        REFERENCES trips(id) ON DELETE CASCADE,
    parent_id  UUID        REFERENCES messages(id) ON DELETE CASCADE,
    user_id    UUID        NOT NULL REFERENCES users(id),
    category   VARCHAR(50) NOT NULL DEFAULT '',
    content    TEXT        NOT NULL DEFAULT '',
    timestamp  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID        NOT NULL REFERENCES users(id),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_by UUID        NOT NULL REFERENCES users(id)
);

CREATE INDEX idx_messages_trip_id   ON messages(trip_id);
CREATE INDEX idx_messages_user_id   ON messages(user_id);
CREATE INDEX idx_messages_parent_id ON messages(parent_id);

-- 3.3 Gear
-- ============================================================

CREATE TABLE gear_library_items (
    id          UUID PRIMARY KEY DEFAULT uuidv7(),
    user_id     UUID             NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name        VARCHAR(200)     NOT NULL,
    weight      DOUBLE PRECISION NOT NULL DEFAULT 0,
    category    VARCHAR(50)      NOT NULL DEFAULT 'Other',
    notes       TEXT,
    is_archived BOOLEAN          NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
    created_by  UUID             NOT NULL REFERENCES users(id),
    updated_at  TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
    updated_by  UUID             NOT NULL REFERENCES users(id)
);

CREATE INDEX idx_gear_library_items_user_id ON gear_library_items(user_id);

CREATE TABLE gear_items (
    id              UUID PRIMARY KEY DEFAULT uuidv7(),
    trip_id         UUID             REFERENCES trips(id) ON DELETE CASCADE,
    library_item_id UUID             REFERENCES gear_library_items(id) ON DELETE SET NULL,
    name            VARCHAR(200)     NOT NULL DEFAULT '',
    weight          DOUBLE PRECISION NOT NULL DEFAULT 0,
    category        VARCHAR(50)      NOT NULL DEFAULT 'Other',
    is_checked      BOOLEAN          NOT NULL DEFAULT FALSE,
    order_index     INT,
    quantity        INT              NOT NULL DEFAULT 1,
    created_at      TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
    created_by      UUID             REFERENCES users(id),
    updated_at      TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
    updated_by      UUID             REFERENCES users(id)
);

CREATE INDEX idx_gear_items_trip_id         ON gear_items(trip_id);
CREATE INDEX idx_gear_items_library_item_id ON gear_items(library_item_id);

CREATE TABLE meal_library_items (
    id          UUID PRIMARY KEY DEFAULT uuidv7(),
    user_id     UUID             NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name        VARCHAR(200)     NOT NULL,
    weight      DOUBLE PRECISION NOT NULL DEFAULT 0,
    calories    DOUBLE PRECISION NOT NULL DEFAULT 0,
    notes       TEXT,
    is_archived BOOLEAN          NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
    created_by  UUID             NOT NULL REFERENCES users(id),
    updated_at  TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
    updated_by  UUID             NOT NULL REFERENCES users(id)
);

CREATE INDEX idx_meal_library_items_user_id ON meal_library_items(user_id);

CREATE TABLE meal_items (
    id              UUID PRIMARY KEY DEFAULT uuidv7(),
    trip_id         UUID             NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    library_item_id UUID             REFERENCES meal_library_items(id) ON DELETE SET NULL,
    meal_plan_day_id UUID            NOT NULL REFERENCES trip_meal_plan_days(id) ON DELETE CASCADE,
    meal_type       VARCHAR(20)      NOT NULL,
    name            VARCHAR(200)     NOT NULL,
    weight          DOUBLE PRECISION NOT NULL DEFAULT 0,
    calories        DOUBLE PRECISION NOT NULL DEFAULT 0,
    quantity        INT              NOT NULL DEFAULT 1,
    note            TEXT,
    created_at      TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
    created_by      UUID             NOT NULL REFERENCES users(id),
    updated_at      TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
    updated_by      UUID             NOT NULL REFERENCES users(id)
);

CREATE INDEX idx_meal_items_trip_id          ON meal_items(trip_id);
CREATE INDEX idx_meal_items_meal_plan_day_id ON meal_items(meal_plan_day_id);
CREATE INDEX idx_meal_items_library_item_id  ON meal_items(library_item_id);

CREATE TABLE templates (
    id           UUID PRIMARY KEY DEFAULT uuidv7(),
    type         VARCHAR(20)      NOT NULL,
    title        VARCHAR(200)     NOT NULL,
    author       VARCHAR(100)     NOT NULL,
    total_weight DOUBLE PRECISION NOT NULL DEFAULT 0,
    item_count   INT              NOT NULL DEFAULT 0,
    visibility   VARCHAR(20)      NOT NULL DEFAULT 'public',
    access_key   VARCHAR(100),
    created_at   TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
    created_by   UUID             NOT NULL REFERENCES users(id),
    updated_at   TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
    updated_by   UUID             NOT NULL REFERENCES users(id)
);

CREATE TABLE template_gear_items (
    id          UUID PRIMARY KEY DEFAULT uuidv7(),
    template_id UUID             NOT NULL REFERENCES templates(id) ON DELETE CASCADE,
    name        VARCHAR(200)     NOT NULL,
    weight      DOUBLE PRECISION NOT NULL DEFAULT 0,
    category    VARCHAR(50)      NOT NULL DEFAULT 'Other',
    quantity    INT              NOT NULL DEFAULT 1,
    order_index INT
);

CREATE INDEX idx_template_gear_items_template_id ON template_gear_items(template_id);

CREATE TABLE template_meal_items (
    id          UUID PRIMARY KEY DEFAULT uuidv7(),
    template_id UUID             NOT NULL REFERENCES templates(id) ON DELETE CASCADE,
    day         VARCHAR(10)      NOT NULL,
    meal_type   VARCHAR(20)      NOT NULL,
    name        VARCHAR(200)     NOT NULL,
    weight      DOUBLE PRECISION NOT NULL DEFAULT 0,
    calories    DOUBLE PRECISION NOT NULL DEFAULT 0,
    quantity    INT              NOT NULL DEFAULT 1,
    note        TEXT
);

CREATE INDEX idx_template_meal_items_template_id ON template_meal_items(template_id);

-- 3.4 Polls
-- ============================================================

CREATE TABLE polls (
    id                   UUID PRIMARY KEY DEFAULT uuidv7(),
    trip_id              UUID         REFERENCES trips(id) ON DELETE CASCADE,
    title                VARCHAR(200) NOT NULL,
    description          TEXT         NOT NULL DEFAULT '',
    deadline             TIMESTAMPTZ,
    is_allow_add_option  BOOLEAN      NOT NULL DEFAULT FALSE,
    max_option_limit     INT          NOT NULL DEFAULT 20,
    allow_multiple_votes BOOLEAN      NOT NULL DEFAULT FALSE,
    result_display_type  VARCHAR(20)  NOT NULL DEFAULT 'realtime',
    status               VARCHAR(20)  NOT NULL DEFAULT 'active',
    created_at           TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    created_by           UUID         NOT NULL REFERENCES users(id),
    updated_at           TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_by           UUID         NOT NULL REFERENCES users(id)
);

CREATE INDEX idx_polls_trip_id ON polls(trip_id);

CREATE TABLE poll_options (
    id         UUID PRIMARY KEY DEFAULT uuidv7(),
    poll_id    UUID         NOT NULL REFERENCES polls(id) ON DELETE CASCADE,
    text       VARCHAR(500) NOT NULL,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    created_by UUID         NOT NULL REFERENCES users(id),
    updated_at TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_by UUID         NOT NULL REFERENCES users(id),
    UNIQUE (poll_id, id)
);

CREATE INDEX idx_poll_options_poll_id ON poll_options(poll_id);

CREATE TABLE poll_votes (
    poll_id        UUID NOT NULL REFERENCES polls(id) ON DELETE CASCADE,
    option_id      UUID NOT NULL,
    user_id        UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (poll_id, option_id, user_id),
    FOREIGN KEY (poll_id, option_id) REFERENCES poll_options(poll_id, id) ON DELETE CASCADE
);

-- 3.5 Group Events
-- ============================================================

CREATE TABLE group_events (
    id                UUID PRIMARY KEY DEFAULT uuidv7(),
    host_id           UUID         NOT NULL REFERENCES users(id),
    host_name         VARCHAR(100) NOT NULL DEFAULT '',
    host_avatar       VARCHAR(255) NOT NULL DEFAULT '🐻',
    title             VARCHAR(200) NOT NULL,
    description       TEXT         NOT NULL DEFAULT '',
    category          VARCHAR(50)  NOT NULL DEFAULT 'Other' CHECK (category IN ('Hiking', 'Camping', 'Bouldering', 'Other')),
    location          VARCHAR(200) NOT NULL DEFAULT '',
    start_date        DATE         NOT NULL,
    end_date          DATE,
    status            VARCHAR(20)  NOT NULL DEFAULT 'open',
    max_members       INT          NOT NULL DEFAULT 10,
    approval_required BOOLEAN      NOT NULL DEFAULT FALSE,
    private_message   TEXT         NOT NULL DEFAULT '',
    linked_trip_id    UUID         REFERENCES trips(id) ON DELETE SET NULL,
    trip_snapshot     JSONB,
    snapshot_updated_at TIMESTAMPTZ,
    like_count        INT          NOT NULL DEFAULT 0,
    comment_count     INT          NOT NULL DEFAULT 0,
    created_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    created_by        UUID         NOT NULL REFERENCES users(id),
    updated_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_by        UUID         NOT NULL REFERENCES users(id)
);

CREATE INDEX idx_group_events_host_id        ON group_events(host_id);
CREATE INDEX idx_group_events_linked_trip_id ON group_events(linked_trip_id);

CREATE TABLE group_event_applications (
    id               UUID PRIMARY KEY DEFAULT uuidv7(),
    event_id         UUID        NOT NULL REFERENCES group_events(id) ON DELETE CASCADE,
    user_id          UUID        NOT NULL REFERENCES users(id),
    status           VARCHAR(20) NOT NULL DEFAULT 'pending',
    message          TEXT        NOT NULL DEFAULT '',
    rejection_reason TEXT        NOT NULL DEFAULT '',
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by       UUID        NOT NULL REFERENCES users(id),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_by       UUID        NOT NULL REFERENCES users(id)
);

CREATE INDEX idx_group_event_applications_event_id ON group_event_applications(event_id);
CREATE INDEX idx_group_event_applications_user_id  ON group_event_applications(user_id);

CREATE TABLE group_event_comments (
    id         UUID PRIMARY KEY DEFAULT uuidv7(),
    event_id   UUID        NOT NULL REFERENCES group_events(id) ON DELETE CASCADE,
    user_id    UUID        NOT NULL REFERENCES users(id),
    content    TEXT        NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID        NOT NULL REFERENCES users(id),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_by UUID        NOT NULL REFERENCES users(id)
);

CREATE INDEX idx_group_event_comments_event_id ON group_event_comments(event_id);
CREATE INDEX idx_group_event_comments_user_id  ON group_event_comments(user_id);

CREATE TABLE group_event_likes (
    event_id   UUID NOT NULL REFERENCES group_events(id) ON DELETE CASCADE,
    user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID NOT NULL REFERENCES users(id),
    PRIMARY KEY (event_id, user_id)
);

-- 3.6 Favorites
-- ============================================================

CREATE TABLE favorites (
    id         UUID PRIMARY KEY DEFAULT uuidv7(),
    user_id    UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    target_id  UUID        NOT NULL,
    type       VARCHAR(30) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID        NOT NULL REFERENCES users(id),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_by UUID        NOT NULL REFERENCES users(id),
    UNIQUE (user_id, target_id, type)
);

-- 3.7 System
-- ============================================================

CREATE TABLE logs (
    id          UUID PRIMARY KEY DEFAULT uuidv7(),
    upload_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    device_id   TEXT,
    device_name TEXT,
    timestamp   TIMESTAMPTZ NOT NULL,
    level       VARCHAR(10) NOT NULL,
    source      TEXT,
    message     TEXT
);

CREATE INDEX idx_logs_timestamp ON logs (timestamp);
CREATE INDEX idx_logs_level ON logs (level);


CREATE TABLE heartbeats (
    user_id    UUID PRIMARY KEY REFERENCES users(id),
    user_type  VARCHAR(20),
    last_seen  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    view       VARCHAR(100),
    view_stats JSONB DEFAULT '{}',
    platform   VARCHAR(20)
);

-- ============================================================
-- Seed Data: Default Roles & Permissions
-- ============================================================

INSERT INTO roles (code, name, description) VALUES
    ('ADMIN',  '管理員', '系統最高權限'),
    ('LEADER', '團長',   '行程建立者/管理者'),
    ('GUIDE',  '嚮導',   '行程協助管理'),
    ('MEMBER', '成員',   '一般使用者');

INSERT INTO permissions (code, category, description) VALUES
    ('trip.create', 'trip',  '建立行程'),
    ('trip.edit',   'trip',  '編輯行程'),
    ('trip.delete', 'trip',  '刪除行程'),
    ('trip.view',   'trip',  '查看行程'),
    ('gear.manage', 'gear',  '管理裝備'),
    ('poll.create', 'poll',  '建立投票'),
    ('poll.vote',   'poll',  '參與投票'),
    ('event.create','event', '建立揪團'),
    ('event.manage','event', '管理揪團'),
    ('admin.users', 'admin', '管理使用者');

-- ADMIN: all permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.code = 'ADMIN';

-- MEMBER: basic permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id FROM roles r, permissions p
WHERE r.code = 'MEMBER' AND p.code IN ('trip.create', 'trip.view', 'gear.manage', 'poll.vote', 'event.create');

-- 3.8 Weather
-- ============================================================

CREATE TABLE IF NOT EXISTS weather_data (
    id          UUID PRIMARY KEY DEFAULT uuidv7(),
    location    TEXT NOT NULL,
    start_time  TIMESTAMPTZ NOT NULL,
    end_time    TIMESTAMPTZ NOT NULL,
    wx          TEXT DEFAULT '',
    temp        REAL DEFAULT 0,
    pop         INT  DEFAULT 0,
    min_temp    REAL DEFAULT 0,
    max_temp    REAL DEFAULT 0,
    humidity    REAL DEFAULT 0,
    wind_speed  REAL DEFAULT 0,
    min_at      REAL DEFAULT 0,
    max_at      REAL DEFAULT 0,
    issue_time  TIMESTAMPTZ,
    fetched_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (location, start_time, end_time)
);

CREATE INDEX idx_weather_location ON weather_data (location);
CREATE INDEX idx_weather_start_time ON weather_data (start_time);

-- 3.9 System Flags
-- ============================================================

CREATE TABLE IF NOT EXISTS system_flags (
    key         TEXT PRIMARY KEY,
    value       BOOLEAN NOT NULL DEFAULT FALSE,
    description TEXT,
    updated_at  TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO system_flags (key, value, description) VALUES
    ('skip_verification_code', FALSE, 'Whether to allow any verification code to pass'),
    ('enable_email_sending',   TRUE,  'Whether to actually send emails')
ON CONFLICT (key) DO NOTHING;

CREATE TABLE IF NOT EXISTS system_flags_history (
    id          BIGSERIAL PRIMARY KEY,
    key         TEXT NOT NULL,
    old_value   BOOLEAN,
    new_value   BOOLEAN,
    changed_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    changed_by  TEXT
);

CREATE OR REPLACE FUNCTION log_system_flags_changes()
RETURNS TRIGGER AS $$
DECLARE
    current_user_id TEXT;
BEGIN
    BEGIN
        current_user_id := current_setting('app.current_user_id', true);
    EXCEPTION WHEN OTHERS THEN
        current_user_id := NULL;
    END;

    IF current_user_id IS NULL OR current_user_id = '' THEN
        current_user_id := SESSION_USER;
    END IF;

    IF (TG_OP = 'UPDATE' AND OLD.value IS DISTINCT FROM NEW.value) THEN
        INSERT INTO system_flags_history (key, old_value, new_value, changed_by)
        VALUES (NEW.key, OLD.value, NEW.value, current_user_id);
    ELSIF (TG_OP = 'INSERT') THEN
        INSERT INTO system_flags_history (key, old_value, new_value, changed_by)
        VALUES (NEW.key, NULL, NEW.value, current_user_id);
    ELSIF (TG_OP = 'DELETE') THEN
        INSERT INTO system_flags_history (key, old_value, new_value, changed_by)
        VALUES (OLD.key, OLD.value, NULL, current_user_id);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_system_flags_changes
AFTER INSERT OR UPDATE OR DELETE ON system_flags
FOR EACH ROW
EXECUTE FUNCTION log_system_flags_changes();

-- 3.10 Gear Cloud
-- ============================================================

CREATE TABLE IF NOT EXISTS gear_sets (
    id UUID PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    author VARCHAR(255) NOT NULL,
    total_weight NUMERIC(10,2) DEFAULT 0,
    item_count INTEGER DEFAULT 0,
    visibility VARCHAR(20) NOT NULL CHECK (visibility IN ('public', 'protected', 'private')),
    download_key VARCHAR(255),
    user_id UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by UUID NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID NOT NULL
);

-- Index for querying public/protected sets efficiently
CREATE INDEX IF NOT EXISTS idx_gear_sets_visibility ON gear_sets(visibility);
-- Index for finding my uploaded sets
CREATE INDEX IF NOT EXISTS idx_gear_sets_user_id ON gear_sets(user_id);

CREATE TABLE IF NOT EXISTS gear_set_items (
    id UUID PRIMARY KEY,
    gear_set_id UUID NOT NULL REFERENCES gear_sets(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL,
    weight NUMERIC(10,2) NOT NULL DEFAULT 0,
    quantity INTEGER NOT NULL DEFAULT 1,
    order_index INTEGER DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_gear_set_items_set_id ON gear_set_items(gear_set_id);

CREATE TABLE IF NOT EXISTS gear_set_meals (
    id UUID PRIMARY KEY,
    gear_set_id UUID NOT NULL REFERENCES gear_sets(id) ON DELETE CASCADE,
    day VARCHAR(50) NOT NULL,
    meal_type VARCHAR(50) NOT NULL,
    name VARCHAR(255) NOT NULL,
    calories NUMERIC(10,2) DEFAULT 0,
    note TEXT
);

CREATE INDEX IF NOT EXISTS idx_gear_set_meals_set_id ON gear_set_meals(gear_set_id);
