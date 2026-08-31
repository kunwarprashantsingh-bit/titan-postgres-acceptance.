\set ON_ERROR_STOP on
\echo 'PG-09 post-test residue and integrity gate'

DO $$
DECLARE synthetic_sources integer;
DECLARE synthetic_entities integer;
DECLARE promoted integer;
BEGIN
    SELECT count(*) INTO synthetic_sources
    FROM titan_core.source_document
    WHERE authoritative_status='SYNTHETIC';
    IF synthetic_sources<>0 THEN
        RAISE EXCEPTION 'Acceptance tests left % synthetic source_document rows behind',synthetic_sources;
    END IF;

    SELECT count(*) INTO synthetic_entities
    FROM titan_core.entity_registry
    WHERE entity_id LIKE '%-TEST' OR entity_id LIKE '%-TST' OR entity_id LIKE '%PG08-%' OR entity_id LIKE '%PG07-%';
    IF synthetic_entities<>0 THEN
        RAISE EXCEPTION 'Acceptance tests left % synthetic entity rows behind',synthetic_entities;
    END IF;

    SELECT count(*) INTO promoted
    FROM titan_migration.pg01_plant_identity_stage
    WHERE migration_status='PROMOTED';
    IF promoted<>10 THEN
        RAISE EXCEPTION 'Expected 10 promoted pilot identities after all tests, found %',promoted;
    END IF;
END;
$$;

SELECT count(*) AS pilot_plants FROM titan_core.plant_master
WHERE plant_id LIKE 'PL-IN-%' OR plant_id LIKE 'PL-CN-%';
