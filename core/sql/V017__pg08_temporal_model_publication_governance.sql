-- Global Cement Sustainability Intelligence
-- PostgreSQL Implementation v1.0 — PG-08 Temporal, Scenario, Model & Publication Governance
-- Requires V001-V016.
BEGIN;

CREATE TABLE titan_ref.period_mapping_method (
    period_mapping_method_code text PRIMARY KEY,
    definition text NOT NULL
);
CREATE TABLE titan_ref.price_basis_type (
    price_basis_type_code text PRIMARY KEY,
    definition text NOT NULL
);
CREATE TABLE titan_ref.scenario_status (
    scenario_status_code text PRIMARY KEY,
    definition text NOT NULL
);
CREATE TABLE titan_ref.assumption_value_type (
    assumption_value_type_code text PRIMARY KEY,
    definition text NOT NULL
);
CREATE TABLE titan_ref.model_run_status (
    model_run_status_code text PRIMARY KEY,
    definition text NOT NULL
);
CREATE TABLE titan_ref.snapshot_status (
    snapshot_status_code text PRIMARY KEY,
    definition text NOT NULL
);
CREATE TABLE titan_ref.publication_status (
    publication_status_code text PRIMARY KEY,
    definition text NOT NULL
);

INSERT INTO titan_ref.period_mapping_method VALUES
('REFERENCE_ONLY','Period relationship only; no allocation fabricated'),
('PRO_RATA','Pro-rata mapping under an explicit declared rule'),
('CUSTOM_EVIDENCED','Custom mapping backed by explicit evidence/method'),
('EXACT','Periods are exactly equivalent');

INSERT INTO titan_ref.price_basis_type VALUES
('NOMINAL','Nominal monetary basis'),
('REAL','Inflation-adjusted real monetary basis');

INSERT INTO titan_ref.scenario_status VALUES
('DRAFT','Scenario under development'),
('APPROVED','Approved for controlled analytical use'),
('SUPERSEDED','Superseded but historically reproducible'),
('WITHDRAWN','Withdrawn');

INSERT INTO titan_ref.assumption_value_type VALUES
('NUMERIC','Numeric assumption'),
('TEXT','Text/categorical assumption'),
('BOOLEAN','Boolean assumption');

INSERT INTO titan_ref.model_run_status VALUES
('DRAFT','Run assembly in progress; outputs may be attached'),
('COMPLETED','Completed immutable run'),
('FAILED','Failed run retained for audit'),
('SUPERSEDED','Completed run superseded by later run');

INSERT INTO titan_ref.snapshot_status VALUES
('DRAFT','Snapshot membership can still be edited'),
('SEALED','Snapshot frozen; membership immutable'),
('WITHDRAWN','Withdrawn snapshot retained');

INSERT INTO titan_ref.publication_status VALUES
('DRAFT','Publication assembly in progress; members/artifacts may be attached'),
('PUBLISHED','Published/current output'),
('SUPERSEDED','Superseded publication retained'),
('RETRACTED','Retracted but retained'),
('INTERNAL','Internal controlled publication snapshot');

INSERT INTO titan_core.unit_master(unit_code,symbol,dimension_code,base_unit_symbol,factor_to_base,definition)
VALUES
('USD','USD','CURRENCY',NULL,NULL,'United States dollar'),
('USD_PER_INR','USD/INR','FX_RATE',NULL,NULL,'USD per INR exchange rate; dated/method-specific'),
('USD_PER_CNY','USD/CNY','FX_RATE',NULL,NULL,'USD per CNY exchange rate; dated/method-specific');

CREATE TABLE titan_core.reporting_calendar (
    calendar_id text PRIMARY KEY,
    calendar_name text NOT NULL,
    owner_entity_id text NULL REFERENCES titan_core.entity_registry(entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    jurisdiction_geo_id text NULL REFERENCES titan_core.geo_unit(geo_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    calendar_type text NOT NULL,
    fiscal_year_start_month integer NOT NULL CHECK (fiscal_year_start_month BETWEEN 1 AND 12),
    fiscal_year_start_day integer NOT NULL CHECK (fiscal_year_start_day BETWEEN 1 AND 31),
    timezone_name text NOT NULL DEFAULT 'UTC',
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    calendar_notes text NULL,
    CONSTRAINT ck_calendar_id CHECK (calendar_id ~ '^CAL-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_calendar_subject CHECK (owner_entity_id IS NOT NULL OR jurisdiction_geo_id IS NOT NULL)
);

CREATE TABLE titan_core.reporting_period (
    period_id text PRIMARY KEY,
    calendar_id text NOT NULL REFERENCES titan_core.reporting_calendar(calendar_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    period_label text NOT NULL,
    period_kind text NOT NULL,
    period_start date NOT NULL,
    period_end date NOT NULL,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_period_id CHECK (period_id ~ '^PERIOD-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_period_dates CHECK (period_end>=period_start),
    CONSTRAINT uq_period_calendar_label UNIQUE(calendar_id,period_label)
);

CREATE TABLE titan_core.period_mapping (
    period_mapping_id text PRIMARY KEY,
    source_period_id text NOT NULL REFERENCES titan_core.reporting_period(period_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    target_period_id text NOT NULL REFERENCES titan_core.reporting_period(period_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    period_mapping_method_code text NOT NULL REFERENCES titan_ref.period_mapping_method(period_mapping_method_code),
    allocation_fraction numeric NULL CHECK (allocation_fraction IS NULL OR allocation_fraction BETWEEN 0 AND 1),
    allocation_basis text NULL,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    mapping_notes text NULL,
    CONSTRAINT ck_period_mapping_id CHECK (period_mapping_id ~ '^PMAP-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_period_mapping_not_self CHECK (source_period_id<>target_period_id),
    CONSTRAINT ck_period_mapping_fraction CHECK (
        (period_mapping_method_code IN ('PRO_RATA','CUSTOM_EVIDENCED') AND allocation_fraction IS NOT NULL AND allocation_basis IS NOT NULL)
        OR
        (period_mapping_method_code IN ('REFERENCE_ONLY','EXACT') AND allocation_fraction IS NULL)
    )
);

CREATE TABLE titan_core.price_basis (
    price_basis_id text PRIMARY KEY,
    price_basis_type_code text NOT NULL REFERENCES titan_ref.price_basis_type(price_basis_type_code),
    base_year integer NULL CHECK (base_year IS NULL OR base_year BETWEEN 1900 AND 2200),
    inflation_index_name text NULL,
    inflation_method text NULL,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    basis_notes text NULL,
    CONSTRAINT ck_price_basis_id CHECK (price_basis_id ~ '^PBASIS-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_real_basis CHECK (
        price_basis_type_code<>'REAL'
        OR (base_year IS NOT NULL AND inflation_index_name IS NOT NULL AND inflation_method IS NOT NULL)
    )
);

CREATE TABLE titan_core.currency_context (
    currency_context_id text PRIMARY KEY,
    from_currency_unit_code text NOT NULL REFERENCES titan_core.unit_master(unit_code),
    to_currency_unit_code text NOT NULL REFERENCES titan_core.unit_master(unit_code),
    fx_rate numeric NOT NULL CHECK (fx_rate>0),
    fx_method text NOT NULL,
    rate_date date NULL,
    rate_period_start date NULL,
    rate_period_end date NULL,
    price_basis_id text NULL REFERENCES titan_core.price_basis(price_basis_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    context_notes text NULL,
    CONSTRAINT ck_currency_context_id CHECK (currency_context_id ~ '^FXCTX-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_currency_pair CHECK (from_currency_unit_code<>to_currency_unit_code),
    CONSTRAINT ck_currency_rate_basis CHECK (
        (rate_date IS NOT NULL AND rate_period_start IS NULL AND rate_period_end IS NULL)
        OR
        (rate_date IS NULL AND rate_period_start IS NOT NULL AND rate_period_end IS NOT NULL AND rate_period_end>=rate_period_start)
    )
);

CREATE TABLE titan_core.financial_normalization (
    financial_normalization_id text PRIMARY KEY,
    input_observation_id text NOT NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    output_observation_id text NOT NULL UNIQUE REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    currency_context_id text NOT NULL REFERENCES titan_core.currency_context(currency_context_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    price_basis_id text NULL REFERENCES titan_core.price_basis(price_basis_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    calculation_method text NOT NULL,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    normalization_notes text NULL,
    CONSTRAINT ck_fin_norm_id CHECK (financial_normalization_id ~ '^FNORM-[A-Za-z0-9][A-Za-z0-9._-]*$')
);

CREATE TABLE titan_core.assumption_set (
    assumption_set_id text PRIMARY KEY,
    assumption_set_name text NOT NULL,
    version_label text NOT NULL,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    set_notes text NULL,
    CONSTRAINT ck_assumption_set_id CHECK (assumption_set_id ~ '^ASM-[A-Za-z0-9][A-Za-z0-9._-]*$')
);

CREATE TABLE titan_core.assumption_item (
    assumption_item_id text PRIMARY KEY,
    assumption_set_id text NOT NULL REFERENCES titan_core.assumption_set(assumption_set_id) ON UPDATE RESTRICT ON DELETE CASCADE,
    assumption_key text NOT NULL,
    assumption_value_type_code text NOT NULL REFERENCES titan_ref.assumption_value_type(assumption_value_type_code),
    numeric_value numeric NULL,
    text_value text NULL,
    boolean_value boolean NULL,
    unit_code text NULL REFERENCES titan_core.unit_master(unit_code),
    uncertainty_text text NULL,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_assumption_item_id CHECK (assumption_item_id ~ '^ASMI-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT uq_assumption_key UNIQUE(assumption_set_id,assumption_key),
    CONSTRAINT ck_assumption_payload CHECK (
        (assumption_value_type_code='NUMERIC' AND numeric_value IS NOT NULL AND text_value IS NULL AND boolean_value IS NULL)
        OR
        (assumption_value_type_code='TEXT' AND numeric_value IS NULL AND text_value IS NOT NULL AND boolean_value IS NULL)
        OR
        (assumption_value_type_code='BOOLEAN' AND numeric_value IS NULL AND text_value IS NULL AND boolean_value IS NOT NULL)
    )
);


CREATE TABLE titan_core.assumption_override_set (
    override_set_id text PRIMARY KEY,
    base_assumption_set_id text NOT NULL REFERENCES titan_core.assumption_set(assumption_set_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    version_label text NOT NULL,
    created_by text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    override_notes text NULL,
    CONSTRAINT ck_override_set_id CHECK (override_set_id ~ '^OVRSET-[A-Za-z0-9][A-Za-z0-9._-]*$')
);

CREATE TABLE titan_core.assumption_override_item (
    override_item_id text PRIMARY KEY,
    override_set_id text NOT NULL REFERENCES titan_core.assumption_override_set(override_set_id) ON UPDATE RESTRICT ON DELETE CASCADE,
    assumption_item_id text NOT NULL REFERENCES titan_core.assumption_item(assumption_item_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    original_value_text text NOT NULL,
    override_value_text text NOT NULL,
    override_reason text NOT NULL,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_override_item_id CHECK (override_item_id ~ '^OVRITEM-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT uq_override_assumption UNIQUE(override_set_id,assumption_item_id)
);

CREATE OR REPLACE FUNCTION titan_core.reject_override_set_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION 'assumption override sets are immutable; create a new override set';
END;
$$;

CREATE TRIGGER trg_override_set_immutable
BEFORE UPDATE OR DELETE ON titan_core.assumption_override_set
FOR EACH ROW EXECUTE FUNCTION titan_core.reject_override_set_mutation();

CREATE TRIGGER trg_override_item_immutable
BEFORE UPDATE OR DELETE ON titan_core.assumption_override_item
FOR EACH ROW EXECUTE FUNCTION titan_core.reject_override_set_mutation();

CREATE TABLE titan_core.scenario_master (
    scenario_id text PRIMARY KEY,
    scenario_name text NOT NULL,
    scenario_family text NOT NULL,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_scenario_id CHECK (scenario_id ~ '^SCN-[A-Za-z0-9][A-Za-z0-9._-]*$')
);

CREATE TABLE titan_core.scenario_version (
    scenario_version_id text PRIMARY KEY,
    scenario_id text NOT NULL REFERENCES titan_core.scenario_master(scenario_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    version_label text NOT NULL,
    scenario_status_code text NOT NULL REFERENCES titan_ref.scenario_status(scenario_status_code),
    default_assumption_set_id text NOT NULL REFERENCES titan_core.assumption_set(assumption_set_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    valid_from date NOT NULL,
    valid_to date NULL,
    supersedes_scenario_version_id text NULL REFERENCES titan_core.scenario_version(scenario_version_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    scenario_notes text NULL,
    CONSTRAINT ck_scenario_version_id CHECK (scenario_version_id ~ '^SCNV-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_scenario_dates CHECK (valid_to IS NULL OR valid_to>=valid_from),
    CONSTRAINT ck_scenario_not_self CHECK (supersedes_scenario_version_id IS NULL OR supersedes_scenario_version_id<>scenario_version_id)
);

CREATE TABLE titan_core.project_scenario_membership (
    project_scenario_membership_id text PRIMARY KEY,
    scenario_version_id text NOT NULL REFERENCES titan_core.scenario_version(scenario_version_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    project_entity_id text NOT NULL REFERENCES titan_core.entity_registry(entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    membership_role text NOT NULL,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_project_scenario_id CHECK (project_scenario_membership_id ~ '^SCNMEM-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT uq_project_scenario UNIQUE(scenario_version_id,project_entity_id,membership_role)
);

CREATE TABLE titan_core.dataset_snapshot (
    dataset_snapshot_id text PRIMARY KEY,
    snapshot_label text NOT NULL,
    cutoff_date date NOT NULL,
    schema_release_ref text NOT NULL,
    snapshot_status_code text NOT NULL REFERENCES titan_ref.snapshot_status(snapshot_status_code),
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by text NOT NULL,
    content_hash text NULL,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    snapshot_notes text NULL,
    CONSTRAINT ck_dataset_snapshot_id CHECK (dataset_snapshot_id ~ '^DSNAP-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_dataset_snapshot_hash CHECK (content_hash IS NULL OR content_hash ~ '^[0-9a-fA-F]{64}$')
);

CREATE TABLE titan_core.dataset_snapshot_member (
    dataset_snapshot_member_id text PRIMARY KEY,
    dataset_snapshot_id text NOT NULL REFERENCES titan_core.dataset_snapshot(dataset_snapshot_id) ON UPDATE RESTRICT ON DELETE CASCADE,
    object_type text NOT NULL,
    object_id text NOT NULL,
    record_version_ref text NULL,
    record_hash text NOT NULL,
    CONSTRAINT ck_dataset_snapshot_member_id CHECK (dataset_snapshot_member_id ~ '^DSMEM-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_dataset_member_hash CHECK (record_hash ~ '^[0-9a-fA-F]{64}$'),
    CONSTRAINT uq_dataset_member UNIQUE(dataset_snapshot_id,object_type,object_id,record_version_ref)
);

CREATE OR REPLACE FUNCTION titan_core.validate_dataset_snapshot_member_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE sid text;
DECLARE st text;
BEGIN
    sid:=CASE WHEN TG_OP='DELETE' THEN OLD.dataset_snapshot_id ELSE NEW.dataset_snapshot_id END;
    SELECT snapshot_status_code INTO st FROM titan_core.dataset_snapshot WHERE dataset_snapshot_id=sid;
    IF st<>'DRAFT' THEN
        RAISE EXCEPTION 'Dataset snapshot % is %, membership is immutable',sid,st;
    END IF;
    RETURN CASE WHEN TG_OP='DELETE' THEN OLD ELSE NEW END;
END;
$$;

CREATE TRIGGER trg_dataset_member_mutation
BEFORE INSERT OR UPDATE OR DELETE ON titan_core.dataset_snapshot_member
FOR EACH ROW EXECUTE FUNCTION titan_core.validate_dataset_snapshot_member_mutation();

CREATE OR REPLACE FUNCTION titan_core.validate_dataset_snapshot_transition()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP='DELETE' THEN
        RAISE EXCEPTION 'dataset_snapshot is retained; use WITHDRAWN status rather than delete';
    END IF;
    IF OLD.snapshot_status_code='DRAFT' AND NEW.snapshot_status_code IN ('DRAFT','SEALED','WITHDRAWN') THEN
        RETURN NEW;
    END IF;
    IF OLD.snapshot_status_code='SEALED' AND NEW.snapshot_status_code IN ('SEALED','WITHDRAWN') THEN
        IF NEW.cutoff_date IS DISTINCT FROM OLD.cutoff_date
           OR NEW.schema_release_ref IS DISTINCT FROM OLD.schema_release_ref
           OR NEW.content_hash IS DISTINCT FROM OLD.content_hash
           OR NEW.snapshot_label IS DISTINCT FROM OLD.snapshot_label THEN
            RAISE EXCEPTION 'Sealed dataset snapshot core fields are immutable';
        END IF;
        RETURN NEW;
    END IF;
    IF OLD.snapshot_status_code='WITHDRAWN' AND NEW IS DISTINCT FROM OLD THEN
        RAISE EXCEPTION 'Withdrawn snapshot is immutable';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_dataset_snapshot_transition
BEFORE UPDATE OR DELETE ON titan_core.dataset_snapshot
FOR EACH ROW EXECUTE FUNCTION titan_core.validate_dataset_snapshot_transition();

CREATE TABLE titan_core.model_definition (
    model_id text PRIMARY KEY,
    model_name text NOT NULL,
    model_purpose text NOT NULL,
    owner_team text NULL,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_model_id CHECK (model_id ~ '^MOD-[A-Za-z0-9][A-Za-z0-9._-]*$')
);

CREATE TABLE titan_core.model_version (
    model_version_id text PRIMARY KEY,
    model_id text NOT NULL REFERENCES titan_core.model_definition(model_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    version_label text NOT NULL,
    method_specification text NOT NULL,
    code_hash text NOT NULL,
    runtime_environment_ref text NOT NULL,
    valid_from date NOT NULL,
    supersedes_model_version_id text NULL REFERENCES titan_core.model_version(model_version_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_model_version_id CHECK (model_version_id ~ '^MODV-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_model_code_hash CHECK (code_hash ~ '^[0-9a-fA-F]{64}$'),
    CONSTRAINT ck_model_not_self CHECK (supersedes_model_version_id IS NULL OR supersedes_model_version_id<>model_version_id)
);

CREATE TABLE titan_core.model_run (
    model_run_id text PRIMARY KEY,
    model_version_id text NOT NULL REFERENCES titan_core.model_version(model_version_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    dataset_snapshot_id text NOT NULL REFERENCES titan_core.dataset_snapshot(dataset_snapshot_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    scenario_version_id text NULL REFERENCES titan_core.scenario_version(scenario_version_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    assumption_set_id text NOT NULL REFERENCES titan_core.assumption_set(assumption_set_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    override_set_id text NULL REFERENCES titan_core.assumption_override_set(override_set_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    cutoff_date date NOT NULL,
    model_run_status_code text NOT NULL REFERENCES titan_ref.model_run_status(model_run_status_code),
    run_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    run_by text NOT NULL,
    input_fingerprint text NOT NULL,
    output_fingerprint text NULL,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    run_notes text NULL,
    CONSTRAINT ck_model_run_id CHECK (model_run_id ~ '^RUN-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_run_input_hash CHECK (input_fingerprint ~ '^[0-9a-fA-F]{64}$'),
    CONSTRAINT ck_run_output_hash CHECK (output_fingerprint IS NULL OR output_fingerprint ~ '^[0-9a-fA-F]{64}$'),
    CONSTRAINT ck_completed_run_output_hash CHECK (model_run_status_code<>'COMPLETED' OR output_fingerprint IS NOT NULL)
);

CREATE OR REPLACE FUNCTION titan_core.validate_model_run_snapshot()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE s_cut date;
DECLARE s_status text;
DECLARE ovr_base text;
BEGIN
    SELECT cutoff_date,snapshot_status_code INTO s_cut,s_status
    FROM titan_core.dataset_snapshot WHERE dataset_snapshot_id=NEW.dataset_snapshot_id;
    IF s_status<>'SEALED' THEN
        RAISE EXCEPTION 'Model run requires SEALED dataset snapshot';
    END IF;
    IF NEW.cutoff_date IS DISTINCT FROM s_cut THEN
        RAISE EXCEPTION 'Model run cutoff % must equal dataset snapshot cutoff %',NEW.cutoff_date,s_cut;
    END IF;
    IF NEW.override_set_id IS NOT NULL THEN
        SELECT base_assumption_set_id INTO ovr_base
        FROM titan_core.assumption_override_set WHERE override_set_id=NEW.override_set_id;
        IF ovr_base IS DISTINCT FROM NEW.assumption_set_id THEN
            RAISE EXCEPTION 'Override set % is based on %, not run assumption set %',NEW.override_set_id,ovr_base,NEW.assumption_set_id;
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_model_run_snapshot
BEFORE INSERT OR UPDATE ON titan_core.model_run
FOR EACH ROW EXECUTE FUNCTION titan_core.validate_model_run_snapshot();

CREATE OR REPLACE FUNCTION titan_core.validate_model_run_transition()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP='DELETE' THEN
        RAISE EXCEPTION 'model_run is retained; use SUPERSEDED rather than delete';
    END IF;
    IF OLD.model_run_status_code='DRAFT' THEN
        IF NEW.model_run_status_code='COMPLETED' AND NEW.output_fingerprint IS NULL THEN
            RAISE EXCEPTION 'Completed model run requires output fingerprint';
        END IF;
        RETURN NEW;
    END IF;
    IF OLD.model_run_status_code IN ('COMPLETED','FAILED','SUPERSEDED') THEN
        IF NEW.model_version_id IS DISTINCT FROM OLD.model_version_id
           OR NEW.dataset_snapshot_id IS DISTINCT FROM OLD.dataset_snapshot_id
           OR NEW.scenario_version_id IS DISTINCT FROM OLD.scenario_version_id
           OR NEW.assumption_set_id IS DISTINCT FROM OLD.assumption_set_id
           OR NEW.override_set_id IS DISTINCT FROM OLD.override_set_id
           OR NEW.cutoff_date IS DISTINCT FROM OLD.cutoff_date
           OR NEW.run_at IS DISTINCT FROM OLD.run_at
           OR NEW.run_by IS DISTINCT FROM OLD.run_by
           OR NEW.input_fingerprint IS DISTINCT FROM OLD.input_fingerprint
           OR NEW.output_fingerprint IS DISTINCT FROM OLD.output_fingerprint THEN
            RAISE EXCEPTION 'Finalized model run core fields are immutable';
        END IF;
        IF OLD.model_run_status_code='COMPLETED' AND NEW.model_run_status_code IN ('COMPLETED','SUPERSEDED') THEN
            RETURN NEW;
        END IF;
        IF NEW IS DISTINCT FROM OLD THEN
            RAISE EXCEPTION 'Finalized model run is immutable';
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_model_run_transition
BEFORE UPDATE OR DELETE ON titan_core.model_run
FOR EACH ROW EXECUTE FUNCTION titan_core.validate_model_run_transition();

CREATE TABLE titan_core.model_output (
    model_output_id text PRIMARY KEY,
    model_run_id text NOT NULL REFERENCES titan_core.model_run(model_run_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    output_key text NOT NULL,
    observation_id text NOT NULL UNIQUE REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_model_output_id CHECK (model_output_id ~ '^OUT-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT uq_model_output_key UNIQUE(model_run_id,output_key)
);


CREATE OR REPLACE FUNCTION titan_core.validate_model_output_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE rid text;
DECLARE st text;
BEGIN
    rid:=CASE WHEN TG_OP='DELETE' THEN OLD.model_run_id ELSE NEW.model_run_id END;
    SELECT model_run_status_code INTO st FROM titan_core.model_run WHERE model_run_id=rid;
    IF st<>'DRAFT' THEN
        RAISE EXCEPTION 'Model run % is %, outputs are immutable',rid,st;
    END IF;
    RETURN CASE WHEN TG_OP='DELETE' THEN OLD ELSE NEW END;
END;
$$;

CREATE TRIGGER trg_model_output_mutation
BEFORE INSERT OR UPDATE OR DELETE ON titan_core.model_output
FOR EACH ROW EXECUTE FUNCTION titan_core.validate_model_output_mutation();

CREATE OR REPLACE FUNCTION titan_core.validate_model_output_observation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE dc text;
DECLARE prov_count integer;
BEGIN
    SELECT data_class_code INTO dc FROM titan_core.observation WHERE observation_id=NEW.observation_id;
    SELECT count(*) INTO prov_count FROM titan_core.observation_model_provenance WHERE observation_id=NEW.observation_id;
    IF dc<>'M' OR prov_count<1 THEN
        RAISE EXCEPTION 'Model output observation % must be class M with model provenance',NEW.observation_id;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_model_output_observation
BEFORE INSERT OR UPDATE ON titan_core.model_output
FOR EACH ROW EXECUTE FUNCTION titan_core.validate_model_output_observation();

CREATE TABLE titan_core.abatement_action (
    abatement_action_id text PRIMARY KEY,
    action_name text NOT NULL,
    project_entity_id text NULL REFERENCES titan_core.entity_registry(entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    physical_boundary_entity_id text NULL REFERENCES titan_core.entity_registry(entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    max_claimable_observation_id text NOT NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    valid_from date NULL,
    valid_to date NULL,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    action_notes text NULL,
    CONSTRAINT ck_abatement_action_id CHECK (abatement_action_id ~ '^ABT-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_abatement_dates CHECK (valid_to IS NULL OR valid_from IS NULL OR valid_to>=valid_from)
);

CREATE TABLE titan_core.abatement_allocation (
    abatement_allocation_id text PRIMARY KEY,
    model_run_id text NOT NULL REFERENCES titan_core.model_run(model_run_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    abatement_action_id text NOT NULL REFERENCES titan_core.abatement_action(abatement_action_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    wedge_code text NOT NULL,
    allocated_observation_id text NOT NULL UNIQUE REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    mutual_exclusion_group text NOT NULL,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    allocation_notes text NULL,
    CONSTRAINT ck_abatement_alloc_id CHECK (abatement_allocation_id ~ '^ABTA-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT uq_abatement_wedge UNIQUE(model_run_id,abatement_action_id,wedge_code)
);


CREATE OR REPLACE FUNCTION titan_core.validate_abatement_allocation_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE rid text;
DECLARE st text;
BEGIN
    rid:=CASE WHEN TG_OP='DELETE' THEN OLD.model_run_id ELSE NEW.model_run_id END;
    SELECT model_run_status_code INTO st FROM titan_core.model_run WHERE model_run_id=rid;
    IF st<>'DRAFT' THEN
        RAISE EXCEPTION 'Model run % is %, abatement allocations are immutable',rid,st;
    END IF;
    RETURN CASE WHEN TG_OP='DELETE' THEN OLD ELSE NEW END;
END;
$$;

CREATE TRIGGER trg_abatement_allocation_mutation
BEFORE INSERT OR UPDATE OR DELETE ON titan_core.abatement_allocation
FOR EACH ROW EXECUTE FUNCTION titan_core.validate_abatement_allocation_mutation();

CREATE OR REPLACE FUNCTION titan_core.validate_abatement_allocation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE rid text;
DECLARE aid text;
DECLARE max_q numeric;
DECLARE alloc_q numeric;
BEGIN
    rid:=CASE WHEN TG_OP='DELETE' THEN OLD.model_run_id ELSE NEW.model_run_id END;
    aid:=CASE WHEN TG_OP='DELETE' THEN OLD.abatement_action_id ELSE NEW.abatement_action_id END;

    SELECT o.numeric_value INTO max_q
    FROM titan_core.abatement_action a
    JOIN titan_core.observation o ON o.observation_id=a.max_claimable_observation_id
    WHERE a.abatement_action_id=aid;

    SELECT COALESCE(sum(o.numeric_value),0) INTO alloc_q
    FROM titan_core.abatement_allocation aa
    JOIN titan_core.observation o ON o.observation_id=aa.allocated_observation_id
    WHERE aa.model_run_id=rid AND aa.abatement_action_id=aid;

    IF max_q IS NULL OR alloc_q>max_q+0.000001 THEN
        RAISE EXCEPTION 'Abatement allocation % exceeds physical maximum % for action %',alloc_q,max_q,aid;
    END IF;
    RETURN NULL;
END;
$$;

CREATE CONSTRAINT TRIGGER ct_abatement_allocation
AFTER INSERT OR UPDATE OR DELETE ON titan_core.abatement_allocation
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION titan_core.validate_abatement_allocation();

CREATE TABLE titan_core.project_probability_history (
    project_probability_id text PRIMARY KEY,
    project_entity_id text NOT NULL REFERENCES titan_core.entity_registry(entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    scenario_version_id text NULL REFERENCES titan_core.scenario_version(scenario_version_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    as_of_date date NOT NULL,
    probability numeric(8,7) NOT NULL CHECK (probability BETWEEN 0 AND 1),
    basis_text text NOT NULL,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_project_probability_id CHECK (project_probability_id ~ '^PPROB-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT uq_project_probability UNIQUE(project_entity_id,scenario_version_id,as_of_date)
);

CREATE TABLE titan_core.publication_snapshot (
    publication_snapshot_id text PRIMARY KEY,
    publication_title text NOT NULL,
    publication_version text NOT NULL,
    publication_status_code text NOT NULL REFERENCES titan_ref.publication_status(publication_status_code),
    dataset_snapshot_id text NOT NULL REFERENCES titan_core.dataset_snapshot(dataset_snapshot_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    cutoff_date date NOT NULL,
    template_version text NOT NULL,
    code_commit_ref text NOT NULL,
    environment_ref text NOT NULL,
    publication_input_fingerprint text NOT NULL,
    output_hash text NOT NULL,
    published_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    supersedes_publication_snapshot_id text NULL REFERENCES titan_core.publication_snapshot(publication_snapshot_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    publication_notes text NULL,
    CONSTRAINT ck_publication_snapshot_id CHECK (publication_snapshot_id ~ '^PUBSNAP-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_pub_input_hash CHECK (publication_input_fingerprint ~ '^[0-9a-fA-F]{64}$'),
    CONSTRAINT ck_pub_output_hash CHECK (output_hash ~ '^[0-9a-fA-F]{64}$'),
    CONSTRAINT ck_pub_not_self CHECK (supersedes_publication_snapshot_id IS NULL OR supersedes_publication_snapshot_id<>publication_snapshot_id)
);

CREATE TABLE titan_core.publication_model_run (
    publication_snapshot_id text NOT NULL REFERENCES titan_core.publication_snapshot(publication_snapshot_id) ON UPDATE RESTRICT ON DELETE CASCADE,
    model_run_id text NOT NULL REFERENCES titan_core.model_run(model_run_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    role_code text NOT NULL,
    PRIMARY KEY(publication_snapshot_id,model_run_id,role_code)
);

CREATE TABLE titan_core.publication_artifact (
    publication_artifact_id text PRIMARY KEY,
    publication_snapshot_id text NOT NULL REFERENCES titan_core.publication_snapshot(publication_snapshot_id) ON UPDATE RESTRICT ON DELETE CASCADE,
    artifact_name text NOT NULL,
    artifact_type text NOT NULL,
    artifact_hash text NOT NULL,
    storage_ref text NOT NULL,
    CONSTRAINT ck_publication_artifact_id CHECK (publication_artifact_id ~ '^PUBART-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_artifact_hash CHECK (artifact_hash ~ '^[0-9a-fA-F]{64}$')
);

CREATE OR REPLACE FUNCTION titan_core.validate_publication_snapshot()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE s_cut date;
DECLARE s_status text;
BEGIN
    SELECT cutoff_date,snapshot_status_code INTO s_cut,s_status
    FROM titan_core.dataset_snapshot WHERE dataset_snapshot_id=NEW.dataset_snapshot_id;
    IF s_status<>'SEALED' THEN
        RAISE EXCEPTION 'Publication requires SEALED dataset snapshot';
    END IF;
    IF NEW.cutoff_date IS DISTINCT FROM s_cut THEN
        RAISE EXCEPTION 'Publication cutoff must equal dataset snapshot cutoff';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_publication_snapshot_validate
BEFORE INSERT OR UPDATE ON titan_core.publication_snapshot
FOR EACH ROW EXECUTE FUNCTION titan_core.validate_publication_snapshot();

CREATE OR REPLACE FUNCTION titan_core.validate_publication_transition()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP='DELETE' THEN
        RAISE EXCEPTION 'publication snapshot is retained; use SUPERSEDED/RETRACTED status';
    END IF;
    IF OLD.publication_status_code='DRAFT' THEN
        RETURN NEW;
    END IF;
    IF NEW.dataset_snapshot_id IS DISTINCT FROM OLD.dataset_snapshot_id
       OR NEW.cutoff_date IS DISTINCT FROM OLD.cutoff_date
       OR NEW.template_version IS DISTINCT FROM OLD.template_version
       OR NEW.code_commit_ref IS DISTINCT FROM OLD.code_commit_ref
       OR NEW.environment_ref IS DISTINCT FROM OLD.environment_ref
       OR NEW.publication_input_fingerprint IS DISTINCT FROM OLD.publication_input_fingerprint
       OR NEW.output_hash IS DISTINCT FROM OLD.output_hash
       OR NEW.publication_title IS DISTINCT FROM OLD.publication_title
       OR NEW.publication_version IS DISTINCT FROM OLD.publication_version THEN
        RAISE EXCEPTION 'Finalized publication core fields are immutable';
    END IF;
    IF OLD.publication_status_code IN ('PUBLISHED','INTERNAL')
       AND NEW.publication_status_code IN (OLD.publication_status_code,'SUPERSEDED','RETRACTED') THEN
        RETURN NEW;
    END IF;
    IF NEW IS DISTINCT FROM OLD THEN
        RAISE EXCEPTION 'Finalized publication is immutable';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_publication_transition
BEFORE UPDATE OR DELETE ON titan_core.publication_snapshot
FOR EACH ROW EXECUTE FUNCTION titan_core.validate_publication_transition();

CREATE OR REPLACE FUNCTION titan_core.validate_publication_member_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE pid text;
DECLARE st text;
BEGIN
    pid:=CASE WHEN TG_OP='DELETE' THEN OLD.publication_snapshot_id ELSE NEW.publication_snapshot_id END;
    SELECT publication_status_code INTO st FROM titan_core.publication_snapshot WHERE publication_snapshot_id=pid;
    IF st<>'DRAFT' THEN
        RAISE EXCEPTION 'Publication % is %, membership/artifacts are immutable',pid,st;
    END IF;
    RETURN CASE WHEN TG_OP='DELETE' THEN OLD ELSE NEW END;
END;
$$;

CREATE TRIGGER trg_publication_model_run_mutation
BEFORE INSERT OR UPDATE OR DELETE ON titan_core.publication_model_run
FOR EACH ROW EXECUTE FUNCTION titan_core.validate_publication_member_mutation();

CREATE TRIGGER trg_publication_artifact_mutation
BEFORE INSERT OR UPDATE OR DELETE ON titan_core.publication_artifact
FOR EACH ROW EXECUTE FUNCTION titan_core.validate_publication_member_mutation();

CREATE OR REPLACE FUNCTION titan_core.normalized_currency_value(input_amount numeric,fx_rate numeric)
RETURNS numeric LANGUAGE sql IMMUTABLE STRICT
AS $$ SELECT input_amount*fx_rate $$;

COMMIT;
