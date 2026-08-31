-- Global Cement Sustainability Intelligence
-- PostgreSQL Implementation v1.0 — PG-06A CCUS Chain & Attribute Integrity
-- Requires V001-V011.
BEGIN;

CREATE TABLE titan_ref.carbon_origin (
    carbon_origin_code text PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_ref.co2_batch_state (
    co2_batch_state_code text PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_ref.custody_event_type (
    custody_event_type_code text PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_ref.permanence_outcome (
    permanence_outcome_code text PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_ref.ccus_accounting_class (
    ccus_accounting_class_code text PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_ref.attribute_transaction_type (
    attribute_transaction_type_code text PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_ref.ccus_project_maturity (
    ccus_project_maturity_code text PRIMARY KEY,
    definition text NOT NULL
);

INSERT INTO titan_ref.carbon_origin VALUES
('MINERAL_PROCESS','CO2 originating from mineral/calcination process emissions'),
('FOSSIL_FUEL','CO2 originating from fossil fuel combustion'),
('BIOGENIC','CO2 originating from biogenic carbon'),
('ATMOSPHERIC','CO2 directly removed from atmosphere'),
('MIXED_UNKNOWN','Mixed stream whose component origins are not fully resolved');

INSERT INTO titan_ref.co2_batch_state VALUES
('CAPTURED','Captured from source process'),
('LIQUEFIED','Conditioned/liquefied'),
('TEMP_STORED','Temporarily stored before transport'),
('LOADED','Loaded to transport carrier'),
('IN_TRANSIT','In transport'),
('TERMINAL_STORED','Stored at receiving terminal'),
('PIPELINE','In pipeline/transport infrastructure'),
('INJECTED','Injected into geological formation'),
('STORED_CERTIFIED','Permanently stored and certified'),
('UTILISED','Transferred to utilization'),
('VENTED','Intentionally vented/released'),
('LOST','Measured/estimated loss/fugitive release'),
('IN_CHAIN_UNRECONCILED','Transferred into value chain but not yet evidenced as stored, released or lost');

INSERT INTO titan_ref.custody_event_type VALUES
('CAPTURE','Capture-meter event'),
('TEMP_STORAGE_IN','Temporary storage receipt'),
('LOAD','Loading custody transfer'),
('UNLOAD','Unloading custody transfer'),
('TERMINAL_RECEIPT','Terminal receipt'),
('PIPELINE_ENTRY','Pipeline entry'),
('PIPELINE_EXIT','Pipeline exit'),
('INJECTION','Injection meter event'),
('VENT','Venting event'),
('LOSS','Loss/reconciliation event'),
('CERTIFY_STORAGE','Storage certification event'),
('CORRECTION','Corrected/superseding measurement event');

INSERT INTO titan_ref.permanence_outcome VALUES
('PERMANENT_GEOLOGIC','Permanent geological storage under qualifying method'),
('PERMANENT_PRODUCT','Permanent chemical/product binding under qualifying method'),
('TEMPORARY','Temporary use/storage'),
('REEMITTED','Expected/actual re-emission'),
('UNRESOLVED','Permanence not sufficiently evidenced');

INSERT INTO titan_ref.ccus_accounting_class VALUES
('EMISSION_NOT_RELEASED','Fossil/mineral emission captured and permanently stored rather than released'),
('REMOVAL','Atmospheric/biogenic removal meeting methodology safeguards'),
('PERMANENT_PRODUCT_STORAGE','Qualifying permanent product/mineral storage'),
('AVOIDED_EMISSION','Avoided-emission analytical item, not inventory removal'),
('NO_REDUCTION','No permanent accounting benefit'),
('PENDING','Accounting classification pending evidence/method');

INSERT INTO titan_ref.attribute_transaction_type VALUES
('GENERATE','Generate verified product/environmental attributes'),
('ALLOCATE','Allocate attributes to product/customer'),
('TRANSFER','Transfer attributes between controlled accounts'),
('RETIRE','Retire attributes against a claim/product'),
('CANCEL','Cancel/void attributes'),
('ADJUST_IN','Administrative increase with evidence'),
('ADJUST_OUT','Administrative decrease/correction');

INSERT INTO titan_ref.ccus_project_maturity VALUES
('ANNOUNCED','Announced only'),
('FEASIBILITY','Feasibility/pre-FEED'),
('FEED','Front-end engineering/design'),
('PERMITTED','Material permits obtained'),
('FID','Final investment decision / funded'),
('CONSTRUCTION','Under construction'),
('COMMISSIONING','Commissioning/ramp-up'),
('OPERATING','Operating'),
('SUSPENDED','Suspended'),
('CANCELLED','Cancelled');

CREATE TABLE titan_core.ccus_project (
    ccus_project_id text PRIMARY KEY
        REFERENCES titan_core.entity_registry(entity_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    project_name text NOT NULL,
    source_entity_id text NULL REFERENCES titan_core.entity_registry(entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    source_name_text text NULL,
    ccus_project_maturity_code text NOT NULL REFERENCES titan_ref.ccus_project_maturity(ccus_project_maturity_code),
    valid_from date NULL,
    valid_to date NULL,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    project_notes text NULL,
    CONSTRAINT ck_ccus_project_name CHECK (btrim(project_name) <> ''),
    CONSTRAINT ck_ccus_project_source CHECK (source_entity_id IS NOT NULL OR source_name_text IS NOT NULL),
    CONSTRAINT ck_ccus_project_dates CHECK (valid_to IS NULL OR valid_from IS NULL OR valid_to >= valid_from)
);

CREATE TRIGGER trg_ccus_project_type
BEFORE INSERT OR UPDATE ON titan_core.ccus_project
FOR EACH ROW EXECUTE FUNCTION titan_core.validate_child_entity_type('ccus_project_id','CCUS_PROJECT');

CREATE TABLE titan_core.capture_asset (
    capture_asset_id text PRIMARY KEY,
    ccus_project_id text NOT NULL REFERENCES titan_core.ccus_project(ccus_project_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    titan_asset_id text NULL REFERENCES titan_core.entity_registry(entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    asset_name text NOT NULL,
    technology text NULL,
    design_capacity_observation_id text NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    valid_from date NULL,
    valid_to date NULL,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_capture_asset_id CHECK (capture_asset_id ~ '^CAP-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_capture_asset_name CHECK (btrim(asset_name) <> ''),
    CONSTRAINT ck_capture_asset_dates CHECK (valid_to IS NULL OR valid_from IS NULL OR valid_to>=valid_from)
);

CREATE TABLE titan_core.capture_stream (
    capture_stream_id text PRIMARY KEY,
    capture_asset_id text NOT NULL REFERENCES titan_core.capture_asset(capture_asset_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    stream_name text NOT NULL,
    source_process text NULL,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_capture_stream_id CHECK (capture_stream_id ~ '^CSTR-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_capture_stream_name CHECK (btrim(stream_name) <> '')
);

CREATE TABLE titan_core.co2_batch (
    co2_batch_id text PRIMARY KEY,
    capture_stream_id text NOT NULL REFERENCES titan_core.capture_stream(capture_stream_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    batch_label text NOT NULL,
    capture_period_start date NOT NULL,
    capture_period_end date NOT NULL,
    captured_quantity_observation_id text NOT NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    current_state_code text NOT NULL REFERENCES titan_ref.co2_batch_state(co2_batch_state_code),
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    batch_notes text NULL,
    CONSTRAINT ck_co2_batch_id CHECK (co2_batch_id ~ '^CO2B-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_co2_batch_period CHECK (capture_period_end>=capture_period_start)
);

CREATE TABLE titan_core.co2_batch_origin_component (
    co2_batch_id text NOT NULL REFERENCES titan_core.co2_batch(co2_batch_id) ON UPDATE RESTRICT ON DELETE CASCADE,
    carbon_origin_code text NOT NULL REFERENCES titan_ref.carbon_origin(carbon_origin_code),
    origin_share numeric(12,10) NULL CHECK (origin_share IS NULL OR origin_share BETWEEN 0 AND 1),
    quantity_observation_id text NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    PRIMARY KEY(co2_batch_id,carbon_origin_code)
);

CREATE OR REPLACE FUNCTION titan_core.validate_co2_origin_total()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE b text;
DECLARE total_share numeric;
BEGIN
    IF TG_OP='DELETE' THEN b:=OLD.co2_batch_id; ELSE b:=NEW.co2_batch_id; END IF;
    SELECT COALESCE(sum(origin_share),0) INTO total_share
    FROM titan_core.co2_batch_origin_component
    WHERE co2_batch_id=b AND origin_share IS NOT NULL;
    IF total_share>1.0000000001 THEN
        RAISE EXCEPTION 'CO2 batch % origin shares exceed 1.0: %',b,total_share;
    END IF;
    RETURN NULL;
END;
$$;

CREATE CONSTRAINT TRIGGER ct_co2_origin_total
AFTER INSERT OR UPDATE OR DELETE ON titan_core.co2_batch_origin_component
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION titan_core.validate_co2_origin_total();

CREATE TABLE titan_core.co2_custody_event (
    custody_event_id text PRIMARY KEY,
    co2_batch_id text NOT NULL REFERENCES titan_core.co2_batch(co2_batch_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    custody_event_type_code text NOT NULL REFERENCES titan_ref.custody_event_type(custody_event_type_code),
    event_time timestamptz NOT NULL,
    from_party_or_asset text NULL,
    to_party_or_asset text NULL,
    quantity_observation_id text NOT NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    measurement_method_id text NULL REFERENCES titan_core.measurement_method(measurement_method_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    supersedes_custody_event_id text NULL REFERENCES titan_core.co2_custody_event(custody_event_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    event_notes text NULL,
    CONSTRAINT ck_custody_event_id CHECK (custody_event_id ~ '^CUST-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_custody_not_self CHECK (supersedes_custody_event_id IS NULL OR supersedes_custody_event_id<>custody_event_id)
);

CREATE TABLE titan_core.co2_chain_state (
    co2_chain_state_id text PRIMARY KEY,
    co2_batch_id text NOT NULL REFERENCES titan_core.co2_batch(co2_batch_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    co2_batch_state_code text NOT NULL REFERENCES titan_ref.co2_batch_state(co2_batch_state_code),
    as_of_date date NOT NULL,
    quantity_observation_id text NOT NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    state_notes text NULL,
    CONSTRAINT ck_chain_state_id CHECK (co2_chain_state_id ~ '^CSTATE-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT uq_batch_state_asof UNIQUE(co2_batch_id,co2_batch_state_code,as_of_date)
);

CREATE TABLE titan_core.storage_site (
    storage_site_id text PRIMARY KEY,
    storage_site_name text NOT NULL,
    jurisdiction_geo_id text NULL REFERENCES titan_core.geo_unit(geo_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    operator_name text NULL,
    storage_type text NOT NULL,
    permit_ref text NULL,
    design_capacity_observation_id text NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_storage_site_id CHECK (storage_site_id ~ '^STOR-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_storage_site_name CHECK (btrim(storage_site_name) <> ''),
    CONSTRAINT ck_storage_type CHECK (btrim(storage_type) <> '')
);

CREATE TABLE titan_core.injection_event (
    injection_event_id text PRIMARY KEY,
    co2_batch_id text NOT NULL REFERENCES titan_core.co2_batch(co2_batch_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    storage_site_id text NOT NULL REFERENCES titan_core.storage_site(storage_site_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    injection_date date NOT NULL,
    injected_quantity_observation_id text NOT NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    injection_notes text NULL,
    CONSTRAINT ck_injection_event_id CHECK (injection_event_id ~ '^INJ-[A-Za-z0-9][A-Za-z0-9._-]*$')
);

CREATE TABLE titan_core.storage_certificate (
    storage_certificate_id text PRIMARY KEY,
    co2_batch_id text NOT NULL REFERENCES titan_core.co2_batch(co2_batch_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    storage_site_id text NOT NULL REFERENCES titan_core.storage_site(storage_site_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    certificate_number text NOT NULL,
    certificate_date date NOT NULL,
    certified_stored_observation_id text NOT NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    lifecycle_emissions_observation_id text NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    assurance_source_id text NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    supersedes_storage_certificate_id text NULL REFERENCES titan_core.storage_certificate(storage_certificate_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    certificate_notes text NULL,
    CONSTRAINT ck_storage_cert_id CHECK (storage_certificate_id ~ '^SCERT-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_storage_cert_number CHECK (btrim(certificate_number) <> ''),
    CONSTRAINT ck_storage_cert_not_self CHECK (supersedes_storage_certificate_id IS NULL OR supersedes_storage_certificate_id<>storage_certificate_id)
);

CREATE TABLE titan_core.permanence_assessment (
    permanence_assessment_id text PRIMARY KEY,
    storage_certificate_id text NULL REFERENCES titan_core.storage_certificate(storage_certificate_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    co2_batch_id text NOT NULL REFERENCES titan_core.co2_batch(co2_batch_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    permanence_outcome_code text NOT NULL REFERENCES titan_ref.permanence_outcome(permanence_outcome_code),
    methodology_version_id text NULL REFERENCES titan_core.methodology_version(methodology_version_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    assessed_quantity_observation_id text NOT NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    assessment_notes text NULL,
    CONSTRAINT ck_perm_assessment_id CHECK (permanence_assessment_id ~ '^PERM-[A-Za-z0-9][A-Za-z0-9._-]*$')
);

CREATE TABLE titan_core.ccus_accounting_result (
    ccus_accounting_result_id text PRIMARY KEY,
    co2_batch_id text NOT NULL REFERENCES titan_core.co2_batch(co2_batch_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    storage_certificate_id text NULL REFERENCES titan_core.storage_certificate(storage_certificate_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    ccus_accounting_class_code text NOT NULL REFERENCES titan_ref.ccus_accounting_class(ccus_accounting_class_code),
    quantity_observation_id text NOT NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    methodology_version_id text NULL REFERENCES titan_core.methodology_version(methodology_version_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    accounting_notes text NULL,
    CONSTRAINT ck_ccus_accounting_result_id CHECK (ccus_accounting_result_id ~ '^CCAR-[A-Za-z0-9][A-Za-z0-9._-]*$')
);

CREATE TABLE titan_core.carbon_attribute_scheme (
    attribute_scheme_id text PRIMARY KEY,
    scheme_name text NOT NULL,
    scheme_owner_name text NOT NULL,
    generation_basis text NOT NULL,
    assurance_basis text NULL,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_attribute_scheme_id CHECK (attribute_scheme_id ~ '^ATTRSCHEME-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_attribute_scheme_name CHECK (btrim(scheme_name) <> '')
);

CREATE TABLE titan_core.carbon_attribute_lot (
    attribute_lot_id text PRIMARY KEY,
    attribute_scheme_id text NOT NULL REFERENCES titan_core.carbon_attribute_scheme(attribute_scheme_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    ccus_project_id text NOT NULL REFERENCES titan_core.ccus_project(ccus_project_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    storage_certificate_id text NOT NULL REFERENCES titan_core.storage_certificate(storage_certificate_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    eligible_quantity_observation_id text NOT NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    vintage_label text NOT NULL,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_attribute_lot_id CHECK (attribute_lot_id ~ '^ATTRLOT-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_attribute_vintage CHECK (btrim(vintage_label) <> '')
);

CREATE TABLE titan_core.carbon_attribute_transaction (
    attribute_transaction_id text PRIMARY KEY,
    attribute_transaction_type_code text NOT NULL REFERENCES titan_ref.attribute_transaction_type(attribute_transaction_type_code),
    attribute_lot_id text NOT NULL REFERENCES titan_core.carbon_attribute_lot(attribute_lot_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    quantity numeric NOT NULL CHECK (quantity>0),
    transaction_date date NOT NULL,
    from_account_ref text NULL,
    to_account_ref text NULL,
    product_version_id text NULL REFERENCES titan_core.product_version(product_version_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    claim_ref text NULL,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    transaction_notes text NULL,
    recorded_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_attribute_transaction_id CHECK (attribute_transaction_id ~ '^ATX-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_attribute_accounts CHECK (
        (attribute_transaction_type_code='GENERATE' AND from_account_ref IS NULL AND to_account_ref IS NOT NULL)
        OR
        (attribute_transaction_type_code IN ('ALLOCATE','TRANSFER') AND from_account_ref IS NOT NULL AND to_account_ref IS NOT NULL AND from_account_ref<>to_account_ref)
        OR
        (attribute_transaction_type_code IN ('RETIRE','CANCEL','ADJUST_OUT') AND from_account_ref IS NOT NULL AND to_account_ref IS NULL)
        OR
        (attribute_transaction_type_code='ADJUST_IN' AND from_account_ref IS NULL AND to_account_ref IS NOT NULL)
    )
);

CREATE VIEW titan_core.carbon_attribute_account_balance AS
WITH m AS (
    SELECT to_account_ref AS account_ref,attribute_lot_id,quantity AS q
    FROM titan_core.carbon_attribute_transaction
    WHERE to_account_ref IS NOT NULL
    UNION ALL
    SELECT from_account_ref AS account_ref,attribute_lot_id,-quantity AS q
    FROM titan_core.carbon_attribute_transaction
    WHERE from_account_ref IS NOT NULL
)
SELECT account_ref,attribute_lot_id,sum(q) AS balance_quantity
FROM m
GROUP BY account_ref,attribute_lot_id;

CREATE OR REPLACE FUNCTION titan_core.validate_attribute_balance()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE acct text;
DECLARE lot text;
DECLARE bal numeric;
DECLARE cert_qty numeric;
DECLARE generated_qty numeric;
BEGIN
    IF TG_OP='DELETE' THEN lot:=OLD.attribute_lot_id; ELSE lot:=NEW.attribute_lot_id; END IF;

    FOREACH acct IN ARRAY ARRAY[
        CASE WHEN TG_OP='DELETE' THEN OLD.from_account_ref ELSE NEW.from_account_ref END,
        CASE WHEN TG_OP='DELETE' THEN OLD.to_account_ref ELSE NEW.to_account_ref END
    ]
    LOOP
        IF acct IS NULL THEN CONTINUE; END IF;
        SELECT COALESCE(balance_quantity,0) INTO bal
        FROM titan_core.carbon_attribute_account_balance
        WHERE account_ref=acct AND attribute_lot_id=lot;
        IF bal < -0.0000000001 THEN
            RAISE EXCEPTION 'Carbon attribute account % lot % would have negative balance %',acct,lot,bal;
        END IF;
    END LOOP;

    SELECT o.numeric_value INTO cert_qty
    FROM titan_core.carbon_attribute_lot l
    JOIN titan_core.storage_certificate c ON c.storage_certificate_id=l.storage_certificate_id
    JOIN titan_core.observation o ON o.observation_id=c.certified_stored_observation_id
    WHERE l.attribute_lot_id=lot;

    SELECT COALESCE(sum(quantity),0) INTO generated_qty
    FROM titan_core.carbon_attribute_transaction
    WHERE attribute_lot_id=lot
      AND attribute_transaction_type_code IN ('GENERATE','ADJUST_IN');

    IF cert_qty IS NOT NULL AND generated_qty > cert_qty + 0.0000000001 THEN
        RAISE EXCEPTION 'Attribute lot % generation % exceeds certified stored quantity %',lot,generated_qty,cert_qty;
    END IF;

    RETURN NULL;
END;
$$;

CREATE CONSTRAINT TRIGGER ct_attribute_balance
AFTER INSERT OR UPDATE OR DELETE ON titan_core.carbon_attribute_transaction
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION titan_core.validate_attribute_balance();

CREATE OR REPLACE FUNCTION titan_core.reject_attribute_transaction_mutation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION 'carbon_attribute_transaction is immutable; use a correcting transaction';
END;
$$;

CREATE TRIGGER trg_attribute_transaction_immutable
BEFORE UPDATE OR DELETE ON titan_core.carbon_attribute_transaction
FOR EACH ROW EXECUTE FUNCTION titan_core.reject_attribute_transaction_mutation();

COMMIT;
