\set ON_ERROR_STOP on
\echo 'PG-10 security/operational preflight'

DO $$
DECLARE v integer := current_setting('server_version_num')::integer;
DECLARE is_super boolean;
BEGIN
    IF v < 180006 OR v >= 190000 THEN
        RAISE EXCEPTION 'PG-10 acceptance requires PostgreSQL >=18.6 and <19.0; server_version_num=%',v;
    END IF;

    SELECT rolsuper INTO is_super FROM pg_roles WHERE rolname=current_user;
    IF NOT is_super THEN
        RAISE EXCEPTION 'Disposable PG-10 security acceptance requires a superuser so group roles/grants can be created safely; current_user=%',current_user;
    END IF;
END;
$$;

SELECT current_user AS acceptance_admin,
       current_database() AS acceptance_database,
       current_setting('server_version') AS server_version;
