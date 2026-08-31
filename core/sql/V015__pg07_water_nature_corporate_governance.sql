-- Global Cement Sustainability Intelligence
-- PostgreSQL Implementation v1.0 — PG-07 Water, Nature & Corporate Transition Governance
-- Requires V001-V014.
BEGIN;

CREATE TABLE titan_ref.water_source_type (
    water_source_type_code text PRIMARY KEY,
    freshwater_flag boolean NOT NULL,
    definition text NOT NULL
);
CREATE TABLE titan_ref.water_flow_role (
    water_flow_role_code text PRIMARY KEY,
    definition text NOT NULL
);
CREATE TABLE titan_ref.biodiversity_action_type (
    biodiversity_action_type_code text PRIMARY KEY,
    hierarchy_rank integer NOT NULL CHECK (hierarchy_rank>=1),
    definition text NOT NULL
);
CREATE TABLE titan_ref.target_validation_status (
    target_validation_status_code text PRIMARY KEY,
    definition text NOT NULL
);
CREATE TABLE titan_ref.gross_net_target_type (
    gross_net_target_type_code text PRIMARY KEY,
    definition text NOT NULL
);
CREATE TABLE titan_ref.target_recalc_trigger (
    target_recalc_trigger_code text PRIMARY KEY,
    definition text NOT NULL
);
CREATE TABLE titan_ref.target_recalc_result (
    target_recalc_result_code text PRIMARY KEY,
    definition text NOT NULL
);
CREATE TABLE titan_ref.capex_class (
    capex_class_code text PRIMARY KEY,
    definition text NOT NULL
);
-- titan_ref.assurance_level is defined once in V008 and reused here.
CREATE TABLE titan_ref.membership_status (
    membership_status_code text PRIMARY KEY,
    definition text NOT NULL
);
CREATE TABLE titan_ref.alignment_state (
    alignment_state_code text PRIMARY KEY,
    definition text NOT NULL
);

INSERT INTO titan_ref.water_source_type VALUES
('SURFACE_FRESH',true,'Fresh surface water'),
('GROUNDWATER_FRESH',true,'Fresh groundwater'),
('RAINWATER',false,'Harvested rainwater'),
('SEAWATER',false,'Seawater/brackish source'),
('THIRD_PARTY_FRESH',true,'Purchased/third-party freshwater'),
('THIRD_PARTY_RECYCLED',false,'Purchased/third-party recycled water'),
('RECYCLED_INTERNAL',false,'Internally recycled/reused water'),
('MINE_DEWATERING',false,'Mine/quarry dewatering flow; freshwater classification must be evaluated separately if needed'),
('OTHER',false,'Other explicit source type');

INSERT INTO titan_ref.water_flow_role VALUES
('WITHDRAWAL','Water withdrawn from source'),
('DISCHARGE','Water discharged to receiving body/third party'),
('CONSUMPTION','Water consumed within defined period/boundary'),
('TRANSFER','Water transferred between internal/external assets'),
('RECYCLE','Water recycled/reused'),
('DEWATERING_INFLOW','Mine/quarry dewatering inflow'),
('OPENING_STORAGE','Opening stored water'),
('CLOSING_STORAGE','Closing stored water');

INSERT INTO titan_ref.biodiversity_action_type VALUES
('AVOID',1,'Avoid impact'),
('MINIMIZE',2,'Minimize unavoidable impact'),
('RESTORE',3,'Restore affected ecosystem'),
('REHABILITATE',3,'Rehabilitate affected land/ecosystem'),
('OFFSET',4,'Offset residual impact'),
('CONSERVE',5,'Conservation action not used to erase direct residual impact'),
('TRANSFORM',6,'Transformative/system-level action');

INSERT INTO titan_ref.target_validation_status VALUES
('VALIDATED','Validated by named framework/body'),
('COMMITTED','Committed/submitted but not validated'),
('COMPANY_ONLY','Company-defined target only'),
('EXPIRED','Target expired'),
('WITHDRAWN','Target withdrawn'),
('SUPERSEDED','Target superseded');

INSERT INTO titan_ref.gross_net_target_type VALUES
('GROSS','Gross target'),
('NET','Net target'),
('BOTH','Target explicitly contains linked gross and net components');

INSERT INTO titan_ref.target_recalc_trigger VALUES
('M_AND_A','Merger/acquisition'),
('DIVESTMENT','Divestment'),
('BOUNDARY_CHANGE','Organizational/operational boundary change'),
('CONSOLIDATION_CHANGE','Consolidation approach change'),
('SCOPE_SHIFT','Activity/scope/category shift'),
('METHODOLOGY_CHANGE','Methodology change'),
('DATA_QUALITY','Data quality improvement'),
('ERROR_CORRECTION','Data/calculation error'),
('OTHER','Other documented trigger');

INSERT INTO titan_ref.target_recalc_result VALUES
('RECALCULATE','Recalculation required'),
('EVALUATED_BELOW_THRESHOLD','Evaluated but below applicable significance threshold'),
('NOT_REQUIRED','No recalculation required under applicable framework'),
('PENDING','Evaluation pending');

INSERT INTO titan_ref.capex_class VALUES
('TRANSITION','Evidence-backed transition/decarbonization capex'),
('MAINTENANCE','Ordinary maintenance/replacement'),
('COMPLIANCE','Regulatory compliance capex without demonstrated transition attribution'),
('GROWTH','Growth/expansion capex'),
('OTHER','Other/unclear capex');

-- Assurance-level reference values are seeded in V008; no duplicate seed in V015.

INSERT INTO titan_ref.membership_status VALUES
('ACTIVE','Active member'),
('INACTIVE','Inactive'),
('WITHDRAWN','Withdrawn/resigned'),
('SUSPENDED','Suspended');

INSERT INTO titan_ref.alignment_state VALUES
('ALIGNED','Company and association positions aligned'),
('PARTIALLY_ALIGNED','Partial alignment'),
('CONFLICT','Material conflict'),
('UNKNOWN','Insufficient evidence');

CREATE TABLE titan_core.water_source (
    water_source_id text PRIMARY KEY,
    site_or_asset_entity_id text NOT NULL REFERENCES titan_core.entity_registry(entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    water_source_type_code text NOT NULL REFERENCES titan_ref.water_source_type(water_source_type_code),
    source_name text NOT NULL,
    basin_ref text NULL,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    valid_from date NULL,
    valid_to date NULL,
    source_notes text NULL,
    CONSTRAINT ck_water_source_id CHECK (water_source_id ~ '^WTRSRC-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_water_source_name CHECK (btrim(source_name) <> ''),
    CONSTRAINT ck_water_source_dates CHECK (valid_to IS NULL OR valid_from IS NULL OR valid_to>=valid_from)
);

CREATE TABLE titan_core.water_flow (
    water_flow_id text PRIMARY KEY,
    site_or_asset_entity_id text NOT NULL REFERENCES titan_core.entity_registry(entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    water_source_id text NULL REFERENCES titan_core.water_source(water_source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    water_flow_role_code text NOT NULL REFERENCES titan_ref.water_flow_role(water_flow_role_code),
    quantity_observation_id text NOT NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    receiving_body_text text NULL,
    period_start date NOT NULL,
    period_end date NOT NULL,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    flow_notes text NULL,
    CONSTRAINT ck_water_flow_id CHECK (water_flow_id ~ '^WTRF-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_water_flow_period CHECK (period_end>=period_start)
);

CREATE TABLE titan_core.water_balance (
    water_balance_id text PRIMARY KEY,
    site_or_asset_entity_id text NOT NULL REFERENCES titan_core.entity_registry(entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    boundary_version_id bigint NULL REFERENCES titan_core.boundary_version(boundary_version_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    period_start date NOT NULL,
    period_end date NOT NULL,
    opening_storage_observation_id text NOT NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    withdrawal_observation_id text NOT NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    other_inflow_observation_id text NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    discharge_observation_id text NOT NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    closing_storage_observation_id text NOT NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    consumption_observation_id text NOT NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    balance_notes text NULL,
    CONSTRAINT ck_water_balance_id CHECK (water_balance_id ~ '^WB-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_water_balance_period CHECK (period_end>=period_start)
);

CREATE OR REPLACE FUNCTION titan_core.validate_water_balance()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE op numeric;
DECLARE wd numeric;
DECLARE infl numeric;
DECLARE dis numeric;
DECLARE cl numeric;
DECLARE con numeric;
DECLARE ids text[];
DECLARE oid text;
DECLARE osub text;
DECLARE ostart date;
DECLARE oend date;
BEGIN
    ids:=ARRAY[
        NEW.opening_storage_observation_id,
        NEW.withdrawal_observation_id,
        NEW.other_inflow_observation_id,
        NEW.discharge_observation_id,
        NEW.closing_storage_observation_id,
        NEW.consumption_observation_id
    ];
    FOREACH oid IN ARRAY ids LOOP
        IF oid IS NULL THEN CONTINUE; END IF;
        SELECT subject_entity_id,period_start,period_end INTO osub,ostart,oend
        FROM titan_core.observation WHERE observation_id=oid;
        IF osub IS DISTINCT FROM NEW.site_or_asset_entity_id THEN
            RAISE EXCEPTION 'Water balance % observation % belongs to different subject %',NEW.water_balance_id,oid,osub;
        END IF;
        IF ostart IS DISTINCT FROM NEW.period_start OR oend IS DISTINCT FROM NEW.period_end THEN
            RAISE EXCEPTION 'Water balance % observation % period mismatch',NEW.water_balance_id,oid;
        END IF;
    END LOOP;

    SELECT numeric_value INTO op FROM titan_core.observation WHERE observation_id=NEW.opening_storage_observation_id;
    SELECT numeric_value INTO wd FROM titan_core.observation WHERE observation_id=NEW.withdrawal_observation_id;
    IF NEW.other_inflow_observation_id IS NULL THEN infl:=0;
    ELSE SELECT numeric_value INTO infl FROM titan_core.observation WHERE observation_id=NEW.other_inflow_observation_id; END IF;
    SELECT numeric_value INTO dis FROM titan_core.observation WHERE observation_id=NEW.discharge_observation_id;
    SELECT numeric_value INTO cl FROM titan_core.observation WHERE observation_id=NEW.closing_storage_observation_id;
    SELECT numeric_value INTO con FROM titan_core.observation WHERE observation_id=NEW.consumption_observation_id;

    IF abs((op+wd+infl-dis-cl)-con)>0.000001 THEN
        RAISE EXCEPTION 'Water balance % does not reconcile',NEW.water_balance_id;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_water_balance
BEFORE INSERT OR UPDATE ON titan_core.water_balance
FOR EACH ROW EXECUTE FUNCTION titan_core.validate_water_balance();

CREATE TABLE titan_core.basin_context (
    basin_context_id text PRIMARY KEY,
    site_or_asset_entity_id text NOT NULL REFERENCES titan_core.entity_registry(entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    basin_name text NOT NULL,
    assessment_framework text NOT NULL,
    assessment_version text NOT NULL,
    assessment_date date NOT NULL,
    risk_or_pressure_state text NOT NULL,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    context_notes text NULL,
    CONSTRAINT ck_basin_context_id CHECK (basin_context_id ~ '^BASIN-[A-Za-z0-9][A-Za-z0-9._-]*$')
);

CREATE TABLE titan_core.water_target (
    water_target_id text PRIMARY KEY,
    target_boundary_entity_id text NOT NULL REFERENCES titan_core.entity_registry(entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    basin_context_id text NULL REFERENCES titan_core.basin_context(basin_context_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    baseline_observation_id text NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    required_reduction_observation_id text NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    target_observation_id text NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    allocation_method text NULL,
    framework_version text NULL,
    framework_status text NULL,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    target_notes text NULL,
    CONSTRAINT ck_water_target_id CHECK (water_target_id ~ '^WTGT-[A-Za-z0-9][A-Za-z0-9._-]*$')
);

CREATE TABLE titan_core.nature_site_context (
    nature_context_id text PRIMARY KEY,
    site_or_quarry_entity_id text NOT NULL REFERENCES titan_core.entity_registry(entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    polygon_ref text NOT NULL,
    assessment_framework text NOT NULL,
    assessment_version text NOT NULL,
    assessment_date date NOT NULL,
    sensitive_area_name text NULL,
    sensitive_area_type text NULL,
    distance_km numeric NULL CHECK (distance_km IS NULL OR distance_km>=0),
    overlap_flag boolean NULL,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    context_notes text NULL,
    CONSTRAINT ck_nature_context_id CHECK (nature_context_id ~ '^NATCTX-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_nature_polygon CHECK (btrim(polygon_ref) <> '')
);

CREATE TABLE titan_core.ecosystem_condition_observation (
    ecosystem_condition_observation_id text PRIMARY KEY,
    nature_context_id text NOT NULL REFERENCES titan_core.nature_site_context(nature_context_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    observation_id text NOT NULL UNIQUE REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    condition_metric text NOT NULL,
    reference_area_text text NULL,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_eco_obs_id CHECK (ecosystem_condition_observation_id ~ '^ECO-[A-Za-z0-9][A-Za-z0-9._-]*$')
);

CREATE TABLE titan_core.biodiversity_impact (
    biodiversity_impact_id text PRIMARY KEY,
    nature_context_id text NOT NULL REFERENCES titan_core.nature_site_context(nature_context_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    impact_driver text NOT NULL,
    affected_ecosystem_or_species text NOT NULL,
    residual_impact_state text NOT NULL,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    impact_notes text NULL,
    CONSTRAINT ck_bio_impact_id CHECK (biodiversity_impact_id ~ '^BIOIMP-[A-Za-z0-9][A-Za-z0-9._-]*$')
);

CREATE TABLE titan_core.biodiversity_action (
    biodiversity_action_id text PRIMARY KEY,
    biodiversity_impact_id text NOT NULL REFERENCES titan_core.biodiversity_impact(biodiversity_impact_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    biodiversity_action_type_code text NOT NULL REFERENCES titan_ref.biodiversity_action_type(biodiversity_action_type_code),
    action_location_ref text NOT NULL,
    action_area_ha numeric NULL CHECK (action_area_ha IS NULL OR action_area_ha>=0),
    period_start date NULL,
    period_end date NULL,
    milestone_state text NULL,
    outcome_observation_id text NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    action_notes text NULL,
    CONSTRAINT ck_bio_action_id CHECK (biodiversity_action_id ~ '^BIOACT-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_bio_action_dates CHECK (period_end IS NULL OR period_start IS NULL OR period_end>=period_start)
);

CREATE TABLE titan_core.offset_relationship (
    offset_relationship_id text PRIMARY KEY,
    biodiversity_impact_id text NOT NULL REFERENCES titan_core.biodiversity_impact(biodiversity_impact_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    biodiversity_action_id text NOT NULL REFERENCES titan_core.biodiversity_action(biodiversity_action_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    equivalence_method text NOT NULL,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    relationship_notes text NULL,
    CONSTRAINT ck_offset_rel_id CHECK (offset_relationship_id ~ '^OFFREL-[A-Za-z0-9][A-Za-z0-9._-]*$')
);

CREATE TABLE titan_core.quarry_supply_relationship (
    quarry_supply_relationship_id text PRIMARY KEY,
    quarry_entity_id text NOT NULL REFERENCES titan_core.entity_registry(entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    plant_entity_id text NOT NULL REFERENCES titan_core.entity_registry(entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    material_flow_id text NULL REFERENCES titan_core.material_flow(material_flow_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    valid_from date NOT NULL,
    valid_to date NULL,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    relationship_notes text NULL,
    CONSTRAINT ck_quarry_supply_id CHECK (quarry_supply_relationship_id ~ '^QSUP-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_quarry_supply_dates CHECK (valid_to IS NULL OR valid_to>=valid_from),
    CONSTRAINT uq_quarry_supply UNIQUE(quarry_entity_id,plant_entity_id,valid_from)
);

CREATE TABLE titan_core.target_master (
    target_id text PRIMARY KEY,
    owner_entity_id text NOT NULL REFERENCES titan_core.entity_registry(entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    target_name text NOT NULL,
    target_topic text NOT NULL,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    CONSTRAINT ck_target_id CHECK (target_id ~ '^TGT-[A-Za-z0-9][A-Za-z0-9._-]*$')
);

CREATE TABLE titan_core.target_version (
    target_version_id text PRIMARY KEY,
    target_id text NOT NULL REFERENCES titan_core.target_master(target_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    version_label text NOT NULL,
    metric_code text NOT NULL,
    scope_definition text NOT NULL,
    boundary_entity_id text NOT NULL REFERENCES titan_core.entity_registry(entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    baseline_year integer NOT NULL CHECK (baseline_year BETWEEN 1900 AND 2200),
    target_year integer NOT NULL CHECK (target_year BETWEEN baseline_year AND 2200),
    gross_net_target_type_code text NOT NULL REFERENCES titan_ref.gross_net_target_type(gross_net_target_type_code),
    associated_gross_target_version_id text NULL REFERENCES titan_core.target_version(target_version_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    baseline_observation_id text NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    target_observation_id text NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    methodology_version_id text NULL REFERENCES titan_core.methodology_version(methodology_version_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    validation_framework text NULL,
    validation_framework_version text NULL,
    target_validation_status_code text NOT NULL REFERENCES titan_ref.target_validation_status(target_validation_status_code),
    validation_date date NULL,
    supersedes_target_version_id text NULL REFERENCES titan_core.target_version(target_version_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    version_notes text NULL,
    CONSTRAINT ck_target_version_id CHECK (target_version_id ~ '^TGTV-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_target_version_not_self CHECK (supersedes_target_version_id IS NULL OR supersedes_target_version_id<>target_version_id),
    CONSTRAINT ck_target_net_has_gross CHECK (
        gross_net_target_type_code<>'NET' OR associated_gross_target_version_id IS NOT NULL
    ),
    CONSTRAINT ck_target_gross_link_not_self CHECK (
        associated_gross_target_version_id IS NULL OR associated_gross_target_version_id<>target_version_id
    )
);

CREATE TABLE titan_core.target_recalculation (
    target_recalculation_id text PRIMARY KEY,
    target_version_id text NOT NULL REFERENCES titan_core.target_version(target_version_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    target_recalc_trigger_code text NOT NULL REFERENCES titan_ref.target_recalc_trigger(target_recalc_trigger_code),
    significance_pct numeric NULL CHECK (significance_pct IS NULL OR significance_pct>=0),
    threshold_pct numeric NULL CHECK (threshold_pct IS NULL OR threshold_pct>=0),
    target_recalc_result_code text NOT NULL REFERENCES titan_ref.target_recalc_result(target_recalc_result_code),
    recalculated_target_version_id text NULL REFERENCES titan_core.target_version(target_version_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    evaluated_date date NOT NULL,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    recalculation_notes text NULL,
    CONSTRAINT ck_target_recalc_id CHECK (target_recalculation_id ~ '^TRC-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_target_recalc_link CHECK (
        target_recalc_result_code<>'RECALCULATE' OR recalculated_target_version_id IS NOT NULL
    )
);

CREATE TABLE titan_core.target_progress (
    target_progress_id text PRIMARY KEY,
    target_version_id text NOT NULL REFERENCES titan_core.target_version(target_version_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    progress_observation_id text NOT NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    comparable_baseline_target_version_id text NOT NULL REFERENCES titan_core.target_version(target_version_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    progress_notes text NULL,
    CONSTRAINT ck_target_progress_id CHECK (target_progress_id ~ '^TPR-[A-Za-z0-9][A-Za-z0-9._-]*$')
);

CREATE TABLE titan_core.credit_reliance_plan (
    credit_reliance_plan_id text PRIMARY KEY,
    target_version_id text NOT NULL REFERENCES titan_core.target_version(target_version_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    credit_type text NOT NULL,
    planned_volume_observation_id text NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    planned_share_observation_id text NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    scheme_name text NULL,
    permanence_assumption text NULL,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    plan_notes text NULL,
    CONSTRAINT ck_credit_plan_id CHECK (credit_reliance_plan_id ~ '^CRP-[A-Za-z0-9][A-Za-z0-9._-]*$')
);

CREATE TABLE titan_core.target_capex_link (
    target_capex_link_id text PRIMARY KEY,
    target_version_id text NOT NULL REFERENCES titan_core.target_version(target_version_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    project_entity_id text NULL REFERENCES titan_core.entity_registry(entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    capex_observation_id text NOT NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    capex_class_code text NOT NULL REFERENCES titan_ref.capex_class(capex_class_code),
    attribution_basis text NOT NULL,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    link_notes text NULL,
    CONSTRAINT ck_target_capex_link_id CHECK (target_capex_link_id ~ '^TCAP-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_target_capex_basis CHECK (btrim(attribution_basis) <> '')
);

CREATE TABLE titan_core.sustainability_assurance_engagement (
    assurance_id text PRIMARY KEY,
    reporting_entity_id text NOT NULL REFERENCES titan_core.entity_registry(entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    practitioner_name text NOT NULL,
    standard_name text NOT NULL,
    standard_version text NULL,
    assurance_level_code text NOT NULL REFERENCES titan_ref.assurance_level(assurance_level_code),
    period_start date NOT NULL,
    period_end date NOT NULL,
    assurance_source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    assurance_notes text NULL,
    CONSTRAINT ck_sus_assurance_id CHECK (assurance_id ~ '^SASSUR-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_sus_assurance_period CHECK (period_end>=period_start)
);

CREATE TABLE titan_core.assurance_scope_member (
    assurance_scope_member_id text PRIMARY KEY,
    assurance_id text NOT NULL REFERENCES titan_core.sustainability_assurance_engagement(assurance_id) ON UPDATE RESTRICT ON DELETE CASCADE,
    observation_id text NULL REFERENCES titan_core.observation(observation_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    disclosure_ref text NULL,
    metric_code text NULL,
    scope_notes text NULL,
    CONSTRAINT ck_assurance_scope_member_id CHECK (assurance_scope_member_id ~ '^ASSCOPE-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_assurance_scope_subject CHECK (observation_id IS NOT NULL OR disclosure_ref IS NOT NULL OR metric_code IS NOT NULL)
);

CREATE TABLE titan_core.association_membership_history (
    association_membership_id text PRIMARY KEY,
    company_entity_id text NOT NULL REFERENCES titan_core.entity_registry(entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    association_entity_id text NOT NULL REFERENCES titan_core.entity_registry(entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    membership_status_code text NOT NULL REFERENCES titan_ref.membership_status(membership_status_code),
    valid_from date NOT NULL,
    valid_to date NULL,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    membership_notes text NULL,
    CONSTRAINT ck_assoc_membership_id CHECK (association_membership_id ~ '^MEM-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_assoc_membership_dates CHECK (valid_to IS NULL OR valid_to>=valid_from)
);

CREATE TABLE titan_core.association_position_alignment (
    association_position_alignment_id text PRIMARY KEY,
    company_entity_id text NOT NULL REFERENCES titan_core.entity_registry(entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    association_entity_id text NOT NULL REFERENCES titan_core.entity_registry(entity_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    topic_code text NOT NULL,
    assessment_date date NOT NULL,
    alignment_state_code text NOT NULL REFERENCES titan_ref.alignment_state(alignment_state_code),
    company_position_source_id text NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    association_position_source_id text NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    alignment_notes text NULL,
    CONSTRAINT ck_assoc_alignment_id CHECK (association_position_alignment_id ~ '^ALIGN-[A-Za-z0-9][A-Za-z0-9._-]*$')
);

CREATE OR REPLACE FUNCTION titan_core.sbti_v2_recalc_result(
    change_pct numeric,
    threshold_pct numeric DEFAULT 5
)
RETURNS text
LANGUAGE sql
IMMUTABLE
STRICT
AS $$
    SELECT CASE WHEN abs(change_pct)>=threshold_pct
                THEN 'RECALCULATE'
                ELSE 'EVALUATED_BELOW_THRESHOLD'
           END
$$;

COMMIT;
