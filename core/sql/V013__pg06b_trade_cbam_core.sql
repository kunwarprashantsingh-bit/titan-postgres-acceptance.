-- Global Cement Sustainability Intelligence
-- PostgreSQL Implementation v1.0 — PG-06B Trade / CBAM Carbon Exposure Core
-- Requires V001-V012.
BEGIN;

CREATE TABLE titan_ref.embedded_emissions_method (
    embedded_emissions_method_code text PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_ref.cbam_threshold_state (
    cbam_threshold_state_code text PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_ref.relief_eligibility_state (
    relief_eligibility_state_code text PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_ref.relief_calculation_status (
    relief_calculation_status_code text PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_ref.cbam_settlement_status (
    cbam_settlement_status_code text PRIMARY KEY,
    definition text NOT NULL
);

INSERT INTO titan_ref.embedded_emissions_method VALUES
('ACTUAL_VERIFIED','Actual embedded emissions supported by required verification'),
('DEFAULT','Legal default value under applicable CBAM rule/version'),
('MIXED_ALLOWED','Permitted combination of actual/default components with explicit lineage');

INSERT INTO titan_ref.cbam_threshold_state VALUES
('BELOW_THRESHOLD','Annual covered mass does not exceed threshold'),
('IN_SCOPE','Annual covered mass exceeds threshold'),
('EXEMPT_OTHER','Other explicit legal exemption'),
('PENDING','Threshold/applicability not yet resolved');

INSERT INTO titan_ref.relief_eligibility_state VALUES
('ELIGIBLE','Relief legally and evidentially eligible'),
('INELIGIBLE','Relief not eligible'),
('PENDING_RULE','Base legal principle exists but final detailed conversion rule is not yet available/bound'),
('EVIDENCE_INCOMPLETE','Required payment/certification evidence incomplete');

INSERT INTO titan_ref.relief_calculation_status VALUES
('DRAFT_CALC','Draft/test calculation; not production settlement'),
('FINAL_CALC','Final calculation under governing rule'),
('SUPERSEDED','Superseded calculation retained');

INSERT INTO titan_ref.cbam_settlement_status VALUES
('NOT_DUE','Declaration/surrender not yet due'),
('OPEN','Open'),
('PENDING_VERIFICATION','Verification incomplete'),
('COMPLIANT','Required certificates surrendered'),
('SHORTFALL','Certificates short'),
('CORRECTED','Corrected/superseding settlement');

CREATE TABLE titan_core.trade_shipment (
    shipment_id text PRIMARY KEY,
    shipment_date date NOT NULL,
    exporter_entity_id text NULL REFERENCES titan_core.entity_registry(entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    importer_entity_id text NULL REFERENCES titan_core.entity_registry(entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    country_of_dispatch_geo_id text NULL REFERENCES titan_core.geo_unit(geo_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    customs_origin_geo_id text NULL REFERENCES titan_core.geo_unit(geo_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    destination_geo_id text NULL REFERENCES titan_core.geo_unit(geo_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    shipment_notes text NULL,
    CONSTRAINT ck_shipment_id CHECK (shipment_id ~ '^SHP-[A-Za-z0-9][A-Za-z0-9._-]*$')
);

CREATE TABLE titan_core.shipment_line (
    shipment_line_id text PRIMARY KEY,
    shipment_id text NOT NULL REFERENCES titan_core.trade_shipment(shipment_id) ON UPDATE RESTRICT ON DELETE CASCADE,
    cn_hs_code text NOT NULL,
    classification_version text NOT NULL,
    product_version_id text NULL REFERENCES titan_core.product_version(product_version_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    material_id text NULL REFERENCES titan_core.material_master(material_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    net_mass_tonnes numeric NOT NULL CHECK (net_mass_tonnes>0),
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    line_notes text NULL,
    CONSTRAINT ck_shipment_line_id CHECK (shipment_line_id ~ '^SHPL-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_shipment_line_good CHECK (
        (product_version_id IS NOT NULL AND material_id IS NULL)
        OR
        (product_version_id IS NULL AND material_id IS NOT NULL)
    ),
    CONSTRAINT ck_cn_code_nonblank CHECK (btrim(cn_hs_code) <> ''),
    CONSTRAINT ck_classification_nonblank CHECK (btrim(classification_version) <> '')
);

CREATE TABLE titan_core.route_segment (
    route_segment_id text PRIMARY KEY,
    shipment_id text NOT NULL REFERENCES titan_core.trade_shipment(shipment_id) ON UPDATE RESTRICT ON DELETE CASCADE,
    segment_no integer NOT NULL CHECK (segment_no>=1),
    mode_code text NOT NULL,
    origin_geo_id text NULL REFERENCES titan_core.geo_unit(geo_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    destination_geo_id text NULL REFERENCES titan_core.geo_unit(geo_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    carrier_name text NULL,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    route_notes text NULL,
    CONSTRAINT ck_route_segment_id CHECK (route_segment_id ~ '^ROUTESEG-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT uq_route_segment_no UNIQUE(shipment_id,segment_no)
);

CREATE TABLE titan_core.production_installation_link (
    production_installation_link_id text PRIMARY KEY,
    shipment_line_id text NOT NULL REFERENCES titan_core.shipment_line(shipment_line_id) ON UPDATE RESTRICT ON DELETE CASCADE,
    installation_entity_id text NOT NULL REFERENCES titan_core.entity_registry(entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    production_period_start date NOT NULL,
    production_period_end date NOT NULL,
    attribution_share numeric(12,10) NULL CHECK (attribution_share IS NULL OR attribution_share BETWEEN 0 AND 1),
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    link_notes text NULL,
    CONSTRAINT ck_prod_link_id CHECK (production_installation_link_id ~ '^PRDLINK-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_prod_period CHECK (production_period_end>=production_period_start)
);

CREATE TABLE titan_core.embedded_emissions_declaration (
    embedded_emissions_declaration_id text PRIMARY KEY,
    shipment_line_id text NOT NULL REFERENCES titan_core.shipment_line(shipment_line_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    embedded_emissions_method_code text NOT NULL REFERENCES titan_ref.embedded_emissions_method(embedded_emissions_method_code),
    policy_version_id text NOT NULL REFERENCES titan_core.policy_version(policy_version_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    direct_emissions_observation_id text NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    indirect_emissions_observation_id text NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    precursor_emissions_observation_id text NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    total_embedded_emissions_observation_id text NOT NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    verifier_entity_id text NULL REFERENCES titan_core.entity_registry(entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    verifier_name_text text NULL,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    declaration_notes text NULL,
    CONSTRAINT ck_eed_id CHECK (embedded_emissions_declaration_id ~ '^EED-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_eed_verifier CHECK (
        embedded_emissions_method_code<>'ACTUAL_VERIFIED'
        OR verifier_entity_id IS NOT NULL OR verifier_name_text IS NOT NULL
    )
);

CREATE TABLE titan_core.precursor_allocation (
    precursor_allocation_id text PRIMARY KEY,
    shipment_line_id text NOT NULL REFERENCES titan_core.shipment_line(shipment_line_id) ON UPDATE RESTRICT ON DELETE CASCADE,
    precursor_material_id text NOT NULL REFERENCES titan_core.material_master(material_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    source_installation_entity_id text NOT NULL REFERENCES titan_core.entity_registry(entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    production_period_start date NOT NULL,
    production_period_end date NOT NULL,
    quantity_observation_id text NOT NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    intensity_observation_id text NOT NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    embedded_emissions_method_code text NOT NULL REFERENCES titan_ref.embedded_emissions_method(embedded_emissions_method_code),
    verifier_evidence_source_id text NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    allocation_notes text NULL,
    CONSTRAINT ck_precursor_alloc_id CHECK (precursor_allocation_id ~ '^PREC-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_precursor_period CHECK (production_period_end>=production_period_start)
);

CREATE TABLE titan_core.cbam_threshold_assessment (
    cbam_threshold_assessment_id text PRIMARY KEY,
    importer_entity_id text NOT NULL REFERENCES titan_core.entity_registry(entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    assessment_year integer NOT NULL CHECK (assessment_year BETWEEN 2026 AND 2200),
    cumulative_covered_mass_tonnes numeric NOT NULL CHECK (cumulative_covered_mass_tonnes>=0),
    threshold_tonnes numeric NOT NULL CHECK (threshold_tonnes>0),
    cbam_threshold_state_code text NOT NULL REFERENCES titan_ref.cbam_threshold_state(cbam_threshold_state_code),
    policy_version_id text NOT NULL REFERENCES titan_core.policy_version(policy_version_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    assessment_notes text NULL,
    CONSTRAINT ck_threshold_assessment_id CHECK (cbam_threshold_assessment_id ~ '^CBTH-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT uq_importer_threshold_year UNIQUE(importer_entity_id,assessment_year),
    CONSTRAINT ck_threshold_state_consistency CHECK (
        (cumulative_covered_mass_tonnes>threshold_tonnes AND cbam_threshold_state_code='IN_SCOPE')
        OR
        (cumulative_covered_mass_tonnes<=threshold_tonnes AND cbam_threshold_state_code IN ('BELOW_THRESHOLD','EXEMPT_OTHER','PENDING'))
    )
);

CREATE TABLE titan_core.cbam_price_reference (
    cbam_price_reference_id text PRIMARY KEY,
    price_year integer NOT NULL CHECK (price_year>=2026),
    price_period_label text NOT NULL,
    period_start date NOT NULL,
    period_end date NOT NULL,
    price_eur_per_certificate numeric NOT NULL CHECK (price_eur_per_certificate>0),
    publication_date date NOT NULL,
    policy_version_id text NOT NULL REFERENCES titan_core.policy_version(policy_version_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_cbam_price_id CHECK (cbam_price_reference_id ~ '^CBP-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_cbam_price_period CHECK (period_end>=period_start),
    CONSTRAINT uq_cbam_price_period UNIQUE(price_year,price_period_label)
);

CREATE TABLE titan_core.cbam_exposure (
    cbam_exposure_id text PRIMARY KEY,
    shipment_line_id text NOT NULL REFERENCES titan_core.shipment_line(shipment_line_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    embedded_emissions_declaration_id text NOT NULL REFERENCES titan_core.embedded_emissions_declaration(embedded_emissions_declaration_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    cbam_threshold_assessment_id text NOT NULL REFERENCES titan_core.cbam_threshold_assessment(cbam_threshold_assessment_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    cbam_price_reference_id text NOT NULL REFERENCES titan_core.cbam_price_reference(cbam_price_reference_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    free_allocation_adjustment_observation_id text NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    gross_exposure_observation_id text NOT NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    policy_version_id text NOT NULL REFERENCES titan_core.policy_version(policy_version_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    exposure_notes text NULL,
    CONSTRAINT ck_cbam_exposure_id CHECK (cbam_exposure_id ~ '^CBX-[A-Za-z0-9][A-Za-z0-9._-]*$')
);

CREATE TABLE titan_core.foreign_carbon_price_evidence (
    foreign_carbon_price_evidence_id text PRIMARY KEY,
    embedded_emissions_declaration_id text NOT NULL REFERENCES titan_core.embedded_emissions_declaration(embedded_emissions_declaration_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    foreign_scheme_name text NOT NULL,
    gross_price_paid_observation_id text NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    rebate_compensation_observation_id text NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    net_effective_price_observation_id text NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    payment_evidence_source_id text NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    independent_certifier_name text NULL,
    relief_eligibility_state_code text NOT NULL REFERENCES titan_ref.relief_eligibility_state(relief_eligibility_state_code),
    conversion_policy_version_id text NULL REFERENCES titan_core.policy_version(policy_version_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    evidence_notes text NULL,
    CONSTRAINT ck_fcpe_id CHECK (foreign_carbon_price_evidence_id ~ '^FCP-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_fcpe_pending_rule CHECK (
        relief_eligibility_state_code<>'PENDING_RULE'
        OR conversion_policy_version_id IS NULL
    )
);

CREATE TABLE titan_core.policy_relief_calculation (
    policy_relief_calculation_id text PRIMARY KEY,
    foreign_carbon_price_evidence_id text NOT NULL REFERENCES titan_core.foreign_carbon_price_evidence(foreign_carbon_price_evidence_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    relief_calculation_status_code text NOT NULL REFERENCES titan_ref.relief_calculation_status(relief_calculation_status_code),
    relief_observation_id text NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    governing_policy_version_id text NULL REFERENCES titan_core.policy_version(policy_version_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    calculation_method text NOT NULL,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    supersedes_relief_calculation_id text NULL REFERENCES titan_core.policy_relief_calculation(policy_relief_calculation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    calculation_notes text NULL,
    CONSTRAINT ck_relief_calc_id CHECK (policy_relief_calculation_id ~ '^REL-CALC-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_relief_calc_method CHECK (btrim(calculation_method) <> ''),
    CONSTRAINT ck_relief_calc_not_self CHECK (supersedes_relief_calculation_id IS NULL OR supersedes_relief_calculation_id<>policy_relief_calculation_id),
    CONSTRAINT ck_relief_final_requires_rule CHECK (
        relief_calculation_status_code<>'FINAL_CALC'
        OR (governing_policy_version_id IS NOT NULL AND relief_observation_id IS NOT NULL)
    )
);

CREATE TABLE titan_core.cbam_settlement (
    cbam_settlement_id text PRIMARY KEY,
    importer_entity_id text NOT NULL REFERENCES titan_core.entity_registry(entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    reporting_year integer NOT NULL CHECK (reporting_year>=2026),
    settlement_version_no integer NOT NULL CHECK (settlement_version_no>=1),
    certificates_required_observation_id text NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    relief_observation_id text NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    certificates_surrendered numeric NULL CHECK (certificates_surrendered IS NULL OR certificates_surrendered>=0),
    cbam_settlement_status_code text NOT NULL REFERENCES titan_ref.cbam_settlement_status(cbam_settlement_status_code),
    policy_version_id text NOT NULL REFERENCES titan_core.policy_version(policy_version_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    supersedes_cbam_settlement_id text NULL REFERENCES titan_core.cbam_settlement(cbam_settlement_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    settlement_notes text NULL,
    CONSTRAINT ck_cbam_settlement_id CHECK (cbam_settlement_id ~ '^CBS-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_cbam_settlement_not_self CHECK (supersedes_cbam_settlement_id IS NULL OR supersedes_cbam_settlement_id<>cbam_settlement_id),
    CONSTRAINT uq_cbam_settlement_version UNIQUE(importer_entity_id,reporting_year,settlement_version_no)
);

CREATE OR REPLACE FUNCTION titan_core.cbam_2026_default_effective_intensity(base_default numeric)
RETURNS numeric
LANGUAGE sql
IMMUTABLE
STRICT
AS $$
    SELECT base_default*1.10
$$;

CREATE OR REPLACE FUNCTION titan_core.cbam_gross_exposure(
    embedded_emissions_tco2 numeric,
    certificate_price_eur numeric
)
RETURNS numeric
LANGUAGE sql
IMMUTABLE
STRICT
AS $$
    SELECT embedded_emissions_tco2*certificate_price_eur
$$;

CREATE OR REPLACE FUNCTION titan_core.cbam_threshold_state_50t(cumulative_mass_t numeric)
RETURNS text
LANGUAGE sql
IMMUTABLE
STRICT
AS $$
    SELECT CASE WHEN cumulative_mass_t>50 THEN 'IN_SCOPE' ELSE 'BELOW_THRESHOLD' END
$$;

COMMIT;
