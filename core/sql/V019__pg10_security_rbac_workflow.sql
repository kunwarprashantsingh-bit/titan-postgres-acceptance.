-- Global Cement Sustainability Intelligence
-- PostgreSQL Implementation — PG-10 Security / RBAC / Workflow RLS
-- Requires V001-V018.
BEGIN;

CREATE SCHEMA IF NOT EXISTS titan_ops;

DO $$
DECLARE r text;
BEGIN
    FOREACH r IN ARRAY ARRAY[
        'titan_automation_ingest','titan_researcher','titan_senior_researcher',
        'titan_reviewer','titan_publisher','titan_data_steward',
        'titan_read_only_analyst','titan_db_admin','titan_migrator','titan_load_tester'
    ]
    LOOP
        IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname=r) THEN
            EXECUTE format(
                'CREATE ROLE %I NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS INHERIT',
                r
            );
        END IF;
        EXECUTE format(
            'ALTER ROLE %I NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS INHERIT',
            r
        );
    END LOOP;
END;
$$;

GRANT titan_researcher TO titan_senior_researcher;

REVOKE CREATE ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA titan_ref,titan_core,titan_migration,titan_ops FROM PUBLIC;

DO $$
DECLARE r text;
BEGIN
    FOREACH r IN ARRAY ARRAY[
        'titan_automation_ingest','titan_researcher','titan_senior_researcher',
        'titan_reviewer','titan_publisher','titan_data_steward',
        'titan_read_only_analyst','titan_db_admin','titan_migrator','titan_load_tester'
    ]
    LOOP
        EXECUTE format('REVOKE ALL ON ALL TABLES IN SCHEMA titan_ref,titan_core,titan_migration FROM %I',r);
        EXECUTE format('REVOKE ALL ON ALL SEQUENCES IN SCHEMA titan_ref,titan_core,titan_migration FROM %I',r);
        EXECUTE format('REVOKE ALL ON ALL FUNCTIONS IN SCHEMA titan_ref,titan_core,titan_migration FROM %I',r);
    END LOOP;
END;
$$;

GRANT USAGE ON SCHEMA titan_ref,titan_core TO
    titan_researcher,titan_senior_researcher,titan_reviewer,titan_publisher,
    titan_data_steward,titan_read_only_analyst,titan_migrator;

GRANT SELECT ON ALL TABLES IN SCHEMA titan_ref,titan_core TO
    titan_researcher,titan_senior_researcher,titan_reviewer,titan_publisher,
    titan_data_steward,titan_read_only_analyst;

GRANT USAGE ON SCHEMA titan_migration TO titan_automation_ingest,titan_researcher,titan_senior_researcher,titan_data_steward,titan_migrator;
GRANT SELECT,INSERT ON titan_migration.pg01_plant_identity_stage TO titan_automation_ingest;
GRANT SELECT,INSERT,UPDATE ON titan_migration.pg01_plant_identity_stage TO titan_researcher,titan_senior_researcher,titan_data_steward;

GRANT USAGE,CREATE ON SCHEMA titan_ref,titan_core,titan_migration,titan_ops TO titan_migrator;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA titan_ref,titan_core,titan_migration TO titan_migrator;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA titan_ref,titan_core,titan_migration TO titan_migrator;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA titan_ref,titan_core,titan_migration TO titan_migrator;

CREATE TABLE titan_ops.work_item (
    work_item_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    work_item_type text NOT NULL,
    subject_object_type text NOT NULL,
    subject_object_id text NULL,
    workflow_state text NOT NULL,
    source_id text NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    created_by_login name NOT NULL DEFAULT session_user,
    acting_role name NOT NULL DEFAULT current_user,
    assigned_to_login name NULL,
    assigned_reviewer_login name NULL,
    row_version bigint NOT NULL DEFAULT 1 CHECK (row_version>=1),
    payload jsonb NOT NULL DEFAULT '{}'::jsonb,
    transition_note text NULL,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_work_item_type CHECK (btrim(work_item_type)<>''),
    CONSTRAINT ck_work_item_subject_type CHECK (btrim(subject_object_type)<>''),
    CONSTRAINT ck_work_item_state CHECK (
        workflow_state IN (
            'RAW','STAGED','VALIDATED','DRAFT','REVIEW_PENDING','APPROVED','PUBLISHED',
            'QUARANTINED','REJECTED','SUPERSEDED','RETURNED','WITHDRAWN'
        )
    )
);

CREATE TABLE titan_ops.workflow_event (
    workflow_event_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    work_item_id uuid NOT NULL REFERENCES titan_ops.work_item(work_item_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    from_state text NULL,
    to_state text NOT NULL,
    row_version bigint NOT NULL,
    actor_login name NOT NULL,
    actor_role name NOT NULL,
    transition_note text NULL,
    occurred_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION titan_ops.reject_workflow_event_mutation()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION 'workflow_event is append-only';
END;
$$;

CREATE TRIGGER trg_workflow_event_immutable
BEFORE UPDATE OR DELETE ON titan_ops.workflow_event
FOR EACH ROW EXECUTE FUNCTION titan_ops.reject_workflow_event_mutation();

CREATE OR REPLACE FUNCTION titan_ops.validate_work_item_transition()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    is_super boolean;
    is_auto boolean := pg_has_role(current_user,'titan_automation_ingest','member');
    is_research boolean := pg_has_role(current_user,'titan_researcher','member');
    is_senior boolean := pg_has_role(current_user,'titan_senior_researcher','member');
    is_review boolean := pg_has_role(current_user,'titan_reviewer','member');
    is_publish boolean := pg_has_role(current_user,'titan_publisher','member');
    is_steward boolean := pg_has_role(current_user,'titan_data_steward','member');
    is_migrator boolean := pg_has_role(current_user,'titan_migrator','member');
    allowed boolean := false;
BEGIN
    SELECT rolsuper INTO is_super FROM pg_roles WHERE rolname=current_user;

    IF TG_OP='INSERT' THEN
        IF is_super OR is_migrator THEN
            allowed:=true;
        ELSIF is_auto AND NEW.workflow_state IN ('RAW','STAGED') THEN
            allowed:=true;
        ELSIF (is_research OR is_senior) AND NEW.workflow_state IN ('RAW','STAGED','VALIDATED','DRAFT') THEN
            allowed:=true;
        ELSIF is_steward AND NEW.workflow_state IN ('STAGED','QUARANTINED','RETURNED') THEN
            allowed:=true;
        END IF;
        IF NOT allowed THEN
            RAISE EXCEPTION 'Role % may not create work item in state %',current_user,NEW.workflow_state;
        END IF;
        NEW.created_by_login:=session_user;
        NEW.acting_role:=current_user;
        NEW.row_version:=1;
        NEW.updated_at:=CURRENT_TIMESTAMP;
        RETURN NEW;
    END IF;

    IF NEW.workflow_state=OLD.workflow_state THEN
        NEW.row_version:=OLD.row_version+1;
        NEW.acting_role:=current_user;
        NEW.updated_at:=CURRENT_TIMESTAMP;
        RETURN NEW;
    END IF;

    IF is_super OR is_migrator THEN
        allowed:=true;
    ELSIF (is_research OR is_senior) AND (
        (OLD.workflow_state='RAW' AND NEW.workflow_state='STAGED')
        OR (OLD.workflow_state='STAGED' AND NEW.workflow_state IN ('VALIDATED','DRAFT','QUARANTINED'))
        OR (OLD.workflow_state='VALIDATED' AND NEW.workflow_state='DRAFT')
        OR (OLD.workflow_state='DRAFT' AND NEW.workflow_state='REVIEW_PENDING')
        OR (OLD.workflow_state='RETURNED' AND NEW.workflow_state='DRAFT')
    ) THEN
        allowed:=true;
    ELSIF is_review AND OLD.workflow_state='REVIEW_PENDING'
          AND NEW.workflow_state IN ('APPROVED','RETURNED','REJECTED') THEN
        allowed:=true;
    ELSIF is_publish AND (
        (OLD.workflow_state='APPROVED' AND NEW.workflow_state='PUBLISHED')
        OR (OLD.workflow_state='PUBLISHED' AND NEW.workflow_state IN ('SUPERSEDED','WITHDRAWN'))
    ) THEN
        allowed:=true;
    ELSIF is_steward
          AND NEW.workflow_state IN ('QUARANTINED','RETURNED')
          AND OLD.workflow_state NOT IN ('PUBLISHED','SUPERSEDED','WITHDRAWN') THEN
        allowed:=true;
    END IF;

    IF NOT allowed THEN
        RAISE EXCEPTION 'Role % may not transition work item from % to %',current_user,OLD.workflow_state,NEW.workflow_state;
    END IF;

    NEW.row_version:=OLD.row_version+1;
    NEW.acting_role:=current_user;
    NEW.updated_at:=CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_work_item_transition
BEFORE INSERT OR UPDATE ON titan_ops.work_item
FOR EACH ROW EXECUTE FUNCTION titan_ops.validate_work_item_transition();

CREATE OR REPLACE FUNCTION titan_ops.append_workflow_event()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog,titan_ops
AS $$
BEGIN
    IF TG_OP='INSERT' OR NEW.workflow_state IS DISTINCT FROM OLD.workflow_state THEN
        INSERT INTO titan_ops.workflow_event
        (work_item_id,from_state,to_state,row_version,actor_login,actor_role,transition_note)
        VALUES (
            NEW.work_item_id,
            CASE WHEN TG_OP='INSERT' THEN NULL ELSE OLD.workflow_state END,
            NEW.workflow_state,
            NEW.row_version,
            session_user,
            NEW.acting_role,
            NEW.transition_note
        );
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_work_item_event
AFTER INSERT OR UPDATE ON titan_ops.work_item
FOR EACH ROW EXECUTE FUNCTION titan_ops.append_workflow_event();

CREATE OR REPLACE FUNCTION titan_ops.try_transition_work_item(
    p_work_item_id uuid,
    p_expected_row_version bigint,
    p_new_state text,
    p_note text DEFAULT NULL
)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE moved uuid;
BEGIN
    UPDATE titan_ops.work_item
       SET workflow_state=p_new_state,
           transition_note=p_note
     WHERE work_item_id=p_work_item_id
       AND row_version=p_expected_row_version
     RETURNING work_item_id INTO moved;
    RETURN moved IS NOT NULL;
END;
$$;

ALTER TABLE titan_ops.work_item ENABLE ROW LEVEL SECURITY;
ALTER TABLE titan_ops.work_item FORCE ROW LEVEL SECURITY;

CREATE POLICY p_work_auto ON titan_ops.work_item
TO titan_automation_ingest
USING (workflow_state IN ('RAW','STAGED'))
WITH CHECK (workflow_state IN ('RAW','STAGED'));

CREATE POLICY p_work_research ON titan_ops.work_item
TO titan_researcher,titan_senior_researcher
USING (workflow_state IN ('RAW','STAGED','VALIDATED','DRAFT','REVIEW_PENDING','RETURNED','QUARANTINED'))
WITH CHECK (workflow_state IN ('RAW','STAGED','VALIDATED','DRAFT','REVIEW_PENDING','RETURNED','QUARANTINED'));

CREATE POLICY p_work_review ON titan_ops.work_item
TO titan_reviewer
USING (workflow_state IN ('REVIEW_PENDING','APPROVED','RETURNED','REJECTED'))
WITH CHECK (workflow_state IN ('REVIEW_PENDING','APPROVED','RETURNED','REJECTED'));

CREATE POLICY p_work_publish ON titan_ops.work_item
TO titan_publisher
USING (workflow_state IN ('APPROVED','PUBLISHED','SUPERSEDED','WITHDRAWN'))
WITH CHECK (workflow_state IN ('APPROVED','PUBLISHED','SUPERSEDED','WITHDRAWN'));

CREATE POLICY p_work_steward ON titan_ops.work_item
TO titan_data_steward
USING (true) WITH CHECK (true);

CREATE POLICY p_work_migrator ON titan_ops.work_item
TO titan_migrator
USING (true) WITH CHECK (true);

REVOKE ALL ON ALL TABLES IN SCHEMA titan_ops FROM PUBLIC;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA titan_ops FROM PUBLIC;
REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA titan_ops FROM PUBLIC;

GRANT USAGE ON SCHEMA titan_ops TO
    titan_automation_ingest,titan_researcher,titan_senior_researcher,titan_reviewer,
    titan_publisher,titan_data_steward,titan_read_only_analyst,titan_db_admin,titan_migrator,titan_load_tester;

GRANT SELECT,INSERT ON titan_ops.work_item TO titan_automation_ingest;
GRANT SELECT,INSERT,UPDATE ON titan_ops.work_item TO titan_researcher,titan_senior_researcher,titan_data_steward;
GRANT SELECT,UPDATE ON titan_ops.work_item TO titan_reviewer,titan_publisher;
GRANT SELECT ON titan_ops.workflow_event TO titan_researcher,titan_senior_researcher,titan_reviewer,titan_publisher,titan_data_steward,titan_read_only_analyst,titan_db_admin;
GRANT EXECUTE ON FUNCTION titan_ops.try_transition_work_item(uuid,bigint,text,text)
TO titan_researcher,titan_senior_researcher,titan_reviewer,titan_publisher,titan_data_steward,titan_migrator;

DO $$
DECLARE r text;
BEGIN
    FOREACH r IN ARRAY ARRAY[
        'titan_automation_ingest','titan_researcher','titan_senior_researcher',
        'titan_reviewer','titan_publisher','titan_data_steward',
        'titan_read_only_analyst','titan_db_admin','titan_migrator','titan_load_tester'
    ]
    LOOP
        EXECUTE format('ALTER ROLE %I SET search_path TO pg_catalog,titan_ref,titan_core,titan_ops',r);
    END LOOP;
END;
$$;

ALTER DEFAULT PRIVILEGES IN SCHEMA titan_ref REVOKE ALL ON TABLES FROM PUBLIC;
ALTER DEFAULT PRIVILEGES IN SCHEMA titan_core REVOKE ALL ON TABLES FROM PUBLIC;
ALTER DEFAULT PRIVILEGES IN SCHEMA titan_migration REVOKE ALL ON TABLES FROM PUBLIC;
ALTER DEFAULT PRIVILEGES IN SCHEMA titan_ops REVOKE ALL ON TABLES FROM PUBLIC;
ALTER DEFAULT PRIVILEGES IN SCHEMA titan_ref REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;
ALTER DEFAULT PRIVILEGES IN SCHEMA titan_core REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;
ALTER DEFAULT PRIVILEGES IN SCHEMA titan_migration REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;
ALTER DEFAULT PRIVILEGES IN SCHEMA titan_ops REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;

COMMIT;
