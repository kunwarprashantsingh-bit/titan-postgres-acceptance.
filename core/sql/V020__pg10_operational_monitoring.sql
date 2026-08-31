-- Global Cement Sustainability Intelligence
-- PostgreSQL Implementation — PG-10 Operational Evidence / Monitoring
-- Requires V019.
BEGIN;

CREATE TABLE titan_ops.operational_acceptance_run (
    acceptance_run_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    acceptance_suite text NOT NULL,
    run_status text NOT NULL DEFAULT 'RUNNING',
    server_version text NOT NULL,
    database_name text NOT NULL,
    started_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    finished_at timestamptz NULL,
    evidence_ref text NULL,
    run_notes text NULL,
    CONSTRAINT ck_acceptance_suite CHECK (btrim(acceptance_suite)<>''),
    CONSTRAINT ck_acceptance_run_status CHECK (run_status IN ('RUNNING','PASS','FAIL')),
    CONSTRAINT ck_acceptance_finish CHECK (
        (run_status='RUNNING' AND finished_at IS NULL)
        OR (run_status IN ('PASS','FAIL') AND finished_at IS NOT NULL)
    )
);

CREATE TABLE titan_ops.operational_acceptance_metric (
    acceptance_metric_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    acceptance_run_id uuid NOT NULL REFERENCES titan_ops.operational_acceptance_run(acceptance_run_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    metric_name text NOT NULL,
    metric_value numeric NULL,
    metric_text text NULL,
    unit_text text NULL,
    pass_state text NULL CHECK (pass_state IS NULL OR pass_state IN ('PASS','FAIL','OBSERVE')),
    recorded_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_acceptance_metric_name CHECK (btrim(metric_name)<>''),
    CONSTRAINT ck_acceptance_metric_payload CHECK (metric_value IS NOT NULL OR metric_text IS NOT NULL)
);

CREATE OR REPLACE FUNCTION titan_ops.validate_acceptance_run_transition()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    IF TG_OP='DELETE' THEN
        RAISE EXCEPTION 'operational_acceptance_run is retained';
    END IF;
    IF OLD.run_status='RUNNING' AND NEW.run_status IN ('RUNNING','PASS','FAIL') THEN
        RETURN NEW;
    END IF;
    IF OLD.run_status IN ('PASS','FAIL') AND NEW IS DISTINCT FROM OLD THEN
        RAISE EXCEPTION 'Final acceptance run is immutable';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_acceptance_run_transition
BEFORE UPDATE OR DELETE ON titan_ops.operational_acceptance_run
FOR EACH ROW EXECUTE FUNCTION titan_ops.validate_acceptance_run_transition();

CREATE OR REPLACE FUNCTION titan_ops.validate_acceptance_metric_insert()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE st text;
BEGIN
    SELECT run_status INTO st FROM titan_ops.operational_acceptance_run WHERE acceptance_run_id=NEW.acceptance_run_id;
    IF st<>'RUNNING' THEN
        RAISE EXCEPTION 'Metrics may be added only while acceptance run is RUNNING';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_acceptance_metric_insert
BEFORE INSERT ON titan_ops.operational_acceptance_metric
FOR EACH ROW EXECUTE FUNCTION titan_ops.validate_acceptance_metric_insert();

CREATE OR REPLACE FUNCTION titan_ops.reject_acceptance_metric_mutation()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION 'operational_acceptance_metric is append-only';
END;
$$;

CREATE TRIGGER trg_acceptance_metric_immutable
BEFORE UPDATE OR DELETE ON titan_ops.operational_acceptance_metric
FOR EACH ROW EXECUTE FUNCTION titan_ops.reject_acceptance_metric_mutation();

CREATE TABLE titan_ops.operational_load_probe (
    load_probe_id bigserial PRIMARY KEY,
    worker_token bigint NOT NULL,
    payload_hash text NOT NULL,
    inserted_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_load_probe_hash CHECK (payload_hash ~ '^[0-9a-fA-F]{32,64}$')
);

CREATE TABLE titan_ops.recovery_probe (
    recovery_probe_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    marker_text text NOT NULL UNIQUE,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    probe_notes text NULL,
    CONSTRAINT ck_recovery_probe_marker CHECK (btrim(marker_text)<>'')
);

CREATE VIEW titan_ops.v_database_health AS
SELECT datname,numbackends,xact_commit,xact_rollback,temp_files,temp_bytes,deadlocks,checksum_failures,stats_reset
FROM pg_stat_database
WHERE datname=current_database();

CREATE VIEW titan_ops.v_role_security_posture AS
SELECT rolname,rolsuper,rolcreaterole,rolcreatedb,rolreplication,rolbypassrls,rolcanlogin,rolconnlimit
FROM pg_roles
WHERE rolname LIKE 'titan_%'
ORDER BY rolname;

CREATE VIEW titan_ops.v_rls_inventory AS
SELECT
    c.oid::regclass::text AS relation_name,
    c.relrowsecurity AS rls_enabled,
    c.relforcerowsecurity AS rls_forced,
    p.policyname,p.roles,p.cmd,p.qual,p.with_check
FROM pg_class c
JOIN pg_namespace n ON n.oid=c.relnamespace
LEFT JOIN pg_policies p ON p.schemaname=n.nspname AND p.tablename=c.relname
WHERE n.nspname='titan_ops'
ORDER BY relation_name,policyname;

REVOKE ALL ON titan_ops.operational_acceptance_run,titan_ops.operational_acceptance_metric,titan_ops.operational_load_probe,titan_ops.recovery_probe FROM PUBLIC;
REVOKE ALL ON SEQUENCE titan_ops.operational_load_probe_load_probe_id_seq FROM PUBLIC;
REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA titan_ops FROM PUBLIC;

GRANT SELECT ON titan_ops.v_database_health TO titan_db_admin,titan_data_steward,titan_read_only_analyst;
GRANT SELECT ON titan_ops.v_role_security_posture,titan_ops.v_rls_inventory TO titan_db_admin,titan_data_steward;
GRANT INSERT,SELECT ON titan_ops.operational_load_probe TO titan_load_tester;
GRANT USAGE,SELECT ON SEQUENCE titan_ops.operational_load_probe_load_probe_id_seq TO titan_load_tester;

COMMIT;
