-- docker/db/init/02_load_jobs_like.sql
-- CSV must have these exact headers/order:
-- city_id,zone,ts,user_type,jobs_like,source_sheet
COPY demand.jobs_like (city_id, zone, ts, user_type, jobs_like, source_sheet)
FROM '/docker-entrypoint-initdb.d/jobs_like.csv'
WITH (FORMAT csv, HEADER true);
