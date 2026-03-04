-- Reverse of 000001_init_schema.up.sql
-- Drop in reverse dependency order

DROP TABLE IF EXISTS heartbeats;
DROP TABLE IF EXISTS logs;
DROP TABLE IF EXISTS favorites;
DROP TABLE IF EXISTS group_event_likes;
DROP TABLE IF EXISTS group_event_comments;
DROP TABLE IF EXISTS group_event_applications;
DROP TABLE IF EXISTS group_events;
DROP TABLE IF EXISTS poll_votes;
DROP TABLE IF EXISTS poll_options;
DROP TABLE IF EXISTS polls;
DROP TABLE IF EXISTS meal_items;
DROP TABLE IF EXISTS gear_set_items;
DROP TABLE IF EXISTS gear_sets;
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
