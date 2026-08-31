\set ON_ERROR_STOP on
CREATE TEMP TABLE titan_inventory(schema_name text,table_name text,row_count bigint);

DO $$
DECLARE r record;
DECLARE n bigint;
BEGIN
    FOR r IN
        SELECT n.nspname AS schema_name,c.relname AS table_name
        FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
        WHERE n.nspname IN ('titan_ref','titan_core','titan_migration','titan_ops')
          AND c.relkind='r'
        ORDER BY 1,2
    LOOP
        EXECUTE format('SELECT count(*) FROM %I.%I',r.schema_name,r.table_name) INTO n;
        INSERT INTO titan_inventory VALUES (r.schema_name,r.table_name,n);
    END LOOP;
END;
$$;

SELECT schema_name,table_name,row_count
FROM titan_inventory
ORDER BY schema_name,table_name;
