-- Reverse of 000001_init_schema.up.sql
-- Drop in reverse dependency order

-- 3.10 Gear Cloud (drop first — foreign key refs to gear_sets)
DROP INDEX IF EXISTS idx_gear_set_meals_set_id;
DROP TABLE IF EXISTS gear_set_meals;
DROP INDEX IF EXISTS idx_gear_set_items_set_id;
DROP TABLE IF EXISTS gear_set_items;
DROP INDEX IF EXISTS idx_gear_sets_user_id;
DROP INDEX IF EXISTS idx_gear_sets_visibility;
DROP TABLE IF EXISTS gear_sets;

DROP INDEX IF EXISTS idx_weather_start_time;
DROP INDEX IF EXISTS idx_weather_location;
DROP TABLE IF EXISTS weather_data;
DROP TRIGGER IF EXISTS trg_system_flags_changes ON system_flags;
DROP FUNCTION IF EXISTS log_system_flags_changes();
DROP TABLE IF EXISTS system_flags_history;
DROP TABLE IF EXISTS system_flags;
DROP TABLE IF EXISTS heartbeats;
DROP TABLE IF EXISTS favorites;
DROP INDEX IF EXISTS idx_logs_level;
DROP INDEX IF EXISTS idx_logs_timestamp;
DROP TABLE IF EXISTS logs;
DROP TABLE IF EXISTS group_event_likes;
DROP TABLE IF EXISTS group_event_comments;
DROP TABLE IF EXISTS group_event_applications;
DROP TABLE IF EXISTS group_events;
DROP TABLE IF EXISTS poll_votes;
DROP TABLE IF EXISTS poll_options;
DROP TABLE IF EXISTS polls;
DROP TABLE IF EXISTS template_meal_items;
DROP TABLE IF EXISTS template_gear_items;
DROP TABLE IF EXISTS templates;
DROP TABLE IF EXISTS meal_items;
DROP TABLE IF EXISTS trip_meal_plan_days;
DROP TABLE IF EXISTS meal_library_items;
DROP TABLE IF EXISTS gear_items;
DROP TABLE IF EXISTS gear_library_items;
DROP TABLE IF EXISTS messages;
DROP TABLE IF EXISTS itinerary_items;
DROP TABLE IF EXISTS trip_members;
DROP TABLE IF EXISTS trips;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS role_permissions;
DROP TABLE IF EXISTS permissions;
DROP TABLE IF EXISTS roles;

DROP EXTENSION IF EXISTS pg_trgm;
