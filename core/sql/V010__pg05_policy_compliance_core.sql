-- Global Cement Sustainability Intelligence
-- PostgreSQL Implementation v1.0 — PG-05 Policy & Compliance Layer
-- Requires PG-01 through PG-04.
BEGIN;

CREATE TABLE titan_ref.scheme_type (
    scheme_type_code text PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_ref.policy_status (
    policy_status_code text PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_ref.policy_relationship_type (
    policy_relationship_type_code text PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_ref.compliance_unit_type (
    compliance_unit_type_code text PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_ref.regulatory_mapping_role (
    regulatory_mapping_role_code text PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_ref.obligation_method (
    obligation_method_code text PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_ref.obligation_rule_role (
    obligation_rule_role_code text PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_ref.verification_status (
    verification_status_code text PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_ref.instrument_type (
    instrument_type_code text PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_ref.carbon_transaction_type (
    carbon_transaction_type_code text PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_ref.settlement_status (
    settlement_status_code text PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_ref.enforcement_event_type (
    enforcement_event_type_code text PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_ref.enforcement_status (
    enforcement_status_code text PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_ref.applicability_state (
    applicability_state_code text PRIMARY KEY,
    definition text NOT NULL
);

INSERT INTO titan_ref.scheme_type VALUES
('ETS','Emissions trading scheme'),
('INTENSITY_CREDIT','Intensity-target credit/certificate scheme'),
('CARBON_TAX','Carbon tax'),
('BORDER_ADJUSTMENT','Border carbon adjustment'),
('STANDARD','Regulatory standard'),
('OTHER','Other regulatory mechanism');

INSERT INTO titan_ref.policy_status VALUES
('DRAFT','Draft text'),
('CONSULTATION','Public consultation/proposal'),
('APPROVED_IN_PRINCIPLE','Approved in principle but not formally promulgated'),
('PROMULGATED','Formally issued/promulgated'),
('EFFECTIVE','In legal/administrative effect'),
('SUPERSEDED','Superseded by later version'),
('WITHDRAWN','Withdrawn');

INSERT INTO titan_ref.policy_relationship_type VALUES
('AMENDS','Amends without necessarily replacing all provisions'),
('SUPERSEDES','Supersedes prior policy version'),
('CORRECTS','Corrects prior version'),
('IMPLEMENTS','Implements parent legal instrument'),
('INTERPRETS','Official interpretation/guidance'),
('EXTENDS','Extends/adds coverage while preserving existing provisions');

INSERT INTO titan_ref.compliance_unit_type VALUES
('ENTITY','Whole regulated entity'),
('PLANT','Plant/site level'),
('KILN_LINE','Individual clinker/kiln production line'),
('PROCESS','Process level'),
('PRODUCT','Product level'),
('AGGREGATE','Explicit aggregate of several assets');

INSERT INTO titan_ref.regulatory_mapping_role VALUES
('PRIMARY_SITE','Primary physical plant/site for regulated entity/unit'),
('INCLUDED_ASSET','Included physical asset'),
('CLINKER_LINE','Clinker line covered by compliance unit'),
('LEGAL_OWNER','Legal owner link'),
('OPERATOR','Operator/controller link'),
('EXCLUDED_ASSET','Explicitly excluded physical asset');

INSERT INTO titan_ref.obligation_method VALUES
('TARGET_INTENSITY','Binding target intensity'),
('BENCHMARK_ALLOCATION','Allowance allocation by benchmark/performance formula'),
('VERIFIED_EMISSIONS_ALLOCATION','Allocation equals verified emissions'),
('TAX_RATE','Tax/rate obligation'),
('NO_TARGET_THIS_PERIOD','No numeric target due for the period'),
('OTHER','Other scheme-specific obligation');

INSERT INTO titan_ref.obligation_rule_role VALUES
('TARGET','Rule defines target/target calculation'),
('ISSUE','Rule governs issuance/over-achievement'),
('SHORTFALL','Rule governs shortfall/certificate requirement'),
('BANK','Rule governs banking/carry-forward'),
('ALLOCATION','Rule governs allowance allocation'),
('ELIGIBILITY','Rule governs eligibility/inclusion/exclusion'),
('SETTLEMENT','Rule governs surrender/settlement'),
('ENFORCEMENT','Rule governs enforcement/compensation');

INSERT INTO titan_ref.verification_status VALUES
('PENDING','Verification pending'),
('VERIFIED','Verified'),
('REVISED','Verified record later revised'),
('REJECTED','Verification rejected'),
('WITHDRAWN','Verification withdrawn');

INSERT INTO titan_ref.instrument_type VALUES
('CREDIT','Credit/certificate'),
('ALLOWANCE','Emissions allowance'),
('OFFSET','Offset instrument'),
('TAX_PAYMENT','Tax/payment evidence'),
('OTHER','Other regulatory instrument');

INSERT INTO titan_ref.carbon_transaction_type VALUES
('ISSUE','Create/issue instrument units into an account'),
('ALLOCATE','Allocate allowance units into an account'),
('PURCHASE','Transfer units from seller account to buyer account'),
('SALE','Transfer units from seller account to buyer account'),
('TRANSFER','Transfer units between accounts'),
('BANK','State transition retaining units in same account'),
('SURRENDER','Retire units against a compliance obligation'),
('CANCEL','Cancel/invalidate units'),
('ADJUST_IN','Administrative increase'),
('ADJUST_OUT','Administrative decrease');

INSERT INTO titan_ref.settlement_status VALUES
('NOT_DUE','No settlement due'),
('PENDING_VERIFICATION','Performance not yet finally verified'),
('OPEN','Obligation open'),
('COMPLIANT','Compliance satisfied'),
('SHORTFALL','Unresolved instrument shortfall'),
('PENALTY','Enforcement/penalty active'),
('CLOSED','Final closed settlement');

INSERT INTO titan_ref.enforcement_event_type VALUES
('NOTICE','Notice/non-compliance notice'),
('COMPENSATION','Environmental compensation'),
('PENALTY','Penalty'),
('APPEAL','Appeal'),
('WAIVER','Waiver/relief'),
('CORRECTION','Correction/reversal');

INSERT INTO titan_ref.enforcement_status VALUES
('OPEN','Open/current'),
('PAID','Paid/satisfied'),
('APPEALED','Under appeal'),
('WAIVED','Waived'),
('REVERSED','Reversed/corrected'),
('CLOSED','Closed');

INSERT INTO titan_ref.applicability_state VALUES
('APPLICABLE','Scheme/policy applies'),
('NOT_APPLICABLE','Does not apply for period/boundary'),
('EXEMPT','Explicit exemption'),
('THRESHOLD_NOT_MET','Scheme threshold not met'),
('PENDING_ASSESSMENT','Applicability pending assessment'),
('UNKNOWN','Applicability not publicly verified');

CREATE TABLE titan_core.carbon_scheme (
    scheme_id text PRIMARY KEY,
    scheme_name text NOT NULL,
    scheme_type_code text NOT NULL REFERENCES titan_ref.scheme_type(scheme_type_code),
    jurisdiction_geo_id text NOT NULL REFERENCES titan_core.geo_unit(geo_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    governing_authority_name text NOT NULL,
    instrument_unit_label text NULL,
    scheme_notes text NULL,
    CONSTRAINT ck_scheme_id CHECK (scheme_id ~ '^SCHEME-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_scheme_name CHECK (btrim(scheme_name) <> ''),
    CONSTRAINT ck_scheme_authority CHECK (btrim(governing_authority_name) <> '')
);

CREATE TABLE titan_core.policy_version (
    policy_version_id text PRIMARY KEY,
    scheme_id text NOT NULL REFERENCES titan_core.carbon_scheme(scheme_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    legal_title text NOT NULL,
    legal_citation text NULL,
    publication_date date NULL,
    effective_from date NULL,
    effective_to date NULL,
    primary_source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    recorded_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    policy_notes text NULL,
    CONSTRAINT ck_policy_version_id CHECK (policy_version_id ~ '^POLV-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_policy_title CHECK (btrim(legal_title) <> ''),
    CONSTRAINT ck_policy_dates CHECK (effective_to IS NULL OR effective_from IS NULL OR effective_to >= effective_from)
);

CREATE TABLE titan_core.policy_status_history (
    policy_status_history_id text PRIMARY KEY,
    policy_version_id text NOT NULL REFERENCES titan_core.policy_version(policy_version_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    policy_status_code text NOT NULL REFERENCES titan_ref.policy_status(policy_status_code),
    valid_from date NOT NULL,
    valid_to date NULL,
    valid_period daterange GENERATED ALWAYS AS (daterange(valid_from, valid_to, '[]')) STORED,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    status_notes text NULL,
    recorded_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_policy_status_id CHECK (policy_status_history_id ~ '^POLSTAT-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_policy_status_dates CHECK (valid_to IS NULL OR valid_to >= valid_from),
    CONSTRAINT ex_policy_status_no_overlap EXCLUDE USING gist (
        policy_version_id WITH =,
        valid_period WITH &&
    )
);

CREATE VIEW titan_core.policy_version_current_status AS
SELECT DISTINCT ON (policy_version_id)
    policy_version_id,
    policy_status_code,
    valid_from,
    valid_to,
    source_id
FROM titan_core.policy_status_history
ORDER BY policy_version_id, valid_from DESC, policy_status_history_id DESC;

CREATE TABLE titan_core.policy_version_relationship (
    policy_version_relationship_id text PRIMARY KEY,
    from_policy_version_id text NOT NULL REFERENCES titan_core.policy_version(policy_version_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    to_policy_version_id text NOT NULL REFERENCES titan_core.policy_version(policy_version_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    policy_relationship_type_code text NOT NULL REFERENCES titan_ref.policy_relationship_type(policy_relationship_type_code),
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    relationship_notes text NULL,
    CONSTRAINT ck_policy_rel_id CHECK (policy_version_relationship_id ~ '^POLREL-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_policy_rel_not_self CHECK (from_policy_version_id <> to_policy_version_id),
    CONSTRAINT uq_policy_relationship UNIQUE(from_policy_version_id,to_policy_version_id,policy_relationship_type_code)
);

CREATE TABLE titan_core.policy_formula_rule (
    policy_rule_id text PRIMARY KEY,
    policy_version_id text NOT NULL REFERENCES titan_core.policy_version(policy_version_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    rule_code text NOT NULL,
    rule_title text NOT NULL,
    rule_expression text NOT NULL,
    parameter_schema jsonb NOT NULL DEFAULT '{}'::jsonb,
    source_location_ref text NOT NULL,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_policy_rule_id CHECK (policy_rule_id ~ '^POLRULE-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_policy_rule_code CHECK (btrim(rule_code) <> ''),
    CONSTRAINT ck_policy_rule_title CHECK (btrim(rule_title) <> ''),
    CONSTRAINT ck_policy_rule_expression CHECK (btrim(rule_expression) <> ''),
    CONSTRAINT ck_policy_rule_location CHECK (btrim(source_location_ref) <> ''),
    CONSTRAINT uq_policy_rule_code UNIQUE(policy_version_id,rule_code)
);

CREATE TABLE titan_core.regulated_entity (
    regulated_entity_id text PRIMARY KEY,
    scheme_id text NOT NULL REFERENCES titan_core.carbon_scheme(scheme_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    external_registration_id text NULL,
    valid_from date NULL,
    valid_to date NULL,
    recorded_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_regulated_entity_id CHECK (regulated_entity_id ~ '^REG-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_regulated_entity_dates CHECK (valid_to IS NULL OR valid_from IS NULL OR valid_to >= valid_from),
    CONSTRAINT uq_scheme_external_registration UNIQUE(scheme_id,external_registration_id)
);

CREATE TABLE titan_core.regulated_entity_name_history (
    regulated_entity_name_history_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    regulated_entity_id text NOT NULL REFERENCES titan_core.regulated_entity(regulated_entity_id) ON UPDATE RESTRICT ON DELETE CASCADE,
    official_name text NOT NULL,
    valid_from date NOT NULL,
    valid_to date NULL,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    recorded_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_reg_name CHECK (btrim(official_name) <> ''),
    CONSTRAINT ck_reg_name_dates CHECK (valid_to IS NULL OR valid_to >= valid_from)
);

CREATE TABLE titan_core.compliance_unit (
    compliance_unit_id text PRIMARY KEY,
    regulated_entity_id text NOT NULL REFERENCES titan_core.regulated_entity(regulated_entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    compliance_unit_type_code text NOT NULL REFERENCES titan_ref.compliance_unit_type(compliance_unit_type_code),
    subject_entity_id text NULL REFERENCES titan_core.entity_registry(entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    boundary_version_id bigint NULL REFERENCES titan_core.boundary_version(boundary_version_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    valid_from date NULL,
    valid_to date NULL,
    unit_notes text NULL,
    CONSTRAINT ck_compliance_unit_id CHECK (compliance_unit_id ~ '^CU-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_compliance_unit_subject CHECK (subject_entity_id IS NOT NULL OR boundary_version_id IS NOT NULL),
    CONSTRAINT ck_compliance_unit_dates CHECK (valid_to IS NULL OR valid_from IS NULL OR valid_to >= valid_from)
);

CREATE TABLE titan_core.regulatory_asset_mapping (
    regulatory_asset_mapping_id text PRIMARY KEY,
    regulated_entity_id text NOT NULL REFERENCES titan_core.regulated_entity(regulated_entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    compliance_unit_id text NULL REFERENCES titan_core.compliance_unit(compliance_unit_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    titan_entity_id text NOT NULL REFERENCES titan_core.entity_registry(entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    regulatory_mapping_role_code text NOT NULL REFERENCES titan_ref.regulatory_mapping_role(regulatory_mapping_role_code),
    valid_from date NOT NULL,
    valid_to date NULL,
    valid_period daterange GENERATED ALWAYS AS (daterange(valid_from,valid_to,'[]')) STORED,
    mapping_confidence numeric(5,4) NULL CHECK (mapping_confidence IS NULL OR mapping_confidence BETWEEN 0 AND 1),
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    mapping_notes text NULL,
    CONSTRAINT ck_reg_asset_mapping_id CHECK (regulatory_asset_mapping_id ~ '^RAM-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_reg_asset_dates CHECK (valid_to IS NULL OR valid_to >= valid_from),
    CONSTRAINT ex_reg_asset_mapping_no_overlap EXCLUDE USING gist (
        regulated_entity_id WITH =,
        titan_entity_id WITH =,
        regulatory_mapping_role_code WITH =,
        valid_period WITH &&
    )
);

CREATE OR REPLACE FUNCTION titan_core.validate_regulatory_mapping_unit()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE unit_reg text;
BEGIN
    IF NEW.compliance_unit_id IS NULL THEN RETURN NEW; END IF;
    SELECT regulated_entity_id INTO unit_reg
    FROM titan_core.compliance_unit
    WHERE compliance_unit_id=NEW.compliance_unit_id;
    IF unit_reg IS DISTINCT FROM NEW.regulated_entity_id THEN
        RAISE EXCEPTION 'Compliance unit % belongs to regulated entity %, not %',
            NEW.compliance_unit_id, unit_reg, NEW.regulated_entity_id;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_regulatory_mapping_unit
BEFORE INSERT OR UPDATE ON titan_core.regulatory_asset_mapping
FOR EACH ROW EXECUTE FUNCTION titan_core.validate_regulatory_mapping_unit();

CREATE TABLE titan_core.policy_applicability (
    policy_applicability_id text PRIMARY KEY,
    policy_version_id text NOT NULL REFERENCES titan_core.policy_version(policy_version_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    regulated_entity_id text NULL REFERENCES titan_core.regulated_entity(regulated_entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    compliance_unit_id text NULL REFERENCES titan_core.compliance_unit(compliance_unit_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    applicability_state_code text NOT NULL REFERENCES titan_ref.applicability_state(applicability_state_code),
    trigger_basis text NOT NULL,
    threshold_value numeric NULL,
    threshold_unit_code text NULL REFERENCES titan_core.unit_master(unit_code),
    valid_from date NOT NULL,
    valid_to date NULL,
    value_state_code text NOT NULL REFERENCES titan_ref.value_state(value_state_code),
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    applicability_notes text NULL,
    CONSTRAINT ck_policy_applicability_id CHECK (policy_applicability_id ~ '^APP-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_policy_applicability_subject CHECK (regulated_entity_id IS NOT NULL OR compliance_unit_id IS NOT NULL),
    CONSTRAINT ck_policy_applicability_trigger CHECK (btrim(trigger_basis) <> ''),
    CONSTRAINT ck_policy_applicability_dates CHECK (valid_to IS NULL OR valid_to >= valid_from)
);

CREATE TABLE titan_core.compliance_baseline (
    compliance_baseline_id text PRIMARY KEY,
    policy_version_id text NOT NULL REFERENCES titan_core.policy_version(policy_version_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    regulated_entity_id text NOT NULL REFERENCES titan_core.regulated_entity(regulated_entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    baseline_period_label text NOT NULL,
    baseline_output numeric NULL CHECK (baseline_output IS NULL OR baseline_output >= 0),
    output_unit_code text NULL REFERENCES titan_core.unit_master(unit_code),
    baseline_intensity numeric NULL,
    intensity_unit_code text NULL REFERENCES titan_core.unit_master(unit_code),
    denominator_id text NULL REFERENCES titan_core.denominator_definition(denominator_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    baseline_notes text NULL,
    CONSTRAINT ck_compliance_baseline_id CHECK (compliance_baseline_id ~ '^BASE-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_baseline_period CHECK (btrim(baseline_period_label) <> '')
);

CREATE TABLE titan_core.compliance_obligation (
    obligation_id text PRIMARY KEY,
    policy_version_id text NOT NULL REFERENCES titan_core.policy_version(policy_version_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    compliance_unit_id text NOT NULL REFERENCES titan_core.compliance_unit(compliance_unit_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    compliance_period_label text NOT NULL,
    period_start date NOT NULL,
    period_end date NOT NULL,
    obligation_method_code text NOT NULL REFERENCES titan_ref.obligation_method(obligation_method_code),
    metric_code text NOT NULL,
    target_value_state_code text NOT NULL REFERENCES titan_ref.value_state(value_state_code),
    target_value numeric NULL,
    target_unit_code text NULL REFERENCES titan_core.unit_master(unit_code),
    denominator_id text NULL REFERENCES titan_core.denominator_definition(denominator_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    policy_rule_id text NULL REFERENCES titan_core.policy_formula_rule(policy_rule_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    obligation_notes text NULL,
    recorded_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_obligation_id CHECK (obligation_id ~ '^OBL-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_obligation_period_label CHECK (btrim(compliance_period_label) <> ''),
    CONSTRAINT ck_obligation_period CHECK (period_end >= period_start),
    CONSTRAINT ck_obligation_metric CHECK (btrim(metric_code) <> ''),
    CONSTRAINT ck_obligation_target_payload CHECK (
        (target_value_state_code IN ('VALUE','PROVISIONAL','ZERO') AND target_value IS NOT NULL)
        OR
        (target_value_state_code NOT IN ('VALUE','PROVISIONAL','ZERO') AND target_value IS NULL)
    ),
    CONSTRAINT ck_obligation_target_denominator CHECK (
        obligation_method_code <> 'TARGET_INTENSITY'
        OR target_value_state_code NOT IN ('VALUE','PROVISIONAL','ZERO')
        OR denominator_id IS NOT NULL
    ),
    CONSTRAINT uq_obligation_unit_period UNIQUE(compliance_unit_id,period_start,period_end,metric_code)
);


CREATE TABLE titan_core.compliance_obligation_rule_link (
    obligation_id text NOT NULL REFERENCES titan_core.compliance_obligation(obligation_id) ON UPDATE RESTRICT ON DELETE CASCADE,
    policy_rule_id text NOT NULL REFERENCES titan_core.policy_formula_rule(policy_rule_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    obligation_rule_role_code text NOT NULL REFERENCES titan_ref.obligation_rule_role(obligation_rule_role_code),
    PRIMARY KEY(obligation_id,policy_rule_id,obligation_rule_role_code)
);

CREATE TABLE titan_core.verification_record (
    verification_id text PRIMARY KEY,
    compliance_unit_id text NOT NULL REFERENCES titan_core.compliance_unit(compliance_unit_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    period_start date NOT NULL,
    period_end date NOT NULL,
    emissions_observation_id text NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    output_observation_id text NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    intensity_observation_id text NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    verifier_entity_id text NULL REFERENCES titan_core.entity_registry(entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    verifier_name_text text NULL,
    verification_status_code text NOT NULL REFERENCES titan_ref.verification_status(verification_status_code),
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    recorded_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    supersedes_verification_id text NULL REFERENCES titan_core.verification_record(verification_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    verification_notes text NULL,
    CONSTRAINT ck_verification_id CHECK (verification_id ~ '^VER-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_verification_period CHECK (period_end >= period_start),
    CONSTRAINT ck_verification_not_self CHECK (supersedes_verification_id IS NULL OR supersedes_verification_id <> verification_id),
    CONSTRAINT ck_verifier_identity CHECK (verifier_entity_id IS NOT NULL OR verifier_name_text IS NOT NULL)
);

CREATE OR REPLACE FUNCTION titan_core.validate_verification_observation_context()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    unit_subject text;
    obs_id text;
    obs_subject text;
    obs_start date;
    obs_end date;
BEGIN
    SELECT subject_entity_id INTO unit_subject
    FROM titan_core.compliance_unit
    WHERE compliance_unit_id=NEW.compliance_unit_id;

    FOREACH obs_id IN ARRAY ARRAY[NEW.emissions_observation_id,NEW.output_observation_id,NEW.intensity_observation_id]
    LOOP
        IF obs_id IS NULL THEN CONTINUE; END IF;
        SELECT subject_entity_id,period_start,period_end
          INTO obs_subject,obs_start,obs_end
          FROM titan_core.observation
         WHERE observation_id=obs_id;
        IF unit_subject IS NOT NULL AND obs_subject IS DISTINCT FROM unit_subject THEN
            RAISE EXCEPTION 'Verification observation % subject % does not match compliance-unit subject %',
                obs_id,obs_subject,unit_subject;
        END IF;
        IF obs_start IS DISTINCT FROM NEW.period_start OR obs_end IS DISTINCT FROM NEW.period_end THEN
            RAISE EXCEPTION 'Verification observation % period does not match verification period',obs_id;
        END IF;
    END LOOP;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_verification_context
BEFORE INSERT OR UPDATE ON titan_core.verification_record
FOR EACH ROW EXECUTE FUNCTION titan_core.validate_verification_observation_context();

CREATE TABLE titan_core.carbon_instrument (
    instrument_id text PRIMARY KEY,
    scheme_id text NOT NULL REFERENCES titan_core.carbon_scheme(scheme_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    instrument_name text NOT NULL,
    instrument_type_code text NOT NULL REFERENCES titan_ref.instrument_type(instrument_type_code),
    unit_label text NOT NULL,
    vintage_rule text NULL,
    banking_rule text NULL,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_instrument_id CHECK (instrument_id ~ '^INST-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_instrument_name CHECK (btrim(instrument_name) <> ''),
    CONSTRAINT ck_instrument_unit CHECK (btrim(unit_label) <> '')
);

CREATE TABLE titan_core.instrument_lot (
    instrument_lot_id text PRIMARY KEY,
    instrument_id text NOT NULL REFERENCES titan_core.carbon_instrument(instrument_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    vintage_label text NOT NULL,
    policy_version_id text NULL REFERENCES titan_core.policy_version(policy_version_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    valid_from date NULL,
    valid_to date NULL,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    lot_notes text NULL,
    CONSTRAINT ck_instrument_lot_id CHECK (instrument_lot_id ~ '^LOT-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_instrument_vintage CHECK (btrim(vintage_label) <> ''),
    CONSTRAINT ck_instrument_lot_dates CHECK (valid_to IS NULL OR valid_from IS NULL OR valid_to >= valid_from)
);

CREATE TABLE titan_core.compliance_account (
    account_id text PRIMARY KEY,
    scheme_id text NOT NULL REFERENCES titan_core.carbon_scheme(scheme_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    regulated_entity_id text NULL REFERENCES titan_core.regulated_entity(regulated_entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    holder_entity_id text NULL REFERENCES titan_core.entity_registry(entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    external_account_id text NULL,
    valid_from date NULL,
    valid_to date NULL,
    account_notes text NULL,
    CONSTRAINT ck_account_id CHECK (account_id ~ '^ACC-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_account_holder CHECK (regulated_entity_id IS NOT NULL OR holder_entity_id IS NOT NULL),
    CONSTRAINT ck_account_dates CHECK (valid_to IS NULL OR valid_from IS NULL OR valid_to >= valid_from)
);

CREATE TABLE titan_core.carbon_transaction (
    carbon_transaction_id text PRIMARY KEY,
    carbon_transaction_type_code text NOT NULL REFERENCES titan_ref.carbon_transaction_type(carbon_transaction_type_code),
    instrument_lot_id text NOT NULL REFERENCES titan_core.instrument_lot(instrument_lot_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    quantity numeric NOT NULL CHECK (quantity > 0),
    transaction_date date NOT NULL,
    from_account_id text NULL REFERENCES titan_core.compliance_account(account_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    to_account_id text NULL REFERENCES titan_core.compliance_account(account_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    obligation_id text NULL REFERENCES titan_core.compliance_obligation(obligation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    transaction_notes text NULL,
    recorded_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_carbon_transaction_id CHECK (carbon_transaction_id ~ '^CTX-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_carbon_transaction_accounts CHECK (
        (carbon_transaction_type_code IN ('ISSUE','ALLOCATE','ADJUST_IN') AND from_account_id IS NULL AND to_account_id IS NOT NULL)
        OR
        (carbon_transaction_type_code IN ('PURCHASE','SALE','TRANSFER') AND from_account_id IS NOT NULL AND to_account_id IS NOT NULL AND from_account_id<>to_account_id)
        OR
        (carbon_transaction_type_code='BANK' AND from_account_id IS NOT NULL AND to_account_id=from_account_id)
        OR
        (carbon_transaction_type_code IN ('SURRENDER','CANCEL','ADJUST_OUT') AND from_account_id IS NOT NULL AND to_account_id IS NULL)
    ),
    CONSTRAINT ck_carbon_transaction_obligation CHECK (
        carbon_transaction_type_code<>'SURRENDER' OR obligation_id IS NOT NULL
    )
);

CREATE VIEW titan_core.compliance_account_lot_balance AS
WITH movements AS (
    SELECT to_account_id AS account_id,instrument_lot_id,quantity AS signed_quantity
    FROM titan_core.carbon_transaction
    WHERE to_account_id IS NOT NULL
      AND carbon_transaction_type_code<>'BANK'
    UNION ALL
    SELECT from_account_id AS account_id,instrument_lot_id,-quantity AS signed_quantity
    FROM titan_core.carbon_transaction
    WHERE from_account_id IS NOT NULL
      AND carbon_transaction_type_code<>'BANK'
)
SELECT account_id,instrument_lot_id,sum(signed_quantity) AS balance_quantity
FROM movements
GROUP BY account_id,instrument_lot_id;

CREATE OR REPLACE FUNCTION titan_core.validate_nonnegative_carbon_balance()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE acct text;
DECLARE lot text;
DECLARE bal numeric;
BEGIN
    lot := COALESCE(NEW.instrument_lot_id,OLD.instrument_lot_id);
    FOREACH acct IN ARRAY ARRAY[
        CASE WHEN TG_OP='DELETE' THEN OLD.from_account_id ELSE NEW.from_account_id END,
        CASE WHEN TG_OP='DELETE' THEN OLD.to_account_id ELSE NEW.to_account_id END
    ]
    LOOP
        IF acct IS NULL THEN CONTINUE; END IF;
        SELECT COALESCE(balance_quantity,0) INTO bal
        FROM titan_core.compliance_account_lot_balance
        WHERE account_id=acct AND instrument_lot_id=lot;
        IF bal < -0.0000000001 THEN
            RAISE EXCEPTION 'Carbon account % lot % would have negative balance %',acct,lot,bal;
        END IF;
    END LOOP;
    RETURN NULL;
END;
$$;

CREATE CONSTRAINT TRIGGER ct_carbon_transaction_balance
AFTER INSERT OR UPDATE OR DELETE ON titan_core.carbon_transaction
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION titan_core.validate_nonnegative_carbon_balance();

CREATE OR REPLACE FUNCTION titan_core.reject_carbon_transaction_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION 'carbon_transaction is immutable; post a correcting/reversing transaction instead';
END;
$$;

CREATE TRIGGER trg_carbon_transaction_immutable
BEFORE UPDATE OR DELETE ON titan_core.carbon_transaction
FOR EACH ROW EXECUTE FUNCTION titan_core.reject_carbon_transaction_mutation();

CREATE TABLE titan_core.compliance_settlement (
    settlement_id text PRIMARY KEY,
    obligation_id text NOT NULL REFERENCES titan_core.compliance_obligation(obligation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    settlement_version_no integer NOT NULL CHECK (settlement_version_no >= 1),
    verification_id text NULL REFERENCES titan_core.verification_record(verification_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    required_quantity numeric NULL CHECK (required_quantity IS NULL OR required_quantity >= 0),
    issued_or_allocated_quantity numeric NULL CHECK (issued_or_allocated_quantity IS NULL OR issued_or_allocated_quantity >= 0),
    surrendered_quantity numeric NULL CHECK (surrendered_quantity IS NULL OR surrendered_quantity >= 0),
    settlement_status_code text NOT NULL REFERENCES titan_ref.settlement_status(settlement_status_code),
    policy_rule_id text NULL REFERENCES titan_core.policy_formula_rule(policy_rule_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    supersedes_settlement_id text NULL REFERENCES titan_core.compliance_settlement(settlement_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    recorded_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    settlement_notes text NULL,
    CONSTRAINT ck_settlement_id CHECK (settlement_id ~ '^SET-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_settlement_not_self CHECK (supersedes_settlement_id IS NULL OR supersedes_settlement_id<>settlement_id),
    CONSTRAINT uq_settlement_version UNIQUE(obligation_id,settlement_version_no)
);

CREATE TABLE titan_core.enforcement_event (
    enforcement_id text PRIMARY KEY,
    obligation_id text NOT NULL REFERENCES titan_core.compliance_obligation(obligation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    enforcement_event_type_code text NOT NULL REFERENCES titan_ref.enforcement_event_type(enforcement_event_type_code),
    enforcement_status_code text NOT NULL REFERENCES titan_ref.enforcement_status(enforcement_status_code),
    event_date date NOT NULL,
    quantity_value numeric NULL,
    amount_value numeric NULL,
    amount_unit_code text NULL REFERENCES titan_core.unit_master(unit_code),
    amount_formula_text text NULL,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    supersedes_enforcement_id text NULL REFERENCES titan_core.enforcement_event(enforcement_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    enforcement_notes text NULL,
    CONSTRAINT ck_enforcement_id CHECK (enforcement_id ~ '^ENF-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_enforcement_not_self CHECK (supersedes_enforcement_id IS NULL OR supersedes_enforcement_id<>enforcement_id)
);

CREATE TABLE titan_core.policy_relief_rule (
    policy_relief_rule_id text PRIMARY KEY,
    source_scheme_id text NOT NULL REFERENCES titan_core.carbon_scheme(scheme_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    target_scheme_id text NOT NULL REFERENCES titan_core.carbon_scheme(scheme_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    policy_version_id text NOT NULL REFERENCES titan_core.policy_version(policy_version_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    eligible_instrument_or_payment text NOT NULL,
    relief_formula_text text NOT NULL,
    valid_from date NOT NULL,
    valid_to date NULL,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    relief_notes text NULL,
    CONSTRAINT ck_relief_rule_id CHECK (policy_relief_rule_id ~ '^RELIEF-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_relief_distinct_schemes CHECK (source_scheme_id<>target_scheme_id),
    CONSTRAINT ck_relief_formula CHECK (btrim(relief_formula_text) <> ''),
    CONSTRAINT ck_relief_dates CHECK (valid_to IS NULL OR valid_to>=valid_from)
);

CREATE OR REPLACE FUNCTION titan_core.ccts_certificate_position(
    target_gei numeric,
    achieved_gei numeric,
    equivalent_output numeric
)
RETURNS TABLE(issued_quantity numeric,required_quantity numeric)
LANGUAGE sql
IMMUTABLE
STRICT
AS $$
    SELECT
      CASE WHEN target_gei>achieved_gei THEN (target_gei-achieved_gei)*equivalent_output ELSE 0 END,
      CASE WHEN achieved_gei>target_gei THEN (achieved_gei-target_gei)*equivalent_output ELSE 0 END
$$;

CREATE OR REPLACE FUNCTION titan_core.cn_cement_allowance_2024(
    verified_emissions numeric,
    eligible boolean
)
RETURNS numeric
LANGUAGE sql
IMMUTABLE
STRICT
AS $$
    SELECT CASE WHEN eligible THEN verified_emissions ELSE 0 END
$$;

CREATE OR REPLACE FUNCTION titan_core.cn_cement_allowance_2025(
    verified_emissions numeric,
    verified_clinker_output numeric,
    industry_balance numeric,
    eligible boolean
)
RETURNS numeric
LANGUAGE plpgsql
IMMUTABLE
STRICT
AS $$
DECLARE
    intensity numeric;
    deviation_x numeric;
    alpha numeric;
BEGIN
    IF NOT eligible THEN RETURN 0; END IF;
    IF verified_emissions < 0 OR verified_clinker_output <= 0 OR industry_balance <= 0 THEN
        RAISE EXCEPTION 'Invalid China ETS allowance inputs';
    END IF;
    intensity := verified_emissions / verified_clinker_output;
    deviation_x := (industry_balance - intensity) / industry_balance;

    IF deviation_x >= 0.20 THEN
        alpha := 0.03;
    ELSIF deviation_x <= -0.20 THEN
        alpha := -0.03;
    ELSE
        alpha := 0.15 * deviation_x;
    END IF;

    RETURN verified_emissions * (1 + alpha);
END;
$$;


CREATE OR REPLACE FUNCTION titan_core.cn_cement_allowance_actual_emissions(
    verified_emissions numeric,
    eligible boolean
)
RETURNS numeric
LANGUAGE sql
IMMUTABLE
STRICT
AS $$
    SELECT CASE WHEN eligible THEN verified_emissions ELSE 0 END
$$;

COMMIT;
