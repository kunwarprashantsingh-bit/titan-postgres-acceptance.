-- PG-01 migration staging and physical-site issuance gate
BEGIN;

CREATE TABLE titan_migration.pg01_plant_identity_stage (
    legacy_plant_id text PRIMARY KEY,
    canonical_name text NOT NULL,
    country_geo_id text NOT NULL
        REFERENCES titan_core.geo_unit(geo_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    admin1_geo_id text NOT NULL
        REFERENCES titan_core.geo_unit(geo_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    plant_type_code text NOT NULL
        REFERENCES titan_ref.plant_type(plant_type_code)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    source_baseline text NOT NULL,
    source_as_of date NOT NULL,
    site_resolution_status text NOT NULL DEFAULT 'NOT_SCREENED',
    resolved_site_id text NULL,
    site_resolution_notes text NULL,
    migration_status text NOT NULL DEFAULT 'STAGED',
    staged_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_pg01_plant_id_format CHECK (legacy_plant_id ~ '^PL-[A-Z]{2}-[A-Z0-9]{2,3}-[0-9]{6}$'),
    CONSTRAINT ck_pg01_site_resolution_status CHECK (
        site_resolution_status IN (
            'NOT_SCREENED',
            'UNIQUE_SITE_CONFIRMED',
            'COLOCATED_EXISTING_SITE',
            'POTENTIAL_DUPLICATE',
            'BLOCKED_EVIDENCE'
        )
    ),
    CONSTRAINT ck_pg01_migration_status CHECK (
        migration_status IN ('STAGED','READY_FOR_PROMOTION','BLOCKED','PROMOTED','REJECTED')
    ),
    CONSTRAINT ck_pg01_site_gate CHECK (
        (site_resolution_status IN ('UNIQUE_SITE_CONFIRMED','COLOCATED_EXISTING_SITE')
            AND resolved_site_id IS NOT NULL)
        OR
        (site_resolution_status NOT IN ('UNIQUE_SITE_CONFIRMED','COLOCATED_EXISTING_SITE'))
    )
);

CREATE VIEW titan_migration.pg01_site_resolution_gate AS
SELECT
    legacy_plant_id,
    canonical_name,
    country_geo_id,
    admin1_geo_id,
    plant_type_code,
    site_resolution_status,
    resolved_site_id,
    migration_status,
    CASE
        WHEN site_resolution_status IN ('UNIQUE_SITE_CONFIRMED','COLOCATED_EXISTING_SITE')
         AND resolved_site_id IS NOT NULL
        THEN true
        ELSE false
    END AS site_gate_passed
FROM titan_migration.pg01_plant_identity_stage;

COMMIT;
