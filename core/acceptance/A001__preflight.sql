\set ON_ERROR_STOP on
\echo 'PG-09 cumulative acceptance preflight'

DO $$
DECLARE v integer := current_setting('server_version_num')::integer;
DECLARE missing text;
BEGIN
    IF v < 180006 OR v >= 190000 THEN
        RAISE EXCEPTION 'Acceptance target requires PostgreSQL >=18.6 and <19.0; server_version_num=%', v;
    END IF;

    SELECT string_agg(req.name, ', ' ORDER BY req.name)
      INTO missing
      FROM (VALUES ('btree_gist'),('pgcrypto')) AS req(name)
      LEFT JOIN pg_available_extensions p ON p.name=req.name
     WHERE p.name IS NULL;
    IF missing IS NOT NULL THEN
        RAISE EXCEPTION 'Required extensions are not available: %', missing;
    END IF;

    IF NOT has_database_privilege(current_user,current_database(),'CREATE') THEN
        RAISE EXCEPTION 'Acceptance role % lacks CREATE privilege on database %',current_user,current_database();
    END IF;
END;
$$;

SELECT version() AS server_version,
       current_database() AS acceptance_database,
       current_user AS acceptance_role,
       current_setting('TimeZone') AS session_timezone;
