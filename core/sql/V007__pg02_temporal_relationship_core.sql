-- Global Cement Sustainability Intelligence
-- PostgreSQL Implementation v1.0 — PG-02 Temporal & Relationship Core
-- Requires PG-01 V001-V006.
-- Architecture v1.0 semantic contract remains frozen.
BEGIN;

CREATE EXTENSION IF NOT EXISTS btree_gist;

INSERT INTO titan_ref.entity_type(entity_type_code,id_prefix,domain_name,definition)
VALUES ('BOUNDARY','BND','Boundary','Versioned accounting/reporting/regulatory/product/project boundary')
ON CONFLICT (entity_type_code) DO NOTHING;

CREATE TABLE titan_ref.ownership_interest_type (
    ownership_interest_type_code text PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_ref.control_role (
    control_role_code text PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_ref.site_relationship_type (
    site_relationship_type_code text PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_ref.shared_service_type (
    shared_service_type_code text PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_ref.allocation_method (
    allocation_method_code text PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_ref.boundary_type (
    boundary_type_code text PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_ref.boundary_member_role (
    boundary_member_role_code text PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_ref.operational_status (
    operational_status_code text PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_ref.asset_event_type (
    asset_event_type_code text PRIMARY KEY,
    definition text NOT NULL
);

INSERT INTO titan_ref.ownership_interest_type VALUES
('DIRECT_EQUITY','Direct legal/economic equity interest'),
('INDIRECT_EQUITY','Indirect equity interest through intermediate entities'),
('JV_EQUITY','Joint-venture equity interest'),
('BENEFICIAL_INTEREST','Beneficial/economic interest distinct from registered shareholding'),
('OTHER','Other evidenced ownership/economic interest');

INSERT INTO titan_ref.control_role VALUES
('PRIMARY_OPERATOR','Primary operating/controller role for the entity'),
('MANAGER','Management role without replacing primary operator'),
('LESSEE','Lease-based operational control'),
('TECHNICAL_OPERATOR','Technical operating responsibility'),
('OTHER','Other evidenced control relationship');

INSERT INTO titan_ref.site_relationship_type VALUES
('PRIMARY_LOCATION','Asset is physically located at this site as its primary location'),
('SHARED_LOCATION','Asset spans or is shared across more than one site'),
('SUPPORTS_SITE','Infrastructure supports the site but is not physically contained by it');

INSERT INTO titan_ref.shared_service_type VALUES
('POWER','Power/electricity service'),
('WHR','Waste-heat recovery service'),
('WATER','Water abstraction/treatment/recycling service'),
('QUARRY','Quarry/raw-material service'),
('LOGISTICS','Rail/port/road/terminal/logistics service'),
('FUEL','Fuel preparation/handling service'),
('OTHER','Other shared infrastructure/service');

INSERT INTO titan_ref.allocation_method VALUES
('FIXED_SHARE','Evidence-backed fixed allocation share'),
('METERED','Allocation from metered physical consumption/output'),
('CONTRACTUAL','Allocation from contractually defined entitlement'),
('OUTPUT_BASED','Allocation proportional to production/output'),
('ENERGY_BASED','Allocation proportional to energy use'),
('REVENUE_BASED','Allocation proportional to revenue'),
('NONE_UNALLOCATED','No defensible allocation available; retain shared/unallocated state');

INSERT INTO titan_ref.boundary_type VALUES
('PHYSICAL_SITE','Physical/geospatial site boundary'),
('ORGANIZATIONAL','Organizational/reporting perimeter'),
('REGULATORY','Regulatory/compliance perimeter'),
('PRODUCT','Product/EPD/LCA boundary'),
('PROJECT','Project boundary'),
('VALUE_CHAIN','Value-chain/accounting boundary'),
('CONTRACTUAL','Contractual entitlement/perimeter'),
('CUSTOM','Explicitly defined custom analytical boundary');

INSERT INTO titan_ref.boundary_member_role VALUES
('INCLUDED','Entity fully/primarily included'),
('PARTIAL','Entity partially included'),
('EXCLUDED_REFERENCE','Entity explicitly excluded but retained for audit/reference'),
('PRECURSOR','Entity/material source included as precursor'),
('BENEFICIARY','Entity receives service/attribute inside boundary'),
('OTHER','Other explicitly documented membership role');

INSERT INTO titan_ref.operational_status VALUES
('CONSTRUCTION','Under construction'),
('COMMISSIONING','Commissioning/ramp-up'),
('OPERATING','Operating'),
('PARTIAL_OPERATION','Only part of the physical operating scope is active'),
('MOTHBALLED','Mothballed but potentially restartable'),
('SHUTDOWN_TEMPORARY','Temporary shutdown'),
('CLOSED','Closed'),
('RETIRED','Permanently retired/decommissioned'),
('UNKNOWN','Operational status not publicly verified');

INSERT INTO titan_ref.asset_event_type VALUES
('COMMISSIONED','Commissioning/initial start-up'),
('CAPACITY_EXPANSION','Physical capacity expansion'),
('RETROFIT','Retrofit/modification'),
('PARTIAL_COMMISSIONING','Only part of project/asset commissioned'),
('MOTHBALLED','Asset entered mothball'),
('RESTARTED','Asset restarted'),
('TEMPORARY_SHUTDOWN','Temporary shutdown event'),
('CLOSED','Closure event'),
('RETIRED','Permanent retirement event'),
('REPLACED','Physical replacement event'),
('OTHER','Other dated physical/operational event');

CREATE TABLE titan_core.ownership_interest (
    ownership_interest_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    owner_entity_id text NOT NULL REFERENCES titan_core.entity_registry(entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    owned_entity_id text NOT NULL REFERENCES titan_core.entity_registry(entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    ownership_interest_type_code text NOT NULL REFERENCES titan_ref.ownership_interest_type(ownership_interest_type_code),
    interest_class text NOT NULL DEFAULT 'ALL',
    economic_share numeric(12,10) NULL,
    voting_share numeric(12,10) NULL,
    valid_from date NOT NULL,
    valid_to date NULL,
    valid_period daterange GENERATED ALWAYS AS (daterange(valid_from, valid_to, '[]')) STORED,
    source_id text NULL,
    recorded_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    superseded_at timestamptz NULL,
    row_version bigint NOT NULL DEFAULT 1 CHECK (row_version >= 1),
    CONSTRAINT ck_ownership_not_self CHECK (owner_entity_id <> owned_entity_id),
    CONSTRAINT ck_ownership_interest_class CHECK (btrim(interest_class) <> ''),
    CONSTRAINT ck_ownership_economic_share CHECK (economic_share IS NULL OR economic_share BETWEEN 0 AND 1),
    CONSTRAINT ck_ownership_voting_share CHECK (voting_share IS NULL OR voting_share BETWEEN 0 AND 1),
    CONSTRAINT ck_ownership_dates CHECK (valid_to IS NULL OR valid_to >= valid_from),
    CONSTRAINT ex_ownership_same_interest_no_overlap EXCLUDE USING gist (
        owner_entity_id WITH =,
        owned_entity_id WITH =,
        ownership_interest_type_code WITH =,
        interest_class WITH =,
        valid_period WITH &&
    )
);

CREATE INDEX ix_ownership_owned_entity ON titan_core.ownership_interest(owned_entity_id);
CREATE INDEX ix_ownership_owner_entity ON titan_core.ownership_interest(owner_entity_id);

CREATE TABLE titan_core.operating_control (
    operating_control_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    controller_entity_id text NOT NULL REFERENCES titan_core.entity_registry(entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    controlled_entity_id text NOT NULL REFERENCES titan_core.entity_registry(entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    control_role_code text NOT NULL REFERENCES titan_ref.control_role(control_role_code),
    valid_from date NOT NULL,
    valid_to date NULL,
    valid_period daterange GENERATED ALWAYS AS (daterange(valid_from, valid_to, '[]')) STORED,
    source_id text NULL,
    recorded_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    superseded_at timestamptz NULL,
    row_version bigint NOT NULL DEFAULT 1 CHECK (row_version >= 1),
    CONSTRAINT ck_control_not_self CHECK (controller_entity_id <> controlled_entity_id),
    CONSTRAINT ck_control_dates CHECK (valid_to IS NULL OR valid_to >= valid_from),
    CONSTRAINT ex_same_control_relation_no_overlap EXCLUDE USING gist (
        controller_entity_id WITH =,
        controlled_entity_id WITH =,
        control_role_code WITH =,
        valid_period WITH &&
    )
);

ALTER TABLE titan_core.operating_control
ADD CONSTRAINT ex_one_primary_operator_per_period
EXCLUDE USING gist (
    controlled_entity_id WITH =,
    valid_period WITH &&
)
WHERE (control_role_code='PRIMARY_OPERATOR');

CREATE TABLE titan_core.site_asset_relationship (
    site_asset_relationship_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    site_id text NOT NULL REFERENCES titan_core.physical_site(site_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    asset_entity_id text NOT NULL REFERENCES titan_core.entity_registry(entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    site_relationship_type_code text NOT NULL REFERENCES titan_ref.site_relationship_type(site_relationship_type_code),
    valid_from date NOT NULL,
    valid_to date NULL,
    valid_period daterange GENERATED ALWAYS AS (daterange(valid_from, valid_to, '[]')) STORED,
    source_id text NULL,
    recorded_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    superseded_at timestamptz NULL,
    CONSTRAINT ck_site_asset_dates CHECK (valid_to IS NULL OR valid_to >= valid_from),
    CONSTRAINT ex_same_site_asset_relation_no_overlap EXCLUDE USING gist (
        site_id WITH =,
        asset_entity_id WITH =,
        site_relationship_type_code WITH =,
        valid_period WITH &&
    )
);

ALTER TABLE titan_core.site_asset_relationship
ADD CONSTRAINT ex_one_primary_site_per_asset_period
EXCLUDE USING gist (
    asset_entity_id WITH =,
    valid_period WITH &&
)
WHERE (site_relationship_type_code='PRIMARY_LOCATION');

CREATE TABLE titan_core.allocation_rule (
    allocation_rule_id text PRIMARY KEY,
    shared_asset_id text NOT NULL REFERENCES titan_core.entity_registry(entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    allocation_method_code text NOT NULL REFERENCES titan_ref.allocation_method(allocation_method_code),
    allocation_metric_code text NOT NULL,
    denominator_basis text NULL,
    valid_from date NOT NULL,
    valid_to date NULL,
    valid_period daterange GENERATED ALWAYS AS (daterange(valid_from, valid_to, '[]')) STORED,
    source_id text NULL,
    recorded_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    superseded_at timestamptz NULL,
    row_version bigint NOT NULL DEFAULT 1 CHECK (row_version >= 1),
    CONSTRAINT ck_allocation_rule_id CHECK (allocation_rule_id ~ '^ALLOC-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_allocation_metric_nonblank CHECK (btrim(allocation_metric_code) <> ''),
    CONSTRAINT ck_allocation_dates CHECK (valid_to IS NULL OR valid_to >= valid_from),
    CONSTRAINT ex_shared_asset_metric_rule_no_overlap EXCLUDE USING gist (
        shared_asset_id WITH =,
        allocation_metric_code WITH =,
        valid_period WITH &&
    )
);

CREATE TABLE titan_core.allocation_share (
    allocation_share_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    allocation_rule_id text NOT NULL REFERENCES titan_core.allocation_rule(allocation_rule_id) ON UPDATE RESTRICT ON DELETE CASCADE,
    beneficiary_entity_id text NOT NULL REFERENCES titan_core.entity_registry(entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    allocation_share numeric(12,10) NULL,
    source_id text NULL,
    recorded_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_allocation_rule_beneficiary UNIQUE (allocation_rule_id, beneficiary_entity_id),
    CONSTRAINT ck_allocation_share CHECK (allocation_share IS NULL OR allocation_share BETWEEN 0 AND 1)
);

CREATE OR REPLACE FUNCTION titan_core.validate_allocation_total()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    rule_id text;
    total_share numeric;
BEGIN
    rule_id := COALESCE(NEW.allocation_rule_id, OLD.allocation_rule_id);
    SELECT COALESCE(sum(allocation_share),0)
      INTO total_share
      FROM titan_core.allocation_share
     WHERE allocation_rule_id=rule_id
       AND allocation_share IS NOT NULL;

    IF total_share > 1.0000000001 THEN
        RAISE EXCEPTION 'Allocation shares for rule % exceed 1.0: %', rule_id, total_share;
    END IF;
    RETURN NULL;
END;
$$;

CREATE CONSTRAINT TRIGGER ct_allocation_share_total
AFTER INSERT OR UPDATE OR DELETE ON titan_core.allocation_share
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION titan_core.validate_allocation_total();

CREATE TABLE titan_core.shared_asset_relationship (
    shared_asset_relationship_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    shared_asset_id text NOT NULL REFERENCES titan_core.entity_registry(entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    beneficiary_entity_id text NOT NULL REFERENCES titan_core.entity_registry(entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    shared_service_type_code text NOT NULL REFERENCES titan_ref.shared_service_type(shared_service_type_code),
    allocation_rule_id text NULL REFERENCES titan_core.allocation_rule(allocation_rule_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    valid_from date NOT NULL,
    valid_to date NULL,
    valid_period daterange GENERATED ALWAYS AS (daterange(valid_from, valid_to, '[]')) STORED,
    source_id text NULL,
    recorded_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    superseded_at timestamptz NULL,
    CONSTRAINT ck_shared_asset_not_self CHECK (shared_asset_id <> beneficiary_entity_id),
    CONSTRAINT ck_shared_asset_dates CHECK (valid_to IS NULL OR valid_to >= valid_from),
    CONSTRAINT ex_shared_asset_beneficiary_service_no_overlap EXCLUDE USING gist (
        shared_asset_id WITH =,
        beneficiary_entity_id WITH =,
        shared_service_type_code WITH =,
        valid_period WITH &&
    )
);

CREATE OR REPLACE FUNCTION titan_core.validate_shared_asset_allocation_rule()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    rule_asset text;
BEGIN
    IF NEW.allocation_rule_id IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT shared_asset_id
      INTO rule_asset
      FROM titan_core.allocation_rule
     WHERE allocation_rule_id=NEW.allocation_rule_id;

    IF rule_asset IS DISTINCT FROM NEW.shared_asset_id THEN
        RAISE EXCEPTION 'Allocation rule % belongs to shared asset %, not %',
            NEW.allocation_rule_id, rule_asset, NEW.shared_asset_id;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_shared_asset_allocation_rule
BEFORE INSERT OR UPDATE ON titan_core.shared_asset_relationship
FOR EACH ROW EXECUTE FUNCTION titan_core.validate_shared_asset_allocation_rule();

CREATE TABLE titan_core.boundary_master (
    boundary_id text PRIMARY KEY REFERENCES titan_core.entity_registry(entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    boundary_type_code text NOT NULL REFERENCES titan_ref.boundary_type(boundary_type_code),
    canonical_name text NOT NULL,
    owner_entity_id text NULL REFERENCES titan_core.entity_registry(entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    recorded_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_boundary_name_nonblank CHECK (btrim(canonical_name) <> '')
);

CREATE TRIGGER trg_boundary_master_type
BEFORE INSERT OR UPDATE ON titan_core.boundary_master
FOR EACH ROW EXECUTE FUNCTION titan_core.validate_child_entity_type('boundary_id','BOUNDARY');

CREATE TABLE titan_core.boundary_version (
    boundary_version_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    boundary_id text NOT NULL REFERENCES titan_core.boundary_master(boundary_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    version_no integer NOT NULL CHECK (version_no >= 1),
    valid_from date NOT NULL,
    valid_to date NULL,
    valid_period daterange GENERATED ALWAYS AS (daterange(valid_from, valid_to, '[]')) STORED,
    methodology_ref text NULL,
    source_id text NULL,
    recorded_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    superseded_at timestamptz NULL,
    supersedes_boundary_version_id bigint NULL REFERENCES titan_core.boundary_version(boundary_version_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT uq_boundary_version UNIQUE(boundary_id, version_no),
    CONSTRAINT ck_boundary_version_dates CHECK (valid_to IS NULL OR valid_to >= valid_from),
    CONSTRAINT ex_boundary_version_no_overlap EXCLUDE USING gist (
        boundary_id WITH =,
        valid_period WITH &&
    )
);

CREATE TABLE titan_core.boundary_member (
    boundary_member_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    boundary_version_id bigint NOT NULL REFERENCES titan_core.boundary_version(boundary_version_id) ON UPDATE RESTRICT ON DELETE CASCADE,
    member_entity_id text NOT NULL REFERENCES titan_core.entity_registry(entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    boundary_member_role_code text NOT NULL REFERENCES titan_ref.boundary_member_role(boundary_member_role_code),
    inclusion_share numeric(12,10) NULL,
    allocation_rule_id text NULL REFERENCES titan_core.allocation_rule(allocation_rule_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    source_id text NULL,
    recorded_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_boundary_version_member_role UNIQUE(boundary_version_id, member_entity_id, boundary_member_role_code),
    CONSTRAINT ck_boundary_inclusion_share CHECK (inclusion_share IS NULL OR inclusion_share BETWEEN 0 AND 1)
);

CREATE TABLE titan_core.asset_event (
    asset_event_id text PRIMARY KEY,
    subject_entity_id text NOT NULL REFERENCES titan_core.entity_registry(entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    asset_event_type_code text NOT NULL REFERENCES titan_ref.asset_event_type(asset_event_type_code),
    event_date date NOT NULL,
    event_end_date date NULL,
    source_id text NULL,
    event_notes text NULL,
    recorded_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_asset_event_id CHECK (asset_event_id ~ '^EVT-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_asset_event_dates CHECK (event_end_date IS NULL OR event_end_date >= event_date)
);

CREATE TABLE titan_core.operational_status_history (
    operational_status_history_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    entity_id text NOT NULL REFERENCES titan_core.entity_registry(entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    operational_status_code text NOT NULL REFERENCES titan_ref.operational_status(operational_status_code),
    valid_from date NOT NULL,
    valid_to date NULL,
    valid_period daterange GENERATED ALWAYS AS (daterange(valid_from, valid_to, '[]')) STORED,
    source_id text NULL,
    recorded_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    superseded_at timestamptz NULL,
    CONSTRAINT ck_operational_status_dates CHECK (valid_to IS NULL OR valid_to >= valid_from),
    CONSTRAINT ex_one_operational_status_per_period EXCLUDE USING gist (
        entity_id WITH =,
        valid_period WITH &&
    )
);

COMMIT;
