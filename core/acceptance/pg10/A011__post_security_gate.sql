\set ON_ERROR_STOP on
\echo 'PG-10 post-security-migration gate'

DO $$
DECLARE n_roles integer;
DECLARE bad_attrs integer;
DECLARE rls_ok integer;
DECLARE policies integer;
DECLARE core_dml integer;
DECLARE migrator_members integer;
DECLARE safe_fn integer;
DECLARE public_exec integer;
BEGIN
    SELECT count(*) INTO n_roles FROM pg_roles
    WHERE rolname IN (
        'titan_automation_ingest','titan_researcher','titan_senior_researcher',
        'titan_reviewer','titan_publisher','titan_data_steward',
        'titan_read_only_analyst','titan_db_admin','titan_migrator','titan_load_tester'
    );
    IF n_roles<>10 THEN RAISE EXCEPTION 'Expected 10 TITAN operational roles, found %',n_roles; END IF;

    SELECT count(*) INTO bad_attrs FROM pg_roles
    WHERE rolname IN (
        'titan_automation_ingest','titan_researcher','titan_senior_researcher',
        'titan_reviewer','titan_publisher','titan_data_steward',
        'titan_read_only_analyst','titan_db_admin','titan_migrator','titan_load_tester'
    )
    AND (rolsuper OR rolcreatedb OR rolcreaterole OR rolreplication OR rolbypassrls OR rolcanlogin);
    IF bad_attrs<>0 THEN RAISE EXCEPTION 'One or more TITAN group roles has prohibited attributes/login'; END IF;

    SELECT count(*) INTO rls_ok
    FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE n.nspname='titan_ops' AND c.relname='work_item'
      AND c.relrowsecurity AND c.relforcerowsecurity;
    IF rls_ok<>1 THEN RAISE EXCEPTION 'titan_ops.work_item must have RLS + FORCE RLS'; END IF;

    SELECT count(*) INTO policies
    FROM pg_policies WHERE schemaname='titan_ops' AND tablename='work_item';
    IF policies<>6 THEN RAISE EXCEPTION 'Expected 6 work_item RLS policies, found %',policies; END IF;

    SELECT count(*) INTO core_dml
    FROM (VALUES
        ('titan_automation_ingest'),('titan_researcher'),('titan_senior_researcher'),
        ('titan_reviewer'),('titan_publisher'),('titan_data_steward'),
        ('titan_read_only_analyst'),('titan_db_admin')
    ) r(role_name)
    WHERE has_table_privilege(role_name,'titan_core.entity_registry','INSERT')
       OR has_table_privilege(role_name,'titan_core.entity_registry','UPDATE')
       OR has_table_privilege(role_name,'titan_core.entity_registry','DELETE');
    IF core_dml<>0 THEN RAISE EXCEPTION 'Runtime role has direct curated-core DML'; END IF;

    SELECT count(*) INTO migrator_members
    FROM pg_auth_members m
    JOIN pg_roles granted ON granted.oid=m.roleid
    JOIN pg_roles member ON member.oid=m.member
    WHERE granted.rolname='titan_migrator'
      AND member.rolname<>'titan_migrator';
    IF migrator_members<>0 THEN RAISE EXCEPTION 'titan_migrator has runtime members'; END IF;

    SELECT count(*) INTO safe_fn
    FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
    WHERE n.nspname='titan_ops' AND p.proname='append_workflow_event'
      AND p.prosecdef
      AND EXISTS (
        SELECT 1 FROM unnest(COALESCE(p.proconfig,ARRAY[]::text[])) x
        WHERE x LIKE 'search_path=%pg_catalog%titan_ops%'
      );
    IF safe_fn<>1 THEN RAISE EXCEPTION 'SECURITY DEFINER audit function lacks fixed safe search_path'; END IF;

    SELECT count(*) INTO public_exec
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid=p.pronamespace
    CROSS JOIN LATERAL aclexplode(COALESCE(p.proacl,acldefault('f',p.proowner))) a
    WHERE n.nspname='titan_ops' AND a.grantee=0 AND a.privilege_type='EXECUTE';
    IF public_exec<>0 THEN RAISE EXCEPTION 'PUBLIC retains EXECUTE on titan_ops functions'; END IF;
END;
$$;

SELECT * FROM titan_ops.v_role_security_posture;
SELECT * FROM titan_ops.v_rls_inventory;
