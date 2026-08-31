-- PG-01 executable acceptance tests
-- Run only in a disposable test database after V001-V004.
-- All synthetic test records are rolled back.
\set ON_ERROR_STOP on

BEGIN;

-- Positive fixture.
INSERT INTO titan_core.entity_registry(entity_id,entity_type_code,canonical_name,country_geo_id)
VALUES ('SITE-IN-RJ-TST001','PHYSICAL_SITE','PG01 Synthetic Test Site','CTY-IN');

INSERT INTO titan_core.physical_site(site_id,primary_geo_id,site_status_code)
VALUES ('SITE-IN-RJ-TST001','SUB-IN-RJ','ACTIVE');

INSERT INTO titan_core.entity_registry(entity_id,entity_type_code,canonical_name,country_geo_id)
VALUES ('PL-IN-RJ-999999','PHYSICAL_PLANT','PG01 Synthetic Test Plant','CTY-IN');

INSERT INTO titan_core.plant_master(plant_id,site_id,plant_type_code)
VALUES ('PL-IN-RJ-999999','SITE-IN-RJ-TST001','INTEGRATED');

INSERT INTO titan_core.alias_history(entity_id,alias_text,alias_type_code,language_script)
VALUES ('PL-IN-RJ-999999','PG01 Test Plant','ABBREVIATION','en');

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM titan_core.plant_master p
        JOIN titan_core.entity_registry e ON e.entity_id = p.plant_id
        JOIN titan_core.physical_site s ON s.site_id = p.site_id
        WHERE p.plant_id='PL-IN-RJ-999999'
          AND e.entity_type_code='PHYSICAL_PLANT'
          AND s.site_id='SITE-IN-RJ-TST001'
    ) THEN
        RAISE EXCEPTION 'PG01-T001 positive plant/site relationship failed';
    END IF;
END;
$$;

-- Wrong prefix must fail.
DO $$
DECLARE caught boolean := false;
BEGIN
    BEGIN
        INSERT INTO titan_core.entity_registry(entity_id,entity_type_code,canonical_name,country_geo_id)
        VALUES ('CO-IN-999999','PHYSICAL_PLANT','Wrong Prefix Test','CTY-IN');
    EXCEPTION WHEN OTHERS THEN
        caught := true;
    END;
    IF NOT caught THEN RAISE EXCEPTION 'PG01-T002 wrong-prefix insert was not rejected'; END IF;
END;
$$;

-- Duplicate entity ID must fail.
DO $$
DECLARE caught boolean := false;
BEGIN
    BEGIN
        INSERT INTO titan_core.entity_registry(entity_id,entity_type_code,canonical_name,country_geo_id)
        VALUES ('PL-IN-RJ-999999','PHYSICAL_PLANT','Duplicate ID','CTY-IN');
    EXCEPTION WHEN unique_violation THEN
        caught := true;
    END;
    IF NOT caught THEN RAISE EXCEPTION 'PG01-T003 duplicate entity ID was not rejected'; END IF;
END;
$$;

-- Wrong child entity type must fail.
DO $$
DECLARE caught boolean := false;
BEGIN
    BEGIN
        INSERT INTO titan_core.plant_master(plant_id,site_id,plant_type_code)
        VALUES ('SITE-IN-RJ-TST001','SITE-IN-RJ-TST001','INTEGRATED');
    EXCEPTION WHEN OTHERS THEN
        caught := true;
    END;
    IF NOT caught THEN RAISE EXCEPTION 'PG01-T004 typed-child mismatch was not rejected'; END IF;
END;
$$;

-- Orphan site FK must fail.
DO $$
DECLARE caught boolean := false;
BEGIN
    BEGIN
        INSERT INTO titan_core.entity_registry(entity_id,entity_type_code,canonical_name,country_geo_id)
        VALUES ('PL-IN-RJ-999998','PHYSICAL_PLANT','Orphan Site Test','CTY-IN');
        INSERT INTO titan_core.plant_master(plant_id,site_id,plant_type_code)
        VALUES ('PL-IN-RJ-999998','SITE-IN-RJ-NOTFOUND','INTEGRATED');
    EXCEPTION WHEN foreign_key_violation THEN
        caught := true;
    END;
    IF NOT caught THEN RAISE EXCEPTION 'PG01-T005 orphan site was not rejected'; END IF;
END;
$$;

-- Invalid alias dates must fail.
DO $$
DECLARE caught boolean := false;
BEGIN
    BEGIN
        INSERT INTO titan_core.alias_history(entity_id,alias_text,alias_type_code,valid_from,valid_to)
        VALUES ('PL-IN-RJ-999999','Bad Date Alias','HISTORICAL',DATE '2026-12-31',DATE '2026-01-01');
    EXCEPTION WHEN check_violation THEN
        caught := true;
    END;
    IF NOT caught THEN RAISE EXCEPTION 'PG01-T006 invalid alias interval was not rejected'; END IF;
END;
$$;

-- Self genealogy must fail.
DO $$
DECLARE caught boolean := false;
BEGIN
    BEGIN
        INSERT INTO titan_core.genealogy_relationship(from_entity_id,to_entity_id,genealogy_type_code,effective_date)
        VALUES ('PL-IN-RJ-999999','PL-IN-RJ-999999','PREDECESSOR_OF',DATE '2026-01-01');
    EXCEPTION WHEN check_violation THEN
        caught := true;
    END;
    IF NOT caught THEN RAISE EXCEPTION 'PG01-T007 self-genealogy was not rejected'; END IF;
END;
$$;

-- Invalid genealogy scope fraction must fail.
INSERT INTO titan_core.entity_registry(entity_id,entity_type_code,canonical_name,country_geo_id)
VALUES ('PL-IN-RJ-999997','PHYSICAL_PLANT','Second Test Plant','CTY-IN');

DO $$
DECLARE caught boolean := false;
BEGIN
    BEGIN
        INSERT INTO titan_core.genealogy_relationship(from_entity_id,to_entity_id,genealogy_type_code,scope_fraction)
        VALUES ('PL-IN-RJ-999999','PL-IN-RJ-999997','SPLIT_INTO',1.25);
    EXCEPTION WHEN check_violation THEN
        caught := true;
    END;
    IF NOT caught THEN RAISE EXCEPTION 'PG01-T008 invalid genealogy fraction was not rejected'; END IF;
END;
$$;

-- Entity ID and type are immutable.
DO $$
DECLARE caught boolean := false;
BEGIN
    BEGIN
        UPDATE titan_core.entity_registry
           SET entity_id='PL-IN-RJ-999996'
         WHERE entity_id='PL-IN-RJ-999999';
    EXCEPTION WHEN OTHERS THEN
        caught := true;
    END;
    IF NOT caught THEN RAISE EXCEPTION 'PG01-T009 entity_id mutation was not rejected'; END IF;
END;
$$;

-- Country field must point at a country geography.
DO $$
DECLARE caught boolean := false;
BEGIN
    BEGIN
        INSERT INTO titan_core.entity_registry(entity_id,entity_type_code,canonical_name,country_geo_id)
        VALUES ('PL-IN-RJ-999996','PHYSICAL_PLANT','Wrong Country Geo','SUB-IN-RJ');
    EXCEPTION WHEN OTHERS THEN
        caught := true;
    END;
    IF NOT caught THEN RAISE EXCEPTION 'PG01-T010 non-country country_geo_id was not rejected'; END IF;
END;
$$;

-- Coordinate pair/ranges must be valid.
DO $$
DECLARE caught boolean := false;
BEGIN
    BEGIN
        INSERT INTO titan_core.site_location_observation(site_id,latitude,longitude)
        VALUES ('SITE-IN-RJ-TST001',95,75);
    EXCEPTION WHEN check_violation THEN
        caught := true;
    END;
    IF NOT caught THEN RAISE EXCEPTION 'PG01-T011 invalid latitude was not rejected'; END IF;
END;
$$;

-- Pilot manifest must contain exactly ten preserved plant IDs and no prematurely minted site IDs.
DO $$
DECLARE total_rows integer;
DECLARE distinct_ids integer;
DECLARE minted_sites integer;
BEGIN
    SELECT count(*), count(DISTINCT legacy_plant_id), count(resolved_site_id)
      INTO total_rows, distinct_ids, minted_sites
      FROM titan_migration.pg01_plant_identity_stage;

    IF total_rows <> 10 THEN
        RAISE EXCEPTION 'PG01-T012 expected 10 pilot rows, got %', total_rows;
    END IF;
    IF distinct_ids <> 10 THEN
        RAISE EXCEPTION 'PG01-T013 pilot plant IDs are not unique';
    END IF;
    IF minted_sites <> 0 THEN
        RAISE EXCEPTION 'PG01-T014 permanent SITE IDs were minted before site-resolution screen';
    END IF;
END;
$$;

ROLLBACK;

\echo 'PG-01 constraint tests passed if execution reached this line.'
