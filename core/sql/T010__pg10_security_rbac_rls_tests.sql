-- PG-10 Security / RBAC / RLS acceptance tests
\set ON_ERROR_STOP on
BEGIN;

DO $$
DECLARE bad integer;
DECLARE core_dml integer;
BEGIN
    SELECT count(*) INTO bad
    FROM pg_roles
    WHERE rolname IN (
        'titan_automation_ingest','titan_researcher','titan_senior_researcher',
        'titan_reviewer','titan_publisher','titan_data_steward',
        'titan_read_only_analyst','titan_db_admin','titan_migrator','titan_load_tester'
    )
      AND (rolsuper OR rolcreatedb OR rolcreaterole OR rolreplication OR rolbypassrls OR rolcanlogin);
    IF bad<>0 THEN RAISE EXCEPTION 'PG10-T001 one or more TITAN group roles has prohibited cluster privileges/login'; END IF;

    SELECT count(*) INTO core_dml
    FROM (VALUES
        ('titan_automation_ingest'),('titan_researcher'),('titan_senior_researcher'),
        ('titan_reviewer'),('titan_publisher'),('titan_data_steward'),
        ('titan_read_only_analyst'),('titan_db_admin')
    ) r(role_name)
    WHERE has_table_privilege(role_name,'titan_core.entity_registry','INSERT')
       OR has_table_privilege(role_name,'titan_core.entity_registry','UPDATE')
       OR has_table_privilege(role_name,'titan_core.entity_registry','DELETE');
    IF core_dml<>0 THEN RAISE EXCEPTION 'PG10-T002 runtime roles received direct curated-core DML'; END IF;
END;
$$;

DO $$
DECLARE bad integer;
BEGIN
    SELECT count(*) INTO bad
    FROM (VALUES
        ('titan_automation_ingest'),('titan_researcher'),('titan_reviewer'),
        ('titan_publisher'),('titan_data_steward'),('titan_db_admin')
    ) r(role_name)
    WHERE has_schema_privilege(role_name,'public','CREATE')
       OR has_schema_privilege(role_name,'titan_core','CREATE');
    IF bad<>0 THEN RAISE EXCEPTION 'PG10-T003 runtime role can CREATE in public/titan_core'; END IF;
END;
$$;

SET ROLE titan_automation_ingest;
INSERT INTO titan_ops.work_item(work_item_type,subject_object_type,subject_object_id,workflow_state,payload,transition_note)
VALUES ('RESEARCH','PLANT','PL-IN-RJ-000002','RAW','{"fixture":"PG10"}'::jsonb,'automation intake')
RETURNING work_item_id AS pg10_wid \gset

DO $$
DECLARE caught boolean:=false;
BEGIN
    BEGIN
        INSERT INTO titan_core.entity_registry(entity_id,entity_type_code,canonical_name,country_geo_id)
        VALUES ('PG10-ILLEGAL-CORE','LEGAL_ENTITY','Illegal direct automation insert','CTY-IN');
    EXCEPTION WHEN OTHERS THEN caught:=true; END;
    IF NOT caught THEN RAISE EXCEPTION 'PG10-T004 automation direct curated-core write was not rejected'; END IF;
END;
$$;
RESET ROLE;

SET ROLE titan_researcher;
UPDATE titan_ops.work_item SET workflow_state='STAGED',transition_note='research staging'
WHERE work_item_id=:'pg10_wid' AND row_version=1;
UPDATE titan_ops.work_item SET workflow_state='VALIDATED',transition_note='research validation'
WHERE work_item_id=:'pg10_wid' AND row_version=2;
UPDATE titan_ops.work_item SET workflow_state='DRAFT',transition_note='research draft'
WHERE work_item_id=:'pg10_wid' AND row_version=3;
UPDATE titan_ops.work_item SET workflow_state='REVIEW_PENDING',transition_note='submit for review'
WHERE work_item_id=:'pg10_wid' AND row_version=4;

DO $$
DECLARE caught boolean:=false;
BEGIN
    BEGIN
        UPDATE titan_ops.work_item SET workflow_state='APPROVED'
        WHERE work_item_id=(SELECT work_item_id FROM titan_ops.work_item WHERE payload->>'fixture'='PG10' LIMIT 1);
    EXCEPTION WHEN OTHERS THEN caught:=true; END;
    IF NOT caught THEN RAISE EXCEPTION 'PG10-T005 researcher self-approval was not rejected'; END IF;
END;
$$;
RESET ROLE;

SET ROLE titan_reviewer;
UPDATE titan_ops.work_item SET workflow_state='APPROVED',transition_note='review approved'
WHERE work_item_id=:'pg10_wid' AND row_version=5;

DO $$
DECLARE caught boolean:=false;
BEGIN
    BEGIN
        UPDATE titan_ops.work_item SET workflow_state='PUBLISHED'
        WHERE work_item_id=(SELECT work_item_id FROM titan_ops.work_item WHERE payload->>'fixture'='PG10' LIMIT 1);
    EXCEPTION WHEN OTHERS THEN caught:=true; END;
    IF NOT caught THEN RAISE EXCEPTION 'PG10-T006 reviewer publication was not rejected'; END IF;
END;
$$;
RESET ROLE;

SET ROLE titan_publisher;
UPDATE titan_ops.work_item SET workflow_state='PUBLISHED',transition_note='publication release'
WHERE work_item_id=:'pg10_wid' AND row_version=6;

DO $$
DECLARE caught boolean:=false;
BEGIN
    BEGIN
        UPDATE titan_core.entity_registry SET canonical_name='ILLEGAL'
        WHERE entity_id='PL-IN-RJ-000002';
    EXCEPTION WHEN OTHERS THEN caught:=true; END;
    IF NOT caught THEN RAISE EXCEPTION 'PG10-T007 publisher direct curated-core mutation was not rejected'; END IF;
END;
$$;
RESET ROLE;

SET ROLE titan_read_only_analyst;
DO $$
DECLARE n integer;
DECLARE caught boolean:=false;
BEGIN
    SELECT count(*) INTO n FROM titan_core.entity_registry;
    IF n<10 THEN RAISE EXCEPTION 'PG10-T008 read-only analyst could not read curated core'; END IF;
    BEGIN
        UPDATE titan_core.entity_registry SET canonical_name='ILLEGAL'
        WHERE entity_id='PL-IN-RJ-000002';
    EXCEPTION WHEN OTHERS THEN caught:=true; END;
    IF NOT caught THEN RAISE EXCEPTION 'PG10-T009 read-only analyst write was not rejected'; END IF;
END;
$$;
RESET ROLE;

DO $$
DECLARE n_events integer;
DECLARE final_state text;
DECLARE final_version bigint;
DECLARE last_actor name;
DECLARE rls_ok integer;
DECLARE safe_fn integer;
BEGIN
    SELECT count(*),max(to_state) FILTER (WHERE row_version=7)
      INTO n_events,final_state
    FROM titan_ops.workflow_event
    WHERE work_item_id=(SELECT work_item_id FROM titan_ops.work_item WHERE payload->>'fixture'='PG10' LIMIT 1);

    SELECT workflow_state,row_version INTO final_state,final_version
    FROM titan_ops.work_item WHERE payload->>'fixture'='PG10' LIMIT 1;

    SELECT actor_role INTO last_actor
    FROM titan_ops.workflow_event
    WHERE work_item_id=(SELECT work_item_id FROM titan_ops.work_item WHERE payload->>'fixture'='PG10' LIMIT 1)
    ORDER BY row_version DESC LIMIT 1;

    SELECT count(*) INTO rls_ok
    FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE n.nspname='titan_ops' AND c.relname='work_item'
      AND c.relrowsecurity AND c.relforcerowsecurity;

    SELECT count(*) INTO safe_fn
    FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
    WHERE n.nspname='titan_ops' AND p.proname='append_workflow_event'
      AND p.prosecdef
      AND EXISTS (
        SELECT 1 FROM unnest(COALESCE(p.proconfig,ARRAY[]::text[])) x
        WHERE x LIKE 'search_path=%pg_catalog%titan_ops%'
      );

    IF n_events<>7 THEN RAISE EXCEPTION 'PG10-T010 expected 7 immutable workflow events, got %',n_events; END IF;
    IF final_state<>'PUBLISHED' OR final_version<>7 THEN RAISE EXCEPTION 'PG10-T011 final workflow state/version failed'; END IF;
    IF last_actor<>'titan_publisher' THEN RAISE EXCEPTION 'PG10-T012 audit actor role failed: %',last_actor; END IF;
    IF rls_ok<>1 THEN RAISE EXCEPTION 'PG10-T013 work_item RLS/FORCE RLS is not enabled'; END IF;
    IF safe_fn<>1 THEN RAISE EXCEPTION 'PG10-T014 SECURITY DEFINER audit function lacks fixed safe search_path'; END IF;
END;
$$;

DO $$
DECLARE bad integer;
BEGIN
    SELECT count(*) INTO bad
    FROM pg_auth_members m
    JOIN pg_roles granted ON granted.oid=m.roleid
    JOIN pg_roles member ON member.oid=m.member
    WHERE granted.rolname='titan_migrator'
      AND member.rolname IN (
        'titan_automation_ingest','titan_researcher','titan_senior_researcher',
        'titan_reviewer','titan_publisher','titan_data_steward',
        'titan_read_only_analyst','titan_db_admin','titan_load_tester'
      );
    IF bad<>0 THEN RAISE EXCEPTION 'PG10-T015 titan_migrator was granted to a runtime role'; END IF;
END;
$$;

ROLLBACK;
\echo 'PG-10 security/RBAC tests passed if execution reached this line.'
