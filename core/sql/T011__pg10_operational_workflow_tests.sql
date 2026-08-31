-- PG-10 Operational workflow / optimistic version / acceptance-evidence tests
\set ON_ERROR_STOP on
BEGIN;

SET ROLE titan_researcher;
INSERT INTO titan_ops.work_item(work_item_type,subject_object_type,subject_object_id,workflow_state,transition_note)
VALUES ('RECONCILIATION','PLANT','PL-IN-GJ-000003','DRAFT','optimistic-lock fixture')
RETURNING work_item_id AS pg10_opt_wid \gset

SELECT titan_ops.try_transition_work_item(:'pg10_opt_wid',1,'REVIEW_PENDING','writer A');
SELECT titan_ops.try_transition_work_item(:'pg10_opt_wid',1,'REVIEW_PENDING','stale writer B');
RESET ROLE;

DO $$
DECLARE st text;
DECLARE v bigint;
DECLARE events integer;
BEGIN
    SELECT workflow_state,row_version INTO st,v FROM titan_ops.work_item WHERE subject_object_id='PL-IN-GJ-000003' LIMIT 1;
    SELECT count(*) INTO events FROM titan_ops.workflow_event WHERE work_item_id=(SELECT work_item_id FROM titan_ops.work_item WHERE subject_object_id='PL-IN-GJ-000003' LIMIT 1);
    IF st<>'REVIEW_PENDING' OR v<>2 OR events<>2 THEN RAISE EXCEPTION 'PG10-T016 optimistic one-winner state/version/audit integrity failed'; END IF;
END;
$$;

SET ROLE titan_publisher;
DO $$
DECLARE visible integer;
BEGIN
    SELECT count(*) INTO visible FROM titan_ops.work_item WHERE subject_object_id='PL-IN-GJ-000003';
    IF visible<>0 THEN RAISE EXCEPTION 'PG10-T017 publisher RLS exposed REVIEW_PENDING research row'; END IF;
END;
$$;
RESET ROLE;

SET ROLE titan_researcher;
DO $$
DECLARE caught boolean:=false;
BEGIN
    BEGIN
        UPDATE titan_ops.workflow_event SET transition_note='tamper'
        WHERE work_item_id=(SELECT work_item_id FROM titan_ops.work_item WHERE subject_object_id='PL-IN-GJ-000003' LIMIT 1);
    EXCEPTION WHEN OTHERS THEN caught:=true; END;
    IF NOT caught THEN RAISE EXCEPTION 'PG10-T018 workflow audit mutation was not rejected'; END IF;
END;
$$;
RESET ROLE;

INSERT INTO titan_ops.operational_acceptance_run
(acceptance_suite,server_version,database_name,evidence_ref)
VALUES ('PG10 synthetic lifecycle',current_setting('server_version'),current_database(),'rollback://PG10')
RETURNING acceptance_run_id AS pg10_arid \gset

INSERT INTO titan_ops.operational_acceptance_metric
(acceptance_run_id,metric_name,metric_value,unit_text,pass_state)
VALUES (:'pg10_arid','synthetic_metric',1,'count','PASS');

UPDATE titan_ops.operational_acceptance_run
SET run_status='PASS',finished_at=CURRENT_TIMESTAMP
WHERE acceptance_run_id=:'pg10_arid';

DO $$
DECLARE caught_metric boolean:=false;
DECLARE caught_run boolean:=false;
BEGIN
    BEGIN
        INSERT INTO titan_ops.operational_acceptance_metric
        (acceptance_run_id,metric_name,metric_value)
        SELECT acceptance_run_id,'late_metric',2 FROM titan_ops.operational_acceptance_run WHERE acceptance_suite='PG10 synthetic lifecycle';
    EXCEPTION WHEN OTHERS THEN caught_metric:=true; END;
    IF NOT caught_metric THEN RAISE EXCEPTION 'PG10-T019 finalized acceptance run accepted late metric'; END IF;

    BEGIN
        UPDATE titan_ops.operational_acceptance_run
        SET evidence_ref='tampered'
        WHERE acceptance_suite='PG10 synthetic lifecycle';
    EXCEPTION WHEN OTHERS THEN caught_run:=true; END;
    IF NOT caught_run THEN RAISE EXCEPTION 'PG10-T020 finalized acceptance run mutation was not rejected'; END IF;
END;
$$;

SET ROLE titan_load_tester;
INSERT INTO titan_ops.operational_load_probe(worker_token,payload_hash)
VALUES (101,md5('PG10-load-probe'));

DO $$
DECLARE caught boolean:=false;
BEGIN
    BEGIN
        UPDATE titan_ops.operational_load_probe SET worker_token=202;
    EXCEPTION WHEN OTHERS THEN caught:=true; END;
    IF NOT caught THEN RAISE EXCEPTION 'PG10-T021 load tester unexpectedly received UPDATE privilege'; END IF;
END;
$$;
RESET ROLE;

DO $$
DECLARE rls_policies integer;
DECLARE bad_public_exec integer;
BEGIN
    SELECT count(*) INTO rls_policies FROM pg_policies
    WHERE schemaname='titan_ops' AND tablename='work_item';

    SELECT count(*) INTO bad_public_exec
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid=p.pronamespace
    CROSS JOIN LATERAL aclexplode(COALESCE(p.proacl,acldefault('f',p.proowner))) a
    WHERE n.nspname='titan_ops'
      AND a.grantee=0
      AND a.privilege_type='EXECUTE';

    IF rls_policies<>6 THEN RAISE EXCEPTION 'PG10-T022 expected 6 work_item RLS policies, found %',rls_policies; END IF;
    IF bad_public_exec<>0 THEN RAISE EXCEPTION 'PG10-T023 PUBLIC retains EXECUTE on titan_ops function(s)'; END IF;
END;
$$;

ROLLBACK;
\echo 'PG-10 operational workflow tests passed if execution reached this line.'
