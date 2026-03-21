-- ============================================================
-- SummitMate PostgreSQL Schema
-- Migration: 000001_init_schema
-- ============================================================

-- 3.1 Auth & RBAC
-- ============================================================

CREATE TABLE roles (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code        VARCHAR(20)  NOT NULL UNIQUE,
    name        VARCHAR(50)  NOT NULL,
    description TEXT,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE permissions (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
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
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email               VARCHAR(255) NOT NULL UNIQUE,
    password_hash       TEXT         NOT NULL,
    display_name        VARCHAR(100) NOT NULL,
    avatar              VARCHAR(10)  NOT NULL DEFAULT '🐻',
    role_id             UUID REFERENCES roles(id),
    is_active           BOOLEAN      NOT NULL DEFAULT TRUE,
    is_verified         BOOLEAN      NOT NULL DEFAULT FALSE,
    verification_code   VARCHAR(10),
    verification_expiry TIMESTAMPTZ,
    last_login_at       TIMESTAMPTZ,
    created_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    created_by          UUID,
    updated_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_by          UUID
);

-- 3.2 Core
-- ============================================================

CREATE TABLE trips (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
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

CREATE TABLE trip_members (
    trip_id   UUID        NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    user_id   UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_code VARCHAR(20) NOT NULL DEFAULT 'member',
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (trip_id, user_id)
);

CREATE TABLE itinerary_items (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
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

CREATE TABLE messages (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
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

-- 3.3 Gear
-- ============================================================

CREATE TABLE gear_library_items (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
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

CREATE TABLE gear_items (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
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

CREATE TABLE meal_library_items (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
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

CREATE TABLE meal_items (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id         UUID             NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    library_item_id UUID             REFERENCES meal_library_items(id) ON DELETE SET NULL,
    day             VARCHAR(10)      NOT NULL,
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

CREATE TABLE templates (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
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
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_id UUID             NOT NULL REFERENCES templates(id) ON DELETE CASCADE,
    name        VARCHAR(200)     NOT NULL,
    weight      DOUBLE PRECISION NOT NULL DEFAULT 0,
    category    VARCHAR(50)      NOT NULL DEFAULT 'Other',
    quantity    INT              NOT NULL DEFAULT 1,
    order_index INT
);

CREATE TABLE template_meal_items (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_id UUID             NOT NULL REFERENCES templates(id) ON DELETE CASCADE,
    day         VARCHAR(10)      NOT NULL,
    meal_type   VARCHAR(20)      NOT NULL,
    name        VARCHAR(200)     NOT NULL,
    weight      DOUBLE PRECISION NOT NULL DEFAULT 0,
    calories    DOUBLE PRECISION NOT NULL DEFAULT 0,
    quantity    INT              NOT NULL DEFAULT 1,
    note        TEXT
);

-- 3.4 Polls
-- ============================================================

CREATE TABLE polls (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
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

CREATE TABLE poll_options (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    poll_id    UUID         NOT NULL REFERENCES polls(id) ON DELETE CASCADE,
    text       VARCHAR(500) NOT NULL,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    created_by UUID         NOT NULL REFERENCES users(id),
    updated_at TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_by UUID         NOT NULL REFERENCES users(id)
);

CREATE TABLE poll_votes (
    poll_id        UUID NOT NULL REFERENCES polls(id) ON DELETE CASCADE,
    option_id      UUID NOT NULL REFERENCES poll_options(id) ON DELETE CASCADE,
    user_id        UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (poll_id, option_id, user_id)
);

-- 3.5 Group Events
-- ============================================================

CREATE TABLE group_events (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title             VARCHAR(200) NOT NULL,
    description       TEXT         NOT NULL DEFAULT '',
    location          VARCHAR(200) NOT NULL DEFAULT '',
    start_date        DATE         NOT NULL,
    end_date          DATE,
    status            VARCHAR(20)  NOT NULL DEFAULT 'open',
    max_members       INT          NOT NULL DEFAULT 10,
    approval_required BOOLEAN      NOT NULL DEFAULT FALSE,
    private_message   TEXT         NOT NULL DEFAULT '',
    linked_trip_id    UUID         REFERENCES trips(id),
    like_count        INT          NOT NULL DEFAULT 0,
    comment_count     INT          NOT NULL DEFAULT 0,
    created_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    created_by        UUID         NOT NULL REFERENCES users(id),
    updated_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_by        UUID         NOT NULL REFERENCES users(id)
);

CREATE TABLE group_event_applications (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id   UUID        NOT NULL REFERENCES group_events(id) ON DELETE CASCADE,
    user_id    UUID        NOT NULL REFERENCES users(id),
    status     VARCHAR(20) NOT NULL DEFAULT 'pending',
    message    TEXT        NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID        NOT NULL REFERENCES users(id),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_by UUID        NOT NULL REFERENCES users(id),
    UNIQUE (event_id, user_id)
);

CREATE TABLE group_event_comments (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id   UUID        NOT NULL REFERENCES group_events(id) ON DELETE CASCADE,
    user_id    UUID        NOT NULL REFERENCES users(id),
    content    TEXT        NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID        NOT NULL REFERENCES users(id),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_by UUID        NOT NULL REFERENCES users(id)
);

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
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
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
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    upload_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    device_id   TEXT,
    device_name TEXT,
    timestamp   TIMESTAMPTZ NOT NULL,
    level       VARCHAR(10) NOT NULL,
    source      TEXT,
    message     TEXT
);

CREATE TABLE heartbeats (
    user_id   UUID PRIMARY KEY REFERENCES users(id),
    user_type VARCHAR(20),
    last_seen TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    view      VARCHAR(100),
    platform  VARCHAR(20)
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
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
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
