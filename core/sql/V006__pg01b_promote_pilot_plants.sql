-- PG-01B pilot promotion into core registry and plant_master.
BEGIN;

DO $$
DECLARE n integer;
BEGIN
    SELECT count(*) INTO n
    FROM titan_migration.pg01_site_resolution_gate
    WHERE site_gate_passed AND migration_status='READY_FOR_PROMOTION';

    IF n <> 10 THEN
        RAISE EXCEPTION 'Promotion blocked: expected 10 site-gate-passed pilot rows, found %', n;
    END IF;

    SELECT count(*) INTO n
    FROM titan_core.entity_registry e
    JOIN titan_migration.pg01_plant_identity_stage s ON s.legacy_plant_id=e.entity_id;

    IF n <> 0 THEN
        RAISE EXCEPTION 'Promotion blocked: one or more pilot PL IDs already exist in entity_registry';
    END IF;
END;
$$;

INSERT INTO titan_core.entity_registry(entity_id,entity_type_code,canonical_name,country_geo_id)
SELECT legacy_plant_id,'PHYSICAL_PLANT',canonical_name,country_geo_id
FROM titan_migration.pg01_plant_identity_stage
WHERE migration_status='READY_FOR_PROMOTION'
ORDER BY legacy_plant_id;

INSERT INTO titan_core.plant_master(plant_id,site_id,plant_type_code)
SELECT legacy_plant_id,resolved_site_id,plant_type_code
FROM titan_migration.pg01_plant_identity_stage
WHERE migration_status='READY_FOR_PROMOTION'
ORDER BY legacy_plant_id;

UPDATE titan_migration.pg01_plant_identity_stage
SET migration_status='PROMOTED'
WHERE migration_status='READY_FOR_PROMOTION';

COMMIT;
