COPY demand.jobs_like (city_id, zone, ts, user_type, jobs_like, source_sheet)
FROM '/docker-entrypoint-initdb.d/jobs_like.csv'
WITH (FORMAT csv, HEADER true);
