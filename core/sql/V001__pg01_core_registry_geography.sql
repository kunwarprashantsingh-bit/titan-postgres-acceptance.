-- Global Cement Sustainability Intelligence
-- PostgreSQL Implementation v1.0 — PG-01 Core Registry & Geography
-- Architecture baseline: Global Cement Sustainability Intelligence Architecture v1.0 FROZEN
-- Target: PostgreSQL 18.x, current supported minor/security release
-- Execution policy: psql -v ON_ERROR_STOP=1
--
-- IMPORTANT:
-- 1) Existing TITAN PL/KL/GR/QR/PW/WHR identifiers are preserved.
-- 2) Controlled classifications use reference tables, not PostgreSQL ENUM types.
-- 3) This migration defines production tables. Existing plants are NOT promoted
--    until a permanent physical SITE identity has passed the site-resolution gate.
-- 4) source_id columns are retained as text in PG-01; formal FK linkage is added in PG-03.

BEGIN;

CREATE SCHEMA IF NOT EXISTS titan_ref;
CREATE SCHEMA IF NOT EXISTS titan_core;
CREATE SCHEMA IF NOT EXISTS titan_migration;

CREATE TABLE titan_ref.entity_type (
    entity_type_code text PRIMARY KEY,
    id_prefix text NOT NULL UNIQUE,
    domain_name text NOT NULL,
    definition text NOT NULL,
    is_active boolean NOT NULL DEFAULT true,
    CONSTRAINT ck_entity_type_code_nonblank CHECK (btrim(entity_type_code) <> ''),
    CONSTRAINT ck_entity_type_prefix_nonblank CHECK (btrim(id_prefix) <> '')
);

CREATE TABLE titan_ref.geo_type (
    geo_type_code text PRIMARY KEY,
    entity_type_code text NOT NULL REFERENCES titan_ref.entity_type(entity_type_code) ON UPDATE RESTRICT ON DELETE RESTRICT,
    hierarchy_rank smallint NOT NULL CHECK (hierarchy_rank >= 0),
    definition text NOT NULL
);

CREATE TABLE titan_ref.site_status (
    site_status_code text PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_ref.plant_type (
    plant_type_code text PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_ref.alias_type (
    alias_type_code text PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_ref.genealogy_type (
    genealogy_type_code text PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_core.entity_registry (
    entity_id text PRIMARY KEY,
    entity_type_code text NOT NULL
        REFERENCES titan_ref.entity_type(entity_type_code)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    canonical_name text NOT NULL,
    country_geo_id text NULL,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    retired_at timestamptz NULL,
    row_version bigint NOT NULL DEFAULT 1,
    CONSTRAINT ck_entity_name_nonblank CHECK (btrim(canonical_name) <> ''),
    CONSTRAINT ck_entity_row_version CHECK (row_version >= 1),
    CONSTRAINT ck_entity_retirement_time CHECK (retired_at IS NULL OR retired_at >= created_at)
);

CREATE TABLE titan_core.geo_unit (
    geo_id text PRIMARY KEY
        REFERENCES titan_core.entity_registry(entity_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
        DEFERRABLE INITIALLY DEFERRED,
    geo_type_code text NOT NULL
        REFERENCES titan_ref.geo_type(geo_type_code)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    parent_geo_id text NULL
        REFERENCES titan_core.geo_unit(geo_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT
        DEFERRABLE INITIALLY DEFERRED,
    official_name text NOT NULL,
    iso_alpha2 char(2) NULL,
    iso_3166_2 text NULL,
    valid_from date NULL,
    valid_to date NULL,
    recorded_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_geo_name_nonblank CHECK (btrim(official_name) <> ''),
    CONSTRAINT ck_geo_dates CHECK (valid_to IS NULL OR valid_from IS NULL OR valid_to >= valid_from),
    CONSTRAINT ck_geo_not_own_parent CHECK (parent_geo_id IS NULL OR parent_geo_id <> geo_id)
);

CREATE UNIQUE INDEX uq_geo_iso_alpha2
    ON titan_core.geo_unit (iso_alpha2)
    WHERE iso_alpha2 IS NOT NULL;

CREATE UNIQUE INDEX uq_geo_iso_3166_2
    ON titan_core.geo_unit (iso_3166_2)
    WHERE iso_3166_2 IS NOT NULL;

ALTER TABLE titan_core.entity_registry
    ADD CONSTRAINT fk_entity_country_geo
    FOREIGN KEY (country_geo_id)
    REFERENCES titan_core.geo_unit(geo_id)
    ON UPDATE RESTRICT ON DELETE RESTRICT
    DEFERRABLE INITIALLY DEFERRED;

CREATE TABLE titan_core.physical_site (
    site_id text PRIMARY KEY
        REFERENCES titan_core.entity_registry(entity_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    primary_geo_id text NOT NULL
        REFERENCES titan_core.geo_unit(geo_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    site_status_code text NOT NULL
        REFERENCES titan_ref.site_status(site_status_code)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    geometry_ref text NULL,
    recorded_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    row_version bigint NOT NULL DEFAULT 1 CHECK (row_version >= 1)
);

CREATE TABLE titan_core.site_location_observation (
    site_location_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    site_id text NOT NULL
        REFERENCES titan_core.physical_site(site_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    latitude numeric(9,6) NULL,
    longitude numeric(9,6) NULL,
    coordinate_accuracy_m numeric(12,3) NULL,
    coordinate_method text NULL,
    source_id text NULL,
    valid_from date NULL,
    valid_to date NULL,
    recorded_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_site_latitude CHECK (latitude IS NULL OR latitude BETWEEN -90 AND 90),
    CONSTRAINT ck_site_longitude CHECK (longitude IS NULL OR longitude BETWEEN -180 AND 180),
    CONSTRAINT ck_site_coordinate_pair CHECK (
        (latitude IS NULL AND longitude IS NULL)
        OR (latitude IS NOT NULL AND longitude IS NOT NULL)
    ),
    CONSTRAINT ck_site_accuracy CHECK (coordinate_accuracy_m IS NULL OR coordinate_accuracy_m >= 0),
    CONSTRAINT ck_site_location_dates CHECK (valid_to IS NULL OR valid_from IS NULL OR valid_to >= valid_from)
);

CREATE TABLE titan_core.site_address_history (
    site_address_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    site_id text NOT NULL
        REFERENCES titan_core.physical_site(site_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    address_text text NOT NULL,
    locality_text text NULL,
    postal_code text NULL,
    source_id text NULL,
    valid_from date NULL,
    valid_to date NULL,
    recorded_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_site_address_nonblank CHECK (btrim(address_text) <> ''),
    CONSTRAINT ck_site_address_dates CHECK (valid_to IS NULL OR valid_from IS NULL OR valid_to >= valid_from)
);

CREATE TABLE titan_core.plant_master (
    plant_id text PRIMARY KEY
        REFERENCES titan_core.entity_registry(entity_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    site_id text NOT NULL
        REFERENCES titan_core.physical_site(site_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    plant_type_code text NOT NULL
        REFERENCES titan_ref.plant_type(plant_type_code)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    recorded_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    row_version bigint NOT NULL DEFAULT 1 CHECK (row_version >= 1)
);

CREATE INDEX ix_plant_master_site_id
    ON titan_core.plant_master(site_id);

CREATE TABLE titan_core.alias_history (
    alias_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    entity_id text NOT NULL
        REFERENCES titan_core.entity_registry(entity_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    alias_text text NOT NULL,
    alias_type_code text NOT NULL
        REFERENCES titan_ref.alias_type(alias_type_code)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    language_script text NULL,
    valid_from date NULL,
    valid_to date NULL,
    source_id text NULL,
    recorded_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_alias_nonblank CHECK (btrim(alias_text) <> ''),
    CONSTRAINT ck_alias_dates CHECK (valid_to IS NULL OR valid_from IS NULL OR valid_to >= valid_from)
);

CREATE UNIQUE INDEX uq_alias_identity
    ON titan_core.alias_history (
        entity_id,
        alias_type_code,
        lower(alias_text),
        COALESCE(valid_from, DATE '0001-01-01')
    );

CREATE TABLE titan_core.genealogy_relationship (
    relationship_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    from_entity_id text NOT NULL
        REFERENCES titan_core.entity_registry(entity_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    to_entity_id text NOT NULL
        REFERENCES titan_core.entity_registry(entity_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    genealogy_type_code text NOT NULL
        REFERENCES titan_ref.genealogy_type(genealogy_type_code)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    effective_date date NULL,
    scope_fraction numeric(9,8) NULL,
    source_id text NULL,
    recorded_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_genealogy_not_self CHECK (from_entity_id <> to_entity_id),
    CONSTRAINT ck_genealogy_scope_fraction CHECK (
        scope_fraction IS NULL OR (scope_fraction > 0 AND scope_fraction <= 1)
    ),
    CONSTRAINT uq_genealogy_relationship UNIQUE (
        from_entity_id, to_entity_id, genealogy_type_code, effective_date
    )
);

CREATE OR REPLACE FUNCTION titan_core.validate_entity_identity()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    expected_prefix text;
    country_type text;
BEGIN
    IF TG_OP = 'UPDATE' THEN
        IF NEW.entity_id IS DISTINCT FROM OLD.entity_id THEN
            RAISE EXCEPTION 'entity_id is permanent and cannot be changed (% -> %)', OLD.entity_id, NEW.entity_id;
        END IF;
        IF NEW.entity_type_code IS DISTINCT FROM OLD.entity_type_code THEN
            RAISE EXCEPTION 'entity_type_code is immutable for existing entity %', OLD.entity_id;
        END IF;
    END IF;

    SELECT id_prefix
      INTO expected_prefix
      FROM titan_ref.entity_type
     WHERE entity_type_code = NEW.entity_type_code;

    IF expected_prefix IS NULL THEN
        RAISE EXCEPTION 'Unknown entity type %', NEW.entity_type_code;
    END IF;

    IF NEW.entity_id !~ ('^' || expected_prefix || '-[A-Za-z0-9][A-Za-z0-9._-]*$') THEN
        RAISE EXCEPTION 'Entity ID % does not match prefix % for type %',
            NEW.entity_id, expected_prefix, NEW.entity_type_code;
    END IF;

    IF NEW.country_geo_id IS NOT NULL THEN
        SELECT geo_type_code
          INTO country_type
          FROM titan_core.geo_unit
         WHERE geo_id = NEW.country_geo_id;

        IF country_type IS DISTINCT FROM 'COUNTRY' THEN
            RAISE EXCEPTION 'country_geo_id % must reference a COUNTRY geography', NEW.country_geo_id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_entity_identity
BEFORE INSERT OR UPDATE ON titan_core.entity_registry
FOR EACH ROW EXECUTE FUNCTION titan_core.validate_entity_identity();

CREATE OR REPLACE FUNCTION titan_core.validate_geo_unit()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    registry_type text;
    expected_registry_type text;
    parent_type text;
BEGIN
    SELECT entity_type_code
      INTO registry_type
      FROM titan_core.entity_registry
     WHERE entity_id = NEW.geo_id;

    SELECT entity_type_code
      INTO expected_registry_type
      FROM titan_ref.geo_type
     WHERE geo_type_code = NEW.geo_type_code;

    IF registry_type IS DISTINCT FROM expected_registry_type THEN
        RAISE EXCEPTION 'Geo % registry type % does not match geo type % expected entity type %',
            NEW.geo_id, registry_type, NEW.geo_type_code, expected_registry_type;
    END IF;

    IF NEW.geo_type_code = 'COUNTRY' THEN
        IF NEW.parent_geo_id IS NULL THEN
            RAISE EXCEPTION 'COUNTRY geography % must have a REGION parent', NEW.geo_id;
        END IF;
        SELECT geo_type_code INTO parent_type
          FROM titan_core.geo_unit WHERE geo_id = NEW.parent_geo_id;
        IF parent_type IS DISTINCT FROM 'REGION' THEN
            RAISE EXCEPTION 'COUNTRY geography % parent must be REGION', NEW.geo_id;
        END IF;
    ELSIF NEW.geo_type_code = 'SUBNATIONAL' THEN
        IF NEW.parent_geo_id IS NULL THEN
            RAISE EXCEPTION 'SUBNATIONAL geography % must have a parent', NEW.geo_id;
        END IF;
        SELECT geo_type_code INTO parent_type
          FROM titan_core.geo_unit WHERE geo_id = NEW.parent_geo_id;
        IF parent_type NOT IN ('COUNTRY','SUBNATIONAL') THEN
            RAISE EXCEPTION 'SUBNATIONAL geography % parent must be COUNTRY or SUBNATIONAL', NEW.geo_id;
        END IF;
    ELSIF NEW.geo_type_code = 'REGION' AND NEW.parent_geo_id IS NOT NULL THEN
        SELECT geo_type_code INTO parent_type
          FROM titan_core.geo_unit WHERE geo_id = NEW.parent_geo_id;
        IF parent_type IS DISTINCT FROM 'REGION' THEN
            RAISE EXCEPTION 'REGION geography % parent, if present, must be REGION', NEW.geo_id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_geo_unit_validation
BEFORE INSERT OR UPDATE ON titan_core.geo_unit
FOR EACH ROW EXECUTE FUNCTION titan_core.validate_geo_unit();

CREATE OR REPLACE FUNCTION titan_core.validate_child_entity_type()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    entity_key text;
    actual_type text;
    expected_type text := TG_ARGV[1];
BEGIN
    entity_key := to_jsonb(NEW) ->> TG_ARGV[0];

    SELECT entity_type_code
      INTO actual_type
      FROM titan_core.entity_registry
     WHERE entity_id = entity_key;

    IF actual_type IS DISTINCT FROM expected_type THEN
        RAISE EXCEPTION 'Entity % has type %, expected % for table %',
            entity_key, actual_type, expected_type, TG_TABLE_NAME;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_physical_site_type
BEFORE INSERT OR UPDATE ON titan_core.physical_site
FOR EACH ROW EXECUTE FUNCTION titan_core.validate_child_entity_type('site_id','PHYSICAL_SITE');

CREATE TRIGGER trg_plant_master_type
BEFORE INSERT OR UPDATE ON titan_core.plant_master
FOR EACH ROW EXECUTE FUNCTION titan_core.validate_child_entity_type('plant_id','PHYSICAL_PLANT');

COMMIT;
