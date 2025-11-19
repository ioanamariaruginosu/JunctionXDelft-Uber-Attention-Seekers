CREATE OR REPLACE VIEW demand.jobs_like_levels AS
SELECT
  city_id,
  zone,
  ts,
  user_type,
  jobs_like,
  CASE
    WHEN jobs_like >= 0.66 THEN 'high'
    WHEN jobs_like >= 0.33 THEN 'med'
    ELSE 'low'
  END AS level
FROM demand.jobs_like;
