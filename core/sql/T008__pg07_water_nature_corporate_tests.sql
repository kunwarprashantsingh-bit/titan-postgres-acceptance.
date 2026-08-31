-- PG-07 Water, Nature & Corporate Transition Governance acceptance tests
-- Run in disposable database after V001-V016.
\set ON_ERROR_STOP on
BEGIN;

INSERT INTO titan_core.entity_registry(entity_id,entity_type_code,canonical_name,country_geo_id) VALUES
('SRC-PG07-TEST','SOURCE','PG07 synthetic rollback source','CTY-IN'),
('CO-PG07-TEST','LEGAL_ENTITY','PG07 Synthetic Cement Company','CTY-IN'),
('SITE-PG07-TEST','LEGAL_ENTITY','PG07 Synthetic Cement Site','CTY-IN'),
('QUARRY-PG07-TEST','LEGAL_ENTITY','PG07 Synthetic Quarry','CTY-IN'),
('ASSOC-PG07-TEST','LEGAL_ENTITY','PG07 Synthetic Cement Association','CTY-IN'),
('OBS-PG07-W-OPEN','OBSERVATION','PG07 opening stored water','CTY-IN'),
('OBS-PG07-W-WD','OBSERVATION','PG07 fresh withdrawal','CTY-IN'),
('OBS-PG07-W-DEW','OBSERVATION','PG07 mine dewatering inflow','CTY-IN'),
('OBS-PG07-W-DIS','OBSERVATION','PG07 discharge','CTY-IN'),
('OBS-PG07-W-CLOSE','OBSERVATION','PG07 closing stored water','CTY-IN'),
('OBS-PG07-W-CONS','OBSERVATION','PG07 calculated water consumption','CTY-IN'),
('OBS-PG07-DIST','OBSERVATION','PG07 current disturbed quarry area','CTY-IN'),
('OBS-PG07-REST','OBSERVATION','PG07 historical restored area','CTY-IN'),
('OBS-PG07-ECO','OBSERVATION','PG07 ecosystem condition index','CTY-IN'),
('OBS-PG07-TGT-BASE','OBSERVATION','PG07 synthetic corporate target baseline','CTY-IN'),
('OBS-PG07-TGT-VAL','OBSERVATION','PG07 synthetic corporate target value','CTY-IN'),
('OBS-PG07-TGT-PROG','OBSERVATION','PG07 synthetic corporate target progress','CTY-IN'),
('OBS-PG07-CAPEX-TR','OBSERVATION','PG07 synthetic transition capex','CTY-IN'),
('OBS-PG07-CAPEX-MAINT','OBSERVATION','PG07 synthetic maintenance capex','CTY-IN'),
('OBS-PG07-S1','OBSERVATION','PG07 synthetic Scope 1 KPI','CTY-IN'),
('OBS-PG07-S2','OBSERVATION','PG07 synthetic Scope 2 KPI','CTY-IN'),
('OBS-PG07-S3','OBSERVATION','PG07 synthetic Scope 3 KPI','CTY-IN');

INSERT INTO titan_core.source_document
(source_id,publisher_name,document_title,document_type_code,evidence_grade_code,language_code,archival_status_code,authoritative_status)
VALUES ('SRC-PG07-TEST','TITAN Test Harness','PG07 synthetic rollback fixtures','TECHNICAL_REPORT','X','en','LIVE_ONLY','SYNTHETIC');

INSERT INTO titan_core.observation
(observation_id,subject_entity_id,metric_code,quantity_kind_code,value_state_code,data_class_code,numeric_value,unit_code,period_start,period_end)
VALUES
('OBS-PG07-W-OPEN','SITE-PG07-TEST','WATER_OPENING_STORAGE','ABSOLUTE','VALUE','M',20,'M3',DATE '2026-01-01',DATE '2026-12-31'),
('OBS-PG07-W-WD','SITE-PG07-TEST','WATER_WITHDRAWAL','ABSOLUTE','VALUE','M',100,'M3',DATE '2026-01-01',DATE '2026-12-31'),
('OBS-PG07-W-DEW','SITE-PG07-TEST','WATER_DEWATERING_INFLOW','ABSOLUTE','VALUE','M',50,'M3',DATE '2026-01-01',DATE '2026-12-31'),
('OBS-PG07-W-DIS','SITE-PG07-TEST','WATER_DISCHARGE','ABSOLUTE','VALUE','M',120,'M3',DATE '2026-01-01',DATE '2026-12-31'),
('OBS-PG07-W-CLOSE','SITE-PG07-TEST','WATER_CLOSING_STORAGE','ABSOLUTE','VALUE','M',10,'M3',DATE '2026-01-01',DATE '2026-12-31'),
('OBS-PG07-W-CONS','SITE-PG07-TEST','WATER_CONSUMPTION','ABSOLUTE','VALUE','D',40,'M3',DATE '2026-01-01',DATE '2026-12-31'),
('OBS-PG07-DIST','QUARRY-PG07-TEST','CURRENT_DISTURBED_AREA','ABSOLUTE','VALUE','M',80,'HA',DATE '2026-12-31',DATE '2026-12-31'),
('OBS-PG07-REST','QUARRY-PG07-TEST','HISTORICAL_RESTORED_AREA','ABSOLUTE','VALUE','M',120,'HA',DATE '2000-01-01',DATE '2026-12-31'),
('OBS-PG07-ECO','QUARRY-PG07-TEST','ECOSYSTEM_CONDITION_INDEX','INDEX','VALUE','M',0.55,'FRACTION',DATE '2026-01-01',DATE '2026-12-31'),
('OBS-PG07-TGT-BASE','CO-PG07-TEST','SCOPE1_BASELINE','ABSOLUTE','VALUE','M',1000000,'T_CO2E',DATE '2020-01-01',DATE '2020-12-31'),
('OBS-PG07-TGT-VAL','CO-PG07-TEST','SCOPE1_TARGET_REDUCTION','RATIO','VALUE','M',0.30,'FRACTION',DATE '2030-01-01',DATE '2030-12-31'),
('OBS-PG07-TGT-PROG','CO-PG07-TEST','SCOPE1_PROGRESS_REDUCTION','RATIO','VALUE','M',0.18,'FRACTION',DATE '2026-01-01',DATE '2026-12-31'),
('OBS-PG07-CAPEX-TR','CO-PG07-TEST','CAPEX','ABSOLUTE','VALUE','M',100,'INR',DATE '2026-01-01',DATE '2026-12-31'),
('OBS-PG07-CAPEX-MAINT','CO-PG07-TEST','CAPEX','ABSOLUTE','VALUE','M',40,'INR',DATE '2026-01-01',DATE '2026-12-31'),
('OBS-PG07-S1','CO-PG07-TEST','SCOPE1','ABSOLUTE','VALUE','M',100,'T_CO2E',DATE '2027-01-01',DATE '2027-12-31'),
('OBS-PG07-S2','CO-PG07-TEST','SCOPE2','ABSOLUTE','VALUE','M',20,'T_CO2E',DATE '2027-01-01',DATE '2027-12-31'),
('OBS-PG07-S3','CO-PG07-TEST','SCOPE3','ABSOLUTE','VALUE','M',300,'T_CO2E',DATE '2027-01-01',DATE '2027-12-31');

INSERT INTO titan_core.observation_model_provenance(observation_id,model_ref,model_version_ref,assumption_set_ref)
SELECT observation_id,'PG07_SYNTHETIC','v1','PG07-TEST'
FROM titan_core.observation
WHERE observation_id LIKE 'OBS-PG07-%'
  AND data_class_code='M';

INSERT INTO titan_core.observation_derivation(observation_id,formula_text,calculation_notes)
VALUES ('OBS-PG07-W-CONS','opening + withdrawal + other inflow - discharge - closing','Synthetic water balance');

INSERT INTO titan_core.observation_derivation_input(observation_id,input_observation_id,input_role) VALUES
('OBS-PG07-W-CONS','OBS-PG07-W-OPEN','OPENING_STORAGE'),
('OBS-PG07-W-CONS','OBS-PG07-W-WD','WITHDRAWAL'),
('OBS-PG07-W-CONS','OBS-PG07-W-DEW','OTHER_INFLOW'),
('OBS-PG07-W-CONS','OBS-PG07-W-DIS','DISCHARGE'),
('OBS-PG07-W-CONS','OBS-PG07-W-CLOSE','CLOSING_STORAGE');

-- Water semantics.
INSERT INTO titan_core.water_source(water_source_id,site_or_asset_entity_id,water_source_type_code,source_name,source_id)
VALUES
('WTRSRC-PG07-FRESH','SITE-PG07-TEST','GROUNDWATER_FRESH','Synthetic groundwater','SRC-PG07-TEST'),
('WTRSRC-PG07-DEW','SITE-PG07-TEST','MINE_DEWATERING','Synthetic quarry dewatering','SRC-PG07-TEST');

INSERT INTO titan_core.water_flow
(water_flow_id,site_or_asset_entity_id,water_source_id,water_flow_role_code,quantity_observation_id,receiving_body_text,period_start,period_end,source_id)
VALUES
('WTRF-PG07-WD','SITE-PG07-TEST','WTRSRC-PG07-FRESH','WITHDRAWAL','OBS-PG07-W-WD',NULL,DATE '2026-01-01',DATE '2026-12-31','SRC-PG07-TEST'),
('WTRF-PG07-DEW','SITE-PG07-TEST','WTRSRC-PG07-DEW','DEWATERING_INFLOW','OBS-PG07-W-DEW',NULL,DATE '2026-01-01',DATE '2026-12-31','SRC-PG07-TEST'),
('WTRF-PG07-DIS','SITE-PG07-TEST','WTRSRC-PG07-DEW','DISCHARGE','OBS-PG07-W-DIS','Synthetic river',DATE '2026-01-01',DATE '2026-12-31','SRC-PG07-TEST');

INSERT INTO titan_core.water_balance
(water_balance_id,site_or_asset_entity_id,period_start,period_end,opening_storage_observation_id,withdrawal_observation_id,other_inflow_observation_id,discharge_observation_id,closing_storage_observation_id,consumption_observation_id,source_id)
VALUES ('WB-PG07-2026','SITE-PG07-TEST',DATE '2026-01-01',DATE '2026-12-31',
'OBS-PG07-W-OPEN','OBS-PG07-W-WD','OBS-PG07-W-DEW','OBS-PG07-W-DIS','OBS-PG07-W-CLOSE','OBS-PG07-W-CONS','SRC-PG07-TEST');

DO $$
DECLARE c numeric;
BEGIN
    SELECT numeric_value INTO c FROM titan_core.observation WHERE observation_id='OBS-PG07-W-CONS';
    IF c<>40 THEN RAISE EXCEPTION 'PG07-T001 water consumption expected 40'; END IF;
END;
$$;

-- Invalid balance rejected.
DO $$
DECLARE caught boolean:=false;
BEGIN
    BEGIN
        INSERT INTO titan_core.water_balance
        (water_balance_id,site_or_asset_entity_id,period_start,period_end,opening_storage_observation_id,withdrawal_observation_id,other_inflow_observation_id,discharge_observation_id,closing_storage_observation_id,consumption_observation_id,source_id)
        VALUES ('WB-PG07-BAD','SITE-PG07-TEST',DATE '2026-01-01',DATE '2026-12-31',
        'OBS-PG07-W-OPEN','OBS-PG07-W-WD',NULL,'OBS-PG07-W-DIS','OBS-PG07-W-CLOSE','OBS-PG07-W-CONS','SRC-PG07-TEST');
    EXCEPTION WHEN OTHERS THEN caught:=true; END;
    IF NOT caught THEN RAISE EXCEPTION 'PG07-T002 unbalanced water balance was not rejected'; END IF;
END;
$$;

INSERT INTO titan_core.basin_context
(basin_context_id,site_or_asset_entity_id,basin_name,assessment_framework,assessment_version,assessment_date,risk_or_pressure_state,source_id,context_notes)
VALUES ('BASIN-PG07-001','SITE-PG07-TEST','Synthetic stressed basin','SBTN Freshwater','V2 PILOT',DATE '2026-08-30','HIGH_STRESS','SRC-PG07-SBTN-FW2','Framework status remains pilot.');

INSERT INTO titan_core.water_target
(water_target_id,target_boundary_entity_id,basin_context_id,allocation_method,framework_version,framework_status,source_id,target_notes)
VALUES ('WTGT-PG07-001','SITE-PG07-TEST','BASIN-PG07-001','Synthetic basin-required contraction','SBTN Freshwater V2','PILOT','SRC-PG07-SBTN-FW2','Not production validated; pilot architecture test.');

DO $$
DECLARE status text;
BEGIN
    SELECT framework_status INTO status FROM titan_core.water_target WHERE water_target_id='WTGT-PG07-001';
    IF status<>'PILOT' THEN RAISE EXCEPTION 'PG07-T003 SBTN V2 pilot status lost'; END IF;
END;
$$;

-- Nature location, impact, action and offset.
INSERT INTO titan_core.nature_site_context
(nature_context_id,site_or_quarry_entity_id,polygon_ref,assessment_framework,assessment_version,assessment_date,sensitive_area_name,sensitive_area_type,distance_km,overlap_flag,source_id)
VALUES ('NATCTX-PG07-001','QUARRY-PG07-TEST','GIS://synthetic/quarry','GRI101/TNFD','2026',DATE '2026-08-30','Synthetic Key Biodiversity Area','KBA',2.4,false,'SRC-PG07-GRI101');

INSERT INTO titan_core.ecosystem_condition_observation
(ecosystem_condition_observation_id,nature_context_id,observation_id,condition_metric,reference_area_text,source_id)
VALUES ('ECO-PG07-001','NATCTX-PG07-001','OBS-PG07-ECO','Synthetic ecosystem condition index','Quarry reference habitat','SRC-PG07-TEST');

INSERT INTO titan_core.biodiversity_impact
(biodiversity_impact_id,nature_context_id,impact_driver,affected_ecosystem_or_species,residual_impact_state,source_id)
VALUES ('BIOIMP-PG07-001','NATCTX-PG07-001','LAND_USE_CHANGE','Synthetic habitat','RESIDUAL_IMPACT','SRC-PG07-TEST');

INSERT INTO titan_core.biodiversity_action
(biodiversity_action_id,biodiversity_impact_id,biodiversity_action_type_code,action_location_ref,action_area_ha,period_start,milestone_state,outcome_observation_id,source_id)
VALUES
('BIOACT-PG07-REST','BIOIMP-PG07-001','RESTORE','ONSITE:synthetic',120,DATE '2000-01-01','AREA_RESTORED',NULL,'SRC-PG07-TEST'),
('BIOACT-PG07-OFF','BIOIMP-PG07-001','OFFSET','OFFSITE:synthetic',20,DATE '2026-01-01','INITIATED',NULL,'SRC-PG07-TEST');

INSERT INTO titan_core.offset_relationship
(offset_relationship_id,biodiversity_impact_id,biodiversity_action_id,equivalence_method,source_id)
VALUES ('OFFREL-PG07-001','BIOIMP-PG07-001','BIOACT-PG07-OFF','Synthetic no-net-loss equivalence method','SRC-PG07-TEST');

DO $$
DECLARE restore_outcome text;
DECLARE offsite_loc text;
BEGIN
    SELECT outcome_observation_id INTO restore_outcome FROM titan_core.biodiversity_action WHERE biodiversity_action_id='BIOACT-PG07-REST';
    SELECT action_location_ref INTO offsite_loc FROM titan_core.biodiversity_action WHERE biodiversity_action_id='BIOACT-PG07-OFF';
    IF restore_outcome IS NOT NULL THEN RAISE EXCEPTION 'PG07-T004 restored area must not imply ecosystem outcome'; END IF;
    IF offsite_loc NOT LIKE 'OFFSITE:%' THEN RAISE EXCEPTION 'PG07-T005 offsite offset location lost'; END IF;
END;
$$;

-- Rehabilitation percentage trap: 120 historical restored / 80 current disturbed = 150%, but incompatible periods mean no metric is published.
DO $$
DECLARE ratio numeric;
DECLARE published_ratio_count integer;
BEGIN
    ratio:=120.0/80.0;
    SELECT count(*) INTO published_ratio_count
    FROM titan_core.observation
    WHERE subject_entity_id='QUARRY-PG07-TEST'
      AND metric_code='REHABILITATION_PERCENT';
    IF abs(ratio-1.5)>0.000001 THEN RAISE EXCEPTION 'PG07-T006 synthetic trap ratio failed'; END IF;
    IF published_ratio_count<>0 THEN RAISE EXCEPTION 'PG07-T007 invalid mixed-period rehabilitation ratio was published'; END IF;
END;
$$;

-- Corporate target versioning and no plant propagation.
INSERT INTO titan_core.target_master(target_id,owner_entity_id,target_name,target_topic,source_id)
VALUES ('TGT-PG07-001','CO-PG07-TEST','Synthetic corporate Scope 1 target','CLIMATE','SRC-PG07-TEST');

INSERT INTO titan_core.target_version
(target_version_id,target_id,version_label,metric_code,scope_definition,boundary_entity_id,baseline_year,target_year,gross_net_target_type_code,baseline_observation_id,target_observation_id,methodology_version_id,validation_framework,validation_framework_version,target_validation_status_code,validation_date,source_id)
VALUES
('TGTV-PG07-V1','TGT-PG07-001','Original 2026 publication','SCOPE1_REDUCTION','Corporate Scope 1','CO-PG07-TEST',2020,2030,'GROSS','OBS-PG07-TGT-BASE','OBS-PG07-TGT-VAL',NULL,'SBTi','1.3.1','VALIDATED',DATE '2026-06-01','SRC-PG07-TEST');

INSERT INTO titan_core.target_version
(target_version_id,target_id,version_label,metric_code,scope_definition,boundary_entity_id,baseline_year,target_year,gross_net_target_type_code,baseline_observation_id,target_observation_id,methodology_version_id,validation_framework,validation_framework_version,target_validation_status_code,validation_date,supersedes_target_version_id,source_id,version_notes)
VALUES
('TGTV-PG07-V2','TGT-PG07-001','Recalculated comparable baseline','SCOPE1_REDUCTION','Corporate Scope 1','CO-PG07-TEST',2020,2030,'GROSS','OBS-PG07-TGT-BASE','OBS-PG07-TGT-VAL','METHV-SBTI-CNZ-V2','SBTi','2.0','COMPANY_ONLY',NULL,'TGTV-PG07-V1','SRC-PG07-TEST','Synthetic V2 recalculation architecture test; not asserted as validated in 2026.');

INSERT INTO titan_core.target_recalculation
(target_recalculation_id,target_version_id,target_recalc_trigger_code,significance_pct,threshold_pct,target_recalc_result_code,recalculated_target_version_id,evaluated_date,source_id)
VALUES ('TRC-PG07-001','TGTV-PG07-V1','M_AND_A',6,5,'RECALCULATE','TGTV-PG07-V2',DATE '2026-08-30','SRC-PG07-TEST');

INSERT INTO titan_core.target_progress
(target_progress_id,target_version_id,progress_observation_id,comparable_baseline_target_version_id,source_id)
VALUES ('TPR-PG07-001','TGTV-PG07-V1','OBS-PG07-TGT-PROG','TGTV-PG07-V1','SRC-PG07-TEST');

DO $$
DECLARE r6 text; DECLARE r3 text; DECLARE r5 text; DECLARE plant_targets integer;
BEGIN
    r6:=titan_core.sbti_v2_recalc_result(6,5);
    r3:=titan_core.sbti_v2_recalc_result(3,5);
    r5:=titan_core.sbti_v2_recalc_result(5,5);
    SELECT count(*) INTO plant_targets
    FROM titan_core.target_version
    WHERE boundary_entity_id='SITE-PG07-TEST';

    IF r6<>'RECALCULATE' THEN RAISE EXCEPTION 'PG07-T008 6%% recalculation failed'; END IF;
    IF r3<>'EVALUATED_BELOW_THRESHOLD' THEN RAISE EXCEPTION 'PG07-T009 3%% evaluation failed'; END IF;
    IF r5<>'RECALCULATE' THEN RAISE EXCEPTION 'PG07-T010 5%% threshold boundary failed'; END IF;
    IF plant_targets<>0 THEN RAISE EXCEPTION 'PG07-T011 corporate target propagated to site without evidence'; END IF;
END;
$$;

-- Net target/credit plan and gross separation.
INSERT INTO titan_core.target_master(target_id,owner_entity_id,target_name,target_topic,source_id)
VALUES ('TGT-PG07-NET','CO-PG07-TEST','Synthetic net target','CLIMATE','SRC-PG07-TEST');

INSERT INTO titan_core.target_version
(target_version_id,target_id,version_label,metric_code,scope_definition,boundary_entity_id,baseline_year,target_year,gross_net_target_type_code,associated_gross_target_version_id,baseline_observation_id,target_observation_id,validation_framework,validation_framework_version,target_validation_status_code,source_id)
VALUES ('TGTV-PG07-NET','TGT-PG07-NET','Synthetic net version','NET_GHG','Corporate GHG','CO-PG07-TEST',2020,2050,'NET','TGTV-PG07-V1','OBS-PG07-TGT-BASE','OBS-PG07-TGT-VAL','Company framework','2026','COMPANY_ONLY','SRC-PG07-TEST');

INSERT INTO titan_core.credit_reliance_plan
(credit_reliance_plan_id,target_version_id,credit_type,scheme_name,permanence_assumption,source_id,plan_notes)
VALUES ('CRP-PG07-001','TGTV-PG07-NET','TECHNOLOGICAL_REMOVAL','Synthetic scheme','Permanent storage required','SRC-PG07-TEST','Separate from gross target version.');

DO $$
DECLARE gross_count integer; DECLARE net_count integer; DECLARE credit_count integer;
BEGIN
    SELECT count(*) INTO gross_count FROM titan_core.target_version WHERE target_id='TGT-PG07-001' AND gross_net_target_type_code='GROSS';
    SELECT count(*) INTO net_count FROM titan_core.target_version WHERE target_id='TGT-PG07-NET' AND gross_net_target_type_code='NET';
    SELECT count(*) INTO credit_count FROM titan_core.credit_reliance_plan WHERE target_version_id='TGTV-PG07-NET';
    IF gross_count<1 OR net_count<>1 OR credit_count<>1 THEN RAISE EXCEPTION 'PG07-T012 gross/net/credit separation failed'; END IF;
END;
$$;

-- Net target without associated gross target must fail.
DO $$
DECLARE caught boolean:=false;
BEGIN
    BEGIN
        INSERT INTO titan_core.target_master(target_id,owner_entity_id,target_name,target_topic,source_id)
        VALUES ('TGT-PG07-BADNET','CO-PG07-TEST','Bad net target','CLIMATE','SRC-PG07-TEST');
        INSERT INTO titan_core.target_version
        (target_version_id,target_id,version_label,metric_code,scope_definition,boundary_entity_id,baseline_year,target_year,gross_net_target_type_code,baseline_observation_id,target_observation_id,target_validation_status_code,source_id)
        VALUES ('TGTV-PG07-BADNET','TGT-PG07-BADNET','bad','NET_GHG','Corporate GHG','CO-PG07-TEST',2020,2050,'NET','OBS-PG07-TGT-BASE','OBS-PG07-TGT-VAL','COMPANY_ONLY','SRC-PG07-TEST');
    EXCEPTION WHEN check_violation THEN caught:=true; END;
    IF NOT caught THEN RAISE EXCEPTION 'PG07-T013 net target without associated gross target was not rejected'; END IF;
END;
$$;

-- Capex attribution.
INSERT INTO titan_core.target_capex_link
(target_capex_link_id,target_version_id,capex_observation_id,capex_class_code,attribution_basis,source_id)
VALUES
('TCAP-PG07-TR','TGTV-PG07-V1','OBS-PG07-CAPEX-TR','TRANSITION','Synthetic project-specific decarbonization evidence','SRC-PG07-TEST'),
('TCAP-PG07-MAINT','TGTV-PG07-V1','OBS-PG07-CAPEX-MAINT','MAINTENANCE','Ordinary maintenance; retained but excluded from transition analysis','SRC-PG07-TEST');

DO $$
DECLARE transition_sum numeric; DECLARE all_sum numeric;
BEGIN
    SELECT sum(o.numeric_value) INTO transition_sum
    FROM titan_core.target_capex_link l JOIN titan_core.observation o ON o.observation_id=l.capex_observation_id
    WHERE l.target_version_id='TGTV-PG07-V1' AND l.capex_class_code='TRANSITION';

    SELECT sum(o.numeric_value) INTO all_sum
    FROM titan_core.target_capex_link l JOIN titan_core.observation o ON o.observation_id=l.capex_observation_id
    WHERE l.target_version_id='TGTV-PG07-V1';

    IF transition_sum<>100 OR all_sum<>140 THEN RAISE EXCEPTION 'PG07-T014 transition capex classification failed'; END IF;
END;
$$;

-- Assurance scope: Scope 1+2 covered, Scope 3 excluded.
INSERT INTO titan_core.sustainability_assurance_engagement
(assurance_id,reporting_entity_id,practitioner_name,standard_name,standard_version,assurance_level_code,period_start,period_end,assurance_source_id,assurance_notes)
VALUES ('SASSUR-PG07-001','CO-PG07-TEST','Synthetic Assurance Practitioner','ISSA 5000','2026','LIMITED',DATE '2027-01-01',DATE '2027-12-31','SRC-PG07-ISSA5000','Synthetic engagement after general effective date.');

INSERT INTO titan_core.assurance_scope_member
(assurance_scope_member_id,assurance_id,observation_id,metric_code)
VALUES
('ASSCOPE-PG07-S1','SASSUR-PG07-001','OBS-PG07-S1','SCOPE1'),
('ASSCOPE-PG07-S2','SASSUR-PG07-001','OBS-PG07-S2','SCOPE2');

DO $$
DECLARE covered integer; DECLARE scope3 integer;
BEGIN
    SELECT count(*) INTO covered FROM titan_core.assurance_scope_member WHERE assurance_id='SASSUR-PG07-001';
    SELECT count(*) INTO scope3 FROM titan_core.assurance_scope_member WHERE assurance_id='SASSUR-PG07-001' AND observation_id='OBS-PG07-S3';
    IF covered<>2 OR scope3<>0 THEN RAISE EXCEPTION 'PG07-T015 assurance scope fidelity failed'; END IF;
END;
$$;

-- Association membership/alignment chronology.
INSERT INTO titan_core.association_membership_history
(association_membership_id,company_entity_id,association_entity_id,membership_status_code,valid_from,valid_to,source_id)
VALUES
('MEM-PG07-001','CO-PG07-TEST','ASSOC-PG07-TEST','ACTIVE',DATE '2020-01-01',DATE '2026-06-30','SRC-PG07-TEST'),
('MEM-PG07-002','CO-PG07-TEST','ASSOC-PG07-TEST','WITHDRAWN',DATE '2026-07-01',NULL,'SRC-PG07-TEST');

INSERT INTO titan_core.association_position_alignment
(association_position_alignment_id,company_entity_id,association_entity_id,topic_code,assessment_date,alignment_state_code,company_position_source_id,association_position_source_id,alignment_notes)
VALUES ('ALIGN-PG07-001','CO-PG07-TEST','ASSOC-PG07-TEST','CLIMATE_POLICY',DATE '2026-08-30','CONFLICT','SRC-PG07-TEST','SRC-PG07-TEST','Synthetic post-withdrawal position conflict.');

DO $$
DECLARE current_status text;
BEGIN
    SELECT membership_status_code INTO current_status
    FROM titan_core.association_membership_history
    WHERE company_entity_id='CO-PG07-TEST' AND association_entity_id='ASSOC-PG07-TEST'
    ORDER BY valid_from DESC LIMIT 1;
    IF current_status<>'WITHDRAWN' THEN RAISE EXCEPTION 'PG07-T016 association membership chronology failed'; END IF;
END;
$$;

-- Current framework lifecycle controls.
DO $$
DECLARE sbti_status text; DECLARE fw_status text; DECLARE issa_date date;
BEGIN
    SELECT methodology_status_code INTO sbti_status
    FROM titan_core.methodology_version WHERE methodology_version_id='METHV-SBTI-CNZ-V2';
    SELECT authoritative_status INTO fw_status
    FROM titan_core.source_document WHERE source_id='SRC-PG07-SBTN-FW2';
    SELECT publication_date INTO issa_date
    FROM titan_core.source_document WHERE source_id='SRC-PG07-ISSA5000';

    IF sbti_status<>'FUTURE_EFFECTIVE' THEN RAISE EXCEPTION 'PG07-T017 SBTi V2 operational status failed'; END IF;
    IF fw_status<>'PILOT' THEN RAISE EXCEPTION 'PG07-T018 SBTN V2 pilot status failed'; END IF;
    IF issa_date IS NULL THEN RAISE EXCEPTION 'PG07-T019 ISSA source identity failed'; END IF;
END;
$$;

SET CONSTRAINTS ALL IMMEDIATE;
ROLLBACK;

\echo 'PG-07 water/nature/corporate governance tests passed if execution reached this line.'
