-- docker/db/init/01_schema.sql
CREATE SCHEMA IF NOT EXISTS demand;

-- One normalized fact table
CREATE TABLE IF NOT EXISTS demand.jobs_like (
    id           BIGSERIAL PRIMARY KEY,
    city_id      INTEGER        NOT NULL,
    zone         TEXT           NOT NULL,
    ts           TIMESTAMPTZ    NOT NULL,
    user_type    TEXT           NOT NULL,  -- e.g. 'food' | 'rides'
    jobs_like    DOUBLE PRECISION NOT NULL,
    source_sheet TEXT           NULL       -- provenance: which Excel sheet
);

-- Helpful indexes
CREATE INDEX IF NOT EXISTS idx_jobs_like_city_ts   ON demand.jobs_like (city_id, ts);
CREATE INDEX IF NOT EXISTS idx_jobs_like_zone_ts   ON demand.jobs_like (zone, ts);
CREATE INDEX IF NOT EXISTS idx_jobs_like_user_ts   ON demand.jobs_like (user_type, ts);
CREATE INDEX IF NOT EXISTS idx_jobs_like_sheet     ON demand.jobs_like (source_sheet);
