-- PG-08 Temporal, Scenario, Model & Publication Governance acceptance tests
-- Run in disposable database after V001-V018.
\set ON_ERROR_STOP on
BEGIN;

-- ---------------------------------------------------------------------------
-- Synthetic fixture source/entities/observations
-- ---------------------------------------------------------------------------
INSERT INTO titan_core.entity_registry(entity_id,entity_type_code,canonical_name,country_geo_id) VALUES
('SRC-PG08-TEST','SOURCE','PG08 synthetic rollback source','CTY-IN'),
('CO-PG08-TEST','LEGAL_ENTITY','PG08 Synthetic Company','CTY-IN'),
('PROJ-PG08-CCS','CCUS_PROJECT','PG08 Synthetic CCS Project','CTY-IN'),
('OBS-PG08-CAPEX-INR','OBSERVATION','PG08 synthetic capex INR','CTY-IN'),
('OBS-PG08-CAPEX-USD','OBSERVATION','PG08 normalized capex USD','CTY-IN'),
('OBS-PG08-WHR-MAX','OBSERVATION','PG08 WHR physical abatement maximum','CTY-IN'),
('OBS-PG08-WHR-EFF','OBSERVATION','PG08 WHR efficiency wedge','CTY-IN'),
('OBS-PG08-WHR-PWR','OBSERVATION','PG08 WHR renewable-power wedge','CTY-IN'),
('OBS-PG08-CCS-MAX','OBSERVATION','PG08 CCS physical abatement maximum','CTY-IN'),
('OBS-PG08-CCS-WEDGE','OBSERVATION','PG08 CCS wedge','CTY-IN'),
('OBS-PG08-CCS-DUP','OBSERVATION','PG08 erroneous duplicate CCS wedge','CTY-IN'),
('OBS-PG08-SYSTEM-A','OBSERVATION','PG08 total modelled system abatement run A','CTY-IN'),
('OBS-PG08-SYSTEM-B','OBSERVATION','PG08 total modelled system abatement run B','CTY-IN'),
('OBS-PG08-LATE-OUT','OBSERVATION','PG08 late model output','CTY-IN');

INSERT INTO titan_core.source_document
(source_id,publisher_name,document_title,document_type_code,evidence_grade_code,language_code,archival_status_code,authoritative_status)
VALUES ('SRC-PG08-TEST','TITAN Test Harness','PG08 synthetic rollback fixtures','TECHNICAL_REPORT','X','en','LIVE_ONLY','SYNTHETIC');

INSERT INTO titan_core.observation
(observation_id,subject_entity_id,metric_code,quantity_kind_code,value_state_code,data_class_code,numeric_value,unit_code,period_start,period_end)
VALUES
('OBS-PG08-CAPEX-INR','CO-PG08-TEST','CAPEX','ABSOLUTE','VALUE','M',100,'INR',DATE '2025-01-01',DATE '2025-12-31'),
('OBS-PG08-CAPEX-USD','CO-PG08-TEST','CAPEX_NORMALIZED','ABSOLUTE','VALUE','D',1.2,'USD',DATE '2025-01-01',DATE '2025-12-31'),
('OBS-PG08-WHR-MAX','CO-PG08-TEST','ABATEMENT_MAX','ABSOLUTE','VALUE','M',100000,'T_CO2E',DATE '2030-01-01',DATE '2030-12-31'),
('OBS-PG08-WHR-EFF','CO-PG08-TEST','ABATEMENT_WEDGE','ABSOLUTE','VALUE','M',70000,'T_CO2E',DATE '2030-01-01',DATE '2030-12-31'),
('OBS-PG08-WHR-PWR','CO-PG08-TEST','ABATEMENT_WEDGE','ABSOLUTE','VALUE','M',30000,'T_CO2E',DATE '2030-01-01',DATE '2030-12-31'),
('OBS-PG08-CCS-MAX','PROJ-PG08-CCS','ABATEMENT_MAX','ABSOLUTE','VALUE','M',200000,'T_CO2E',DATE '2030-01-01',DATE '2030-12-31'),
('OBS-PG08-CCS-WEDGE','PROJ-PG08-CCS','ABATEMENT_WEDGE','ABSOLUTE','VALUE','M',200000,'T_CO2E',DATE '2030-01-01',DATE '2030-12-31'),
('OBS-PG08-CCS-DUP','PROJ-PG08-CCS','ABATEMENT_WEDGE','ABSOLUTE','VALUE','M',50000,'T_CO2E',DATE '2030-01-01',DATE '2030-12-31'),
('OBS-PG08-SYSTEM-A','CO-PG08-TEST','MODEL_SYSTEM_ABATEMENT','ABSOLUTE','VALUE','M',300000,'T_CO2E',DATE '2030-01-01',DATE '2030-12-31'),
('OBS-PG08-SYSTEM-B','CO-PG08-TEST','MODEL_SYSTEM_ABATEMENT','ABSOLUTE','VALUE','M',360000,'T_CO2E',DATE '2030-01-01',DATE '2030-12-31'),
('OBS-PG08-LATE-OUT','CO-PG08-TEST','MODEL_LATE_OUTPUT','ABSOLUTE','VALUE','M',1,'T_CO2E',DATE '2030-01-01',DATE '2030-12-31');

INSERT INTO titan_core.observation_model_provenance(observation_id,model_ref,model_version_ref,assumption_set_ref)
SELECT observation_id,'MOD-PG08-SYS','synthetic','PG08-TEST'
FROM titan_core.observation
WHERE observation_id LIKE 'OBS-PG08-%'
  AND data_class_code='M';

INSERT INTO titan_core.observation_derivation(observation_id,formula_text,calculation_notes)
VALUES ('OBS-PG08-CAPEX-USD','input INR capex * declared USD/INR annual-average FX rate','Synthetic financial normalization');

INSERT INTO titan_core.observation_derivation_input(observation_id,input_observation_id,input_role)
VALUES ('OBS-PG08-CAPEX-USD','OBS-PG08-CAPEX-INR','INPUT_CAPEX');

-- ---------------------------------------------------------------------------
-- 1. Reporting calendars / period mapping
-- ---------------------------------------------------------------------------
INSERT INTO titan_core.reporting_calendar
(calendar_id,calendar_name,owner_entity_id,calendar_type,fiscal_year_start_month,fiscal_year_start_day,timezone_name,source_id)
VALUES
('CAL-PG08-FY','Synthetic Apr-Mar fiscal calendar','CO-PG08-TEST','FISCAL',4,1,'Asia/Kolkata','SRC-PG08-TEST'),
('CAL-PG08-CY','Synthetic calendar year','CO-PG08-TEST','CALENDAR',1,1,'UTC','SRC-PG08-TEST');

INSERT INTO titan_core.reporting_period
(period_id,calendar_id,period_label,period_kind,period_start,period_end,source_id)
VALUES
('PERIOD-PG08-FY2526','CAL-PG08-FY','FY2025-26','ANNUAL',DATE '2025-04-01',DATE '2026-03-31','SRC-PG08-TEST'),
('PERIOD-PG08-CY2025','CAL-PG08-CY','CY2025','ANNUAL',DATE '2025-01-01',DATE '2025-12-31','SRC-PG08-TEST');

INSERT INTO titan_core.period_mapping
(period_mapping_id,source_period_id,target_period_id,period_mapping_method_code,allocation_fraction,allocation_basis,source_id,mapping_notes)
VALUES
('PMAP-PG08-REF','PERIOD-PG08-FY2526','PERIOD-PG08-CY2025','REFERENCE_ONLY',NULL,NULL,'SRC-PG08-TEST','Cross-calendar comparison only; no fabricated monthly allocation.');

DO $$
DECLARE frac numeric;
BEGIN
    SELECT allocation_fraction INTO frac FROM titan_core.period_mapping WHERE period_mapping_id='PMAP-PG08-REF';
    IF frac IS NOT NULL THEN RAISE EXCEPTION 'PG08-T001 reference-only period mapping fabricated an allocation'; END IF;
END;
$$;

DO $$
DECLARE caught boolean:=false;
BEGIN
    BEGIN
        INSERT INTO titan_core.period_mapping
        (period_mapping_id,source_period_id,target_period_id,period_mapping_method_code,source_id)
        VALUES ('PMAP-PG08-BAD','PERIOD-PG08-FY2526','PERIOD-PG08-CY2025','PRO_RATA','SRC-PG08-TEST');
    EXCEPTION WHEN check_violation THEN caught:=true; END;
    IF NOT caught THEN RAISE EXCEPTION 'PG08-T002 pro-rata period mapping without fraction/basis was not rejected'; END IF;
END;
$$;

-- ---------------------------------------------------------------------------
-- 2. Currency / price basis
-- ---------------------------------------------------------------------------
INSERT INTO titan_core.price_basis
(price_basis_id,price_basis_type_code,source_id,basis_notes)
VALUES ('PBASIS-PG08-NOM','NOMINAL','SRC-PG08-TEST','Synthetic nominal basis');

INSERT INTO titan_core.price_basis
(price_basis_id,price_basis_type_code,base_year,inflation_index_name,inflation_method,source_id)
VALUES ('PBASIS-PG08-REAL25','REAL',2025,'Synthetic CPI','Deflate to 2025 constant prices','SRC-PG08-TEST');

INSERT INTO titan_core.currency_context
(currency_context_id,from_currency_unit_code,to_currency_unit_code,fx_rate,fx_method,rate_period_start,rate_period_end,price_basis_id,source_id)
VALUES ('FXCTX-PG08-INRUSD','INR','USD',0.012,'Annual average',DATE '2025-01-01',DATE '2025-12-31','PBASIS-PG08-NOM','SRC-PG08-TEST');

INSERT INTO titan_core.financial_normalization
(financial_normalization_id,input_observation_id,output_observation_id,currency_context_id,price_basis_id,calculation_method,source_id)
VALUES ('FNORM-PG08-001','OBS-PG08-CAPEX-INR','OBS-PG08-CAPEX-USD','FXCTX-PG08-INRUSD','PBASIS-PG08-NOM','100 INR × 0.012 USD/INR','SRC-PG08-TEST');

DO $$
DECLARE x numeric;
BEGIN
    x:=titan_core.normalized_currency_value(100,0.012);
    IF abs(x-1.2)>0.0000001 THEN RAISE EXCEPTION 'PG08-T003 currency normalization failed'; END IF;
END;
$$;

DO $$
DECLARE caught boolean:=false;
BEGIN
    BEGIN
        INSERT INTO titan_core.price_basis(price_basis_id,price_basis_type_code,base_year,source_id)
        VALUES ('PBASIS-PG08-BADREAL','REAL',2025,'SRC-PG08-TEST');
    EXCEPTION WHEN check_violation THEN caught:=true; END;
    IF NOT caught THEN RAISE EXCEPTION 'PG08-T004 real price basis without index/method was not rejected'; END IF;
END;
$$;

-- ---------------------------------------------------------------------------
-- 3. Scenario / assumptions / overrides
-- ---------------------------------------------------------------------------
INSERT INTO titan_core.assumption_set(assumption_set_id,assumption_set_name,version_label,source_id)
VALUES
('ASM-PG08-V1','PG08 Base Assumptions','v1','SRC-PG08-TEST'),
('ASM-PG08-V2','PG08 Delayed Assumptions','v2','SRC-PG08-TEST');

INSERT INTO titan_core.assumption_item
(assumption_item_id,assumption_set_id,assumption_key,assumption_value_type_code,numeric_value,unit_code,source_id)
VALUES
('ASMI-PG08-COMM1','ASM-PG08-V1','commission_year','NUMERIC',2030,NULL,'SRC-PG08-TEST'),
('ASMI-PG08-PROB1','ASM-PG08-V1','project_probability','NUMERIC',0.40,'FRACTION','SRC-PG08-TEST'),
('ASMI-PG08-COMM2','ASM-PG08-V2','commission_year','NUMERIC',2032,NULL,'SRC-PG08-TEST'),
('ASMI-PG08-PROB2','ASM-PG08-V2','project_probability','NUMERIC',0.75,'FRACTION','SRC-PG08-TEST');

INSERT INTO titan_core.scenario_master(scenario_id,scenario_name,scenario_family,source_id)
VALUES ('SCN-PG08-TRANS','PG08 Transition Scenario','TRANSITION','SRC-PG08-TEST');

INSERT INTO titan_core.scenario_version
(scenario_version_id,scenario_id,version_label,scenario_status_code,default_assumption_set_id,valid_from,source_id)
VALUES ('SCNV-PG08-V1','SCN-PG08-TRANS','v1','APPROVED','ASM-PG08-V1',DATE '2026-01-01','SRC-PG08-TEST');

INSERT INTO titan_core.scenario_version
(scenario_version_id,scenario_id,version_label,scenario_status_code,default_assumption_set_id,valid_from,supersedes_scenario_version_id,source_id)
VALUES ('SCNV-PG08-V2','SCN-PG08-TRANS','v2','APPROVED','ASM-PG08-V2',DATE '2026-08-30','SCNV-PG08-V1','SRC-PG08-TEST');

INSERT INTO titan_core.project_scenario_membership
(project_scenario_membership_id,scenario_version_id,project_entity_id,membership_role,source_id)
VALUES
('SCNMEM-PG08-V1','SCNV-PG08-V1','PROJ-PG08-CCS','MODELLED_PROJECT','SRC-PG08-TEST'),
('SCNMEM-PG08-V2','SCNV-PG08-V2','PROJ-PG08-CCS','MODELLED_PROJECT','SRC-PG08-TEST');

INSERT INTO titan_core.assumption_override_set
(override_set_id,base_assumption_set_id,version_label,created_by,source_id,override_notes)
VALUES ('OVRSET-PG08-001','ASM-PG08-V1','analyst-delay','analyst@test','SRC-PG08-TEST','Synthetic override only');

INSERT INTO titan_core.assumption_override_item
(override_item_id,override_set_id,assumption_item_id,original_value_text,override_value_text,override_reason,source_id)
VALUES ('OVRITEM-PG08-001','OVRSET-PG08-001','ASMI-PG08-COMM1','2030','2031','Synthetic manual delay assumption','SRC-PG08-TEST');

DO $$
DECLARE projects integer; DECLARE caught boolean:=false;
BEGIN
    SELECT count(DISTINCT project_entity_id) INTO projects
    FROM titan_core.project_scenario_membership WHERE project_entity_id='PROJ-PG08-CCS';
    IF projects<>1 THEN RAISE EXCEPTION 'PG08-T005 one project was duplicated by scenario'; END IF;

    BEGIN
        UPDATE titan_core.assumption_override_item SET override_value_text='2034'
        WHERE override_item_id='OVRITEM-PG08-001';
    EXCEPTION WHEN OTHERS THEN caught:=true; END;
    IF NOT caught THEN RAISE EXCEPTION 'PG08-T006 override set/item mutation was not rejected'; END IF;
END;
$$;

-- ---------------------------------------------------------------------------
-- 4. Dataset snapshots
-- ---------------------------------------------------------------------------
INSERT INTO titan_core.dataset_snapshot
(dataset_snapshot_id,snapshot_label,cutoff_date,schema_release_ref,snapshot_status_code,created_by,content_hash,source_id)
VALUES ('DSNAP-PG08-A','PG08 Snapshot A',DATE '2026-08-28','ARCH-v1.0','DRAFT','analyst@test',repeat('a',64),'SRC-PG08-TEST');

INSERT INTO titan_core.dataset_snapshot_member
(dataset_snapshot_member_id,dataset_snapshot_id,object_type,object_id,record_version_ref,record_hash)
VALUES
('DSMEM-PG08-A1','DSNAP-PG08-A','OBSERVATION','OBS-PG08-WHR-MAX','v1',repeat('1',64)),
('DSMEM-PG08-A2','DSNAP-PG08-A','OBSERVATION','OBS-PG08-CCS-MAX','v1',repeat('2',64)),
('DSMEM-PG08-A3','DSNAP-PG08-A','PROJECT_PROBABILITY','PROJ-PG08-CCS','2026-01-01',repeat('3',64));

UPDATE titan_core.dataset_snapshot SET snapshot_status_code='SEALED'
WHERE dataset_snapshot_id='DSNAP-PG08-A';

DO $$
DECLARE caught boolean:=false;
BEGIN
    BEGIN
        INSERT INTO titan_core.dataset_snapshot_member
        (dataset_snapshot_member_id,dataset_snapshot_id,object_type,object_id,record_version_ref,record_hash)
        VALUES ('DSMEM-PG08-LATE','DSNAP-PG08-A','OBSERVATION','OBS-PG08-LATE-OUT','v1',repeat('4',64));
    EXCEPTION WHEN OTHERS THEN caught:=true; END;
    IF NOT caught THEN RAISE EXCEPTION 'PG08-T007 sealed dataset snapshot accepted late member'; END IF;
END;
$$;

INSERT INTO titan_core.dataset_snapshot
(dataset_snapshot_id,snapshot_label,cutoff_date,schema_release_ref,snapshot_status_code,created_by,content_hash,source_id)
VALUES ('DSNAP-PG08-B','PG08 Snapshot B',DATE '2026-08-30','ARCH-v1.0','DRAFT','analyst@test',repeat('b',64),'SRC-PG08-TEST');

INSERT INTO titan_core.dataset_snapshot_member
(dataset_snapshot_member_id,dataset_snapshot_id,object_type,object_id,record_version_ref,record_hash)
VALUES
('DSMEM-PG08-B1','DSNAP-PG08-B','OBSERVATION','OBS-PG08-WHR-MAX','v1',repeat('1',64)),
('DSMEM-PG08-B2','DSNAP-PG08-B','OBSERVATION','OBS-PG08-CCS-MAX','v1',repeat('2',64)),
('DSMEM-PG08-B3','DSNAP-PG08-B','PROJECT_PROBABILITY','PROJ-PG08-CCS','2026-08-30',repeat('5',64));

UPDATE titan_core.dataset_snapshot SET snapshot_status_code='SEALED'
WHERE dataset_snapshot_id='DSNAP-PG08-B';

-- ---------------------------------------------------------------------------
-- 5. Models / runs / outputs
-- ---------------------------------------------------------------------------
INSERT INTO titan_core.model_definition(model_id,model_name,model_purpose,owner_team,source_id)
VALUES ('MOD-PG08-SYS','PG08 System Abatement Model','Synthetic reproducibility and abatement-allocation test','TITAN','SRC-PG08-TEST');

INSERT INTO titan_core.model_version
(model_version_id,model_id,version_label,method_specification,code_hash,runtime_environment_ref,valid_from,source_id)
VALUES
('MODV-PG08-V1','MOD-PG08-SYS','v1','Sum controlled abatement allocations',repeat('6',64),'python-env-a',DATE '2026-01-01','SRC-PG08-TEST');

INSERT INTO titan_core.model_version
(model_version_id,model_id,version_label,method_specification,code_hash,runtime_environment_ref,valid_from,supersedes_model_version_id,source_id)
VALUES
('MODV-PG08-V2','MOD-PG08-SYS','v2','Revised probability-weighted scenario method',repeat('7',64),'python-env-b',DATE '2026-08-30','MODV-PG08-V1','SRC-PG08-TEST');

INSERT INTO titan_core.model_run
(model_run_id,model_version_id,dataset_snapshot_id,scenario_version_id,assumption_set_id,cutoff_date,model_run_status_code,run_by,input_fingerprint,source_id)
VALUES ('RUN-PG08-A','MODV-PG08-V1','DSNAP-PG08-A','SCNV-PG08-V1','ASM-PG08-V1',DATE '2026-08-28','DRAFT','analyst@test',repeat('8',64),'SRC-PG08-TEST');

INSERT INTO titan_core.model_run
(model_run_id,model_version_id,dataset_snapshot_id,scenario_version_id,assumption_set_id,override_set_id,cutoff_date,model_run_status_code,run_by,input_fingerprint,source_id)
VALUES ('RUN-PG08-OVR','MODV-PG08-V1','DSNAP-PG08-A','SCNV-PG08-V1','ASM-PG08-V1','OVRSET-PG08-001',DATE '2026-08-28','DRAFT','analyst@test',repeat('9',64),'SRC-PG08-TEST');

DO $$
DECLARE caught boolean:=false;
BEGIN
    BEGIN
        INSERT INTO titan_core.model_run
        (model_run_id,model_version_id,dataset_snapshot_id,scenario_version_id,assumption_set_id,override_set_id,cutoff_date,model_run_status_code,run_by,input_fingerprint,source_id)
        VALUES ('RUN-PG08-BADOVR','MODV-PG08-V1','DSNAP-PG08-A','SCNV-PG08-V1','ASM-PG08-V2','OVRSET-PG08-001',DATE '2026-08-28','DRAFT','analyst@test',repeat('0',64),'SRC-PG08-TEST');
    EXCEPTION WHEN OTHERS THEN caught:=true; END;
    IF NOT caught THEN RAISE EXCEPTION 'PG08-T008 mismatched override/base assumption set was not rejected'; END IF;
END;
$$;

-- Abatement actions and allocations while run is DRAFT.
INSERT INTO titan_core.abatement_action
(abatement_action_id,action_name,physical_boundary_entity_id,max_claimable_observation_id,source_id)
VALUES
('ABT-PG08-WHR','WHR + grid displacement','CO-PG08-TEST','OBS-PG08-WHR-MAX','SRC-PG08-TEST'),
('ABT-PG08-CCS','Synthetic CCS','PROJ-PG08-CCS','OBS-PG08-CCS-MAX','SRC-PG08-TEST');

INSERT INTO titan_core.abatement_allocation
(abatement_allocation_id,model_run_id,abatement_action_id,wedge_code,allocated_observation_id,mutual_exclusion_group,source_id)
VALUES
('ABTA-PG08-WHR-EFF','RUN-PG08-A','ABT-PG08-WHR','EFFICIENCY','OBS-PG08-WHR-EFF','MEG-WHR','SRC-PG08-TEST'),
('ABTA-PG08-WHR-PWR','RUN-PG08-A','ABT-PG08-WHR','POWER','OBS-PG08-WHR-PWR','MEG-WHR','SRC-PG08-TEST'),
('ABTA-PG08-CCS','RUN-PG08-A','ABT-PG08-CCS','CCUS','OBS-PG08-CCS-WEDGE','MEG-CCS','SRC-PG08-TEST');

SET CONSTRAINTS ct_abatement_allocation IMMEDIATE;
SET CONSTRAINTS ct_abatement_allocation DEFERRED;

DO $$
DECLARE caught boolean:=false;
BEGIN
    BEGIN
        INSERT INTO titan_core.abatement_allocation
        (abatement_allocation_id,model_run_id,abatement_action_id,wedge_code,allocated_observation_id,mutual_exclusion_group,source_id)
        VALUES ('ABTA-PG08-CCS-DUP','RUN-PG08-A','ABT-PG08-CCS','POWER_DUP','OBS-PG08-CCS-DUP','MEG-CCS','SRC-PG08-TEST');
        SET CONSTRAINTS ct_abatement_allocation IMMEDIATE;
    EXCEPTION WHEN OTHERS THEN caught:=true; END;
    SET CONSTRAINTS ct_abatement_allocation DEFERRED;
    IF NOT caught THEN RAISE EXCEPTION 'PG08-T009 duplicate abatement exceeding physical maximum was not rejected'; END IF;
END;
$$;

INSERT INTO titan_core.model_output(model_output_id,model_run_id,output_key,observation_id,source_id)
VALUES ('OUT-PG08-A','RUN-PG08-A','TOTAL_SYSTEM_ABATEMENT','OBS-PG08-SYSTEM-A','SRC-PG08-TEST');

UPDATE titan_core.model_run
SET model_run_status_code='COMPLETED',output_fingerprint=repeat('c',64)
WHERE model_run_id='RUN-PG08-A';

UPDATE titan_core.model_run
SET model_run_status_code='COMPLETED',output_fingerprint=repeat('d',64)
WHERE model_run_id='RUN-PG08-OVR';

DO $$
DECLARE total_alloc numeric; DECLARE caught_output boolean:=false; DECLARE caught_run boolean:=false;
BEGIN
    SELECT sum(o.numeric_value) INTO total_alloc
    FROM titan_core.abatement_allocation a
    JOIN titan_core.observation o ON o.observation_id=a.allocated_observation_id
    WHERE a.model_run_id='RUN-PG08-A';

    IF total_alloc<>300000 THEN RAISE EXCEPTION 'PG08-T010 legitimate allocated system abatement expected 300000'; END IF;

    BEGIN
        INSERT INTO titan_core.model_output(model_output_id,model_run_id,output_key,observation_id,source_id)
        VALUES ('OUT-PG08-LATE','RUN-PG08-A','LATE_OUTPUT','OBS-PG08-LATE-OUT','SRC-PG08-TEST');
    EXCEPTION WHEN OTHERS THEN caught_output:=true; END;
    IF NOT caught_output THEN RAISE EXCEPTION 'PG08-T011 finalized model run accepted late output'; END IF;

    BEGIN
        UPDATE titan_core.model_run SET cutoff_date=DATE '2026-08-30' WHERE model_run_id='RUN-PG08-A';
    EXCEPTION WHEN OTHERS THEN caught_run:=true; END;
    IF NOT caught_run THEN RAISE EXCEPTION 'PG08-T012 finalized model run core mutation was not rejected'; END IF;
END;
$$;

-- New snapshot/model version/run can change current forecast without rewriting old run.
INSERT INTO titan_core.model_run
(model_run_id,model_version_id,dataset_snapshot_id,scenario_version_id,assumption_set_id,cutoff_date,model_run_status_code,run_by,input_fingerprint,source_id)
VALUES ('RUN-PG08-B','MODV-PG08-V2','DSNAP-PG08-B','SCNV-PG08-V2','ASM-PG08-V2',DATE '2026-08-30','DRAFT','analyst@test',repeat('e',64),'SRC-PG08-TEST');

INSERT INTO titan_core.model_output(model_output_id,model_run_id,output_key,observation_id,source_id)
VALUES ('OUT-PG08-B','RUN-PG08-B','TOTAL_SYSTEM_ABATEMENT','OBS-PG08-SYSTEM-B','SRC-PG08-TEST');

UPDATE titan_core.model_run
SET model_run_status_code='COMPLETED',output_fingerprint=repeat('f',64)
WHERE model_run_id='RUN-PG08-B';

DO $$
DECLARE a numeric; DECLARE b numeric;
BEGIN
    SELECT o.numeric_value INTO a
    FROM titan_core.model_output mo JOIN titan_core.observation o ON o.observation_id=mo.observation_id
    WHERE mo.model_run_id='RUN-PG08-A';
    SELECT o.numeric_value INTO b
    FROM titan_core.model_output mo JOIN titan_core.observation o ON o.observation_id=mo.observation_id
    WHERE mo.model_run_id='RUN-PG08-B';

    IF a<>300000 OR b<>360000 THEN RAISE EXCEPTION 'PG08-T013 prior/current model outputs did not remain distinct'; END IF;
END;
$$;

-- ---------------------------------------------------------------------------
-- 6. Project probability history
-- ---------------------------------------------------------------------------
INSERT INTO titan_core.project_probability_history
(project_probability_id,project_entity_id,scenario_version_id,as_of_date,probability,basis_text,source_id)
VALUES
('PPROB-PG08-OLD','PROJ-PG08-CCS','SCNV-PG08-V1',DATE '2026-01-01',0.40,'Pre-FID synthetic estimate','SRC-PG08-TEST'),
('PPROB-PG08-NEW','PROJ-PG08-CCS','SCNV-PG08-V2',DATE '2026-08-30',0.75,'Post-FID synthetic estimate','SRC-PG08-TEST');

DO $$
DECLARE n integer; DECLARE mn numeric; DECLARE mx numeric;
BEGIN
    SELECT count(*),min(probability),max(probability) INTO n,mn,mx
    FROM titan_core.project_probability_history WHERE project_entity_id='PROJ-PG08-CCS';
    IF n<>2 OR mn<>0.40 OR mx<>0.75 THEN RAISE EXCEPTION 'PG08-T014 project probability history did not preserve old/new states'; END IF;
END;
$$;

-- ---------------------------------------------------------------------------
-- 7. Publication snapshots
-- ---------------------------------------------------------------------------
INSERT INTO titan_core.publication_snapshot
(publication_snapshot_id,publication_title,publication_version,publication_status_code,dataset_snapshot_id,cutoff_date,template_version,code_commit_ref,environment_ref,publication_input_fingerprint,output_hash,source_id)
VALUES
('PUBSNAP-PG08-A','PG08 Synthetic Publication','1.0','DRAFT','DSNAP-PG08-A',DATE '2026-08-28','TPL-v1','commit-a','env-a',repeat('a',64),repeat('b',64),'SRC-PG08-TEST');

INSERT INTO titan_core.publication_model_run(publication_snapshot_id,model_run_id,role_code)
VALUES ('PUBSNAP-PG08-A','RUN-PG08-A','PRIMARY');

INSERT INTO titan_core.publication_artifact
(publication_artifact_id,publication_snapshot_id,artifact_name,artifact_type,artifact_hash,storage_ref)
VALUES ('PUBART-PG08-A','PUBSNAP-PG08-A','report-v1.pdf','PDF',repeat('c',64),'object://pg08/report-v1.pdf');

UPDATE titan_core.publication_snapshot SET publication_status_code='PUBLISHED'
WHERE publication_snapshot_id='PUBSNAP-PG08-A';

DO $$
DECLARE caught_art boolean:=false; DECLARE caught_pub boolean:=false;
BEGIN
    BEGIN
        INSERT INTO titan_core.publication_artifact
        (publication_artifact_id,publication_snapshot_id,artifact_name,artifact_type,artifact_hash,storage_ref)
        VALUES ('PUBART-PG08-LATE','PUBSNAP-PG08-A','late.csv','CSV',repeat('d',64),'object://pg08/late.csv');
    EXCEPTION WHEN OTHERS THEN caught_art:=true; END;
    IF NOT caught_art THEN RAISE EXCEPTION 'PG08-T015 published snapshot accepted late artifact'; END IF;

    BEGIN
        UPDATE titan_core.publication_snapshot SET output_hash=repeat('e',64)
        WHERE publication_snapshot_id='PUBSNAP-PG08-A';
    EXCEPTION WHEN OTHERS THEN caught_pub:=true; END;
    IF NOT caught_pub THEN RAISE EXCEPTION 'PG08-T016 published snapshot output hash was mutable'; END IF;
END;
$$;

INSERT INTO titan_core.publication_snapshot
(publication_snapshot_id,publication_title,publication_version,publication_status_code,dataset_snapshot_id,cutoff_date,template_version,code_commit_ref,environment_ref,publication_input_fingerprint,output_hash,supersedes_publication_snapshot_id,source_id)
VALUES
('PUBSNAP-PG08-B','PG08 Synthetic Publication','1.1','DRAFT','DSNAP-PG08-B',DATE '2026-08-30','TPL-v1','commit-b','env-b',repeat('f',64),repeat('1',64),'PUBSNAP-PG08-A','SRC-PG08-TEST');

INSERT INTO titan_core.publication_model_run(publication_snapshot_id,model_run_id,role_code)
VALUES ('PUBSNAP-PG08-B','RUN-PG08-B','PRIMARY');

INSERT INTO titan_core.publication_artifact
(publication_artifact_id,publication_snapshot_id,artifact_name,artifact_type,artifact_hash,storage_ref)
VALUES ('PUBART-PG08-B','PUBSNAP-PG08-B','report-v1.1.pdf','PDF',repeat('2',64),'object://pg08/report-v1.1.pdf');

UPDATE titan_core.publication_snapshot SET publication_status_code='PUBLISHED'
WHERE publication_snapshot_id='PUBSNAP-PG08-B';

UPDATE titan_core.publication_snapshot SET publication_status_code='SUPERSEDED'
WHERE publication_snapshot_id='PUBSNAP-PG08-A';

DO $$
DECLARE hash_a text; DECLARE hash_b text; DECLARE run_a numeric; DECLARE run_b numeric;
BEGIN
    SELECT output_hash INTO hash_a FROM titan_core.publication_snapshot WHERE publication_snapshot_id='PUBSNAP-PG08-A';
    SELECT output_hash INTO hash_b FROM titan_core.publication_snapshot WHERE publication_snapshot_id='PUBSNAP-PG08-B';
    SELECT o.numeric_value INTO run_a
    FROM titan_core.publication_model_run p
    JOIN titan_core.model_output mo ON mo.model_run_id=p.model_run_id
    JOIN titan_core.observation o ON o.observation_id=mo.observation_id
    WHERE p.publication_snapshot_id='PUBSNAP-PG08-A' AND mo.output_key='TOTAL_SYSTEM_ABATEMENT';
    SELECT o.numeric_value INTO run_b
    FROM titan_core.publication_model_run p
    JOIN titan_core.model_output mo ON mo.model_run_id=p.model_run_id
    JOIN titan_core.observation o ON o.observation_id=mo.observation_id
    WHERE p.publication_snapshot_id='PUBSNAP-PG08-B' AND mo.output_key='TOTAL_SYSTEM_ABATEMENT';

    IF hash_a<>repeat('b',64) OR hash_b<>repeat('1',64) THEN RAISE EXCEPTION 'PG08-T017 publication hashes not preserved'; END IF;
    IF run_a<>300000 OR run_b<>360000 THEN RAISE EXCEPTION 'PG08-T018 old/new publications did not preserve their own model runs'; END IF;
END;
$$;

-- ---------------------------------------------------------------------------
-- 8. Runtime reference policy
-- ---------------------------------------------------------------------------
DO $$
DECLARE current_minor integer; DECLARE release_date date;
BEGIN
    SELECT count(*) INTO current_minor FROM titan_core.source_document
    WHERE source_id IN ('SRC-PG08-PG-VERSION','SRC-PG08-PG-186','SRC-PG08-PG-CONSTRAINTS','SRC-PG08-PG-TXN');

    SELECT publication_date INTO release_date
    FROM titan_core.source_document WHERE source_id='SRC-PG08-PG-186';

    IF current_minor<>4 OR release_date<>DATE '2026-08-13' THEN
        RAISE EXCEPTION 'PG08-T019 current PostgreSQL runtime references missing/stale';
    END IF;
END;
$$;

SET CONSTRAINTS ALL IMMEDIATE;
ROLLBACK;

\echo 'PG-08 temporal/model/publication governance tests passed if execution reached this line.'
