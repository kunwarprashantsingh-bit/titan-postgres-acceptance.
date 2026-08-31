\set ON_ERROR_STOP on
\echo 'PG-10 post-test residue gate'

DO $$
DECLARE work_rows integer;
DECLARE event_rows integer;
DECLARE acceptance_rows integer;
DECLARE metric_rows integer;
DECLARE load_rows integer;
DECLARE recovery_rows integer;
BEGIN
    SELECT count(*) INTO work_rows FROM titan_ops.work_item;
    SELECT count(*) INTO event_rows FROM titan_ops.workflow_event;
    SELECT count(*) INTO acceptance_rows FROM titan_ops.operational_acceptance_run;
    SELECT count(*) INTO metric_rows FROM titan_ops.operational_acceptance_metric;
    SELECT count(*) INTO load_rows FROM titan_ops.operational_load_probe;
    SELECT count(*) INTO recovery_rows FROM titan_ops.recovery_probe;

    IF work_rows<>0 OR event_rows<>0 OR acceptance_rows<>0 OR metric_rows<>0 OR load_rows<>0 OR recovery_rows<>0 THEN
        RAISE EXCEPTION 'Rollback tests left titan_ops residue: work %, events %, runs %, metrics %, load %, recovery %',
            work_rows,event_rows,acceptance_rows,metric_rows,load_rows,recovery_rows;
    END IF;
END;
$$;
