-- PG-05 Policy & Compliance acceptance tests
-- Run in a disposable database after V001-V011.
\set ON_ERROR_STOP on

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. Permanent India seed integrity
-- ---------------------------------------------------------------------------
DO $$
DECLARE n_entities integer;
DECLARE n_baselines integer;
DECLARE n_obligations integer;
DECLARE n_no_target integer;
DECLARE n_amended_bound integer;
BEGIN
    SELECT count(*) INTO n_entities
    FROM titan_core.regulated_entity
    WHERE scheme_id='SCHEME-IN-CCTS'
      AND external_registration_id IN ('CMTOE085RJ','CMTOE087GJ','CMTOE019MP','CGUOE005UP','CMTOE001KA');

    SELECT count(*) INTO n_baselines
    FROM titan_core.compliance_baseline
    WHERE policy_version_id='POLV-IN-CCTS-GEI-2025';

    SELECT count(*) INTO n_obligations
    FROM titan_core.compliance_obligation
    WHERE obligation_id LIKE 'OBL-IN-%';

    SELECT count(*) INTO n_no_target
    FROM titan_core.compliance_obligation
    WHERE obligation_id='OBL-IN-KUN-2526'
      AND target_value_state_code='NOT_YET_DUE'
      AND target_value IS NULL;

    SELECT count(*) INTO n_amended_bound
    FROM titan_core.compliance_obligation
    WHERE policy_version_id='POLV-IN-CCTS-GEI-AM1';

    IF n_entities<>5 THEN RAISE EXCEPTION 'PG05-T001 expected 5 India pilot regulated entities, got %',n_entities; END IF;
    IF n_baselines<>5 THEN RAISE EXCEPTION 'PG05-T002 expected 5 India baselines, got %',n_baselines; END IF;
    IF n_obligations<>10 THEN RAISE EXCEPTION 'PG05-T003 expected 10 India obligations, got %',n_obligations; END IF;
    IF n_no_target<>1 THEN RAISE EXCEPTION 'PG05-T004 Kundanganj FY25-26 must remain NOT_YET_DUE with no zero target'; END IF;
    IF n_amended_bound<>0 THEN RAISE EXCEPTION 'PG05-T005 amendment must not silently rebind cement pilot obligations'; END IF;
END;
$$;

-- Exact CCTS target values from the promulgated principal schedule.
DO $$
DECLARE bad integer;
BEGIN
    SELECT count(*) INTO bad
    FROM (
        VALUES
        ('OBL-IN-KOT-2526',0.8032::numeric),
        ('OBL-IN-KOT-2627',0.7891::numeric),
        ('OBL-IN-JAF-2526',0.7935::numeric),
        ('OBL-IN-JAF-2627',0.7783::numeric),
        ('OBL-IN-MAI-2526',0.5885::numeric),
        ('OBL-IN-MAI-2627',0.5788::numeric),
        ('OBL-IN-KUN-2627',0.0125::numeric),
        ('OBL-IN-MUD-2526',0.4440::numeric),
        ('OBL-IN-MUD-2627',0.4402::numeric)
    ) AS expected(obligation_id,target_value)
    LEFT JOIN titan_core.compliance_obligation o USING(obligation_id)
    WHERE o.target_value IS DISTINCT FROM expected.target_value
       OR o.denominator_id IS DISTINCT FROM 'DEN-CCTS-EQPROD';

    IF bad<>0 THEN RAISE EXCEPTION 'PG05-T006 one or more India target values/denominators do not match verified schedule'; END IF;
END;
$$;

-- Regulatory spelling can differ without changing TITAN plant identity.
DO $$
DECLARE reg_name text;
DECLARE plant_id text;
BEGIN
    SELECT n.official_name,m.titan_entity_id
      INTO reg_name,plant_id
      FROM titan_core.regulated_entity_name_history n
      JOIN titan_core.regulatory_asset_mapping m USING(regulated_entity_id)
     WHERE n.regulated_entity_id='REG-IN-CCTS-CMTOE087GJ'
       AND m.regulatory_mapping_role_code='PRIMARY_SITE';

    IF reg_name<>'Naramada Cement Jafrabad Works' OR plant_id<>'PL-IN-GJ-000003' THEN
        RAISE EXCEPTION 'PG05-T007 regulatory alias / TITAN identity mapping failed';
    END IF;
END;
$$;

-- ---------------------------------------------------------------------------
-- 2. India CCTS formula replay
-- ---------------------------------------------------------------------------
DO $$
DECLARE issued numeric;
DECLARE required numeric;
BEGIN
    SELECT issued_quantity,required_quantity INTO issued,required
    FROM titan_core.ccts_certificate_position(0.8032,0.7900,3666138);
    IF abs(issued-48393.0216)>0.000001 OR required<>0 THEN
        RAISE EXCEPTION 'PG05-T008 Kotputli issuance replay failed: issued %, required %',issued,required;
    END IF;

    SELECT issued_quantity,required_quantity INTO issued,required
    FROM titan_core.ccts_certificate_position(0.7935,0.8100,1400465);
    IF issued<>0 OR abs(required-23107.6725)>0.000001 THEN
        RAISE EXCEPTION 'PG05-T009 Jafrabad shortfall replay failed: issued %, required %',issued,required;
    END IF;

    SELECT issued_quantity,required_quantity INTO issued,required
    FROM titan_core.ccts_certificate_position(0.5885,0.5885,5390695);
    IF issued<>0 OR required<>0 THEN
        RAISE EXCEPTION 'PG05-T010 exact-target replay failed';
    END IF;

    SELECT issued_quantity,required_quantity INTO issued,required
    FROM titan_core.ccts_certificate_position(0.4402,0.4450,3532948);
    IF issued<>0 OR abs(required-16958.1504)>0.000001 THEN
        RAISE EXCEPTION 'PG05-T011 Muddapur shortfall replay failed: %',required;
    END IF;
END;
$$;

-- ---------------------------------------------------------------------------
-- 3. Cross-layer verification record: OBS -> compliance unit -> verification
-- ---------------------------------------------------------------------------
INSERT INTO titan_core.entity_registry(entity_id,entity_type_code,canonical_name,country_geo_id) VALUES
('SRC-PG05-TEST','SOURCE','PG05 Synthetic Test Source','CTY-IN'),
('OBS-PG05-KOT-OUT','OBSERVATION','PG05 synthetic Kotputli equivalent output','CTY-IN'),
('OBS-PG05-KOT-GEI','OBSERVATION','PG05 synthetic Kotputli achieved GEI','CTY-IN');

INSERT INTO titan_core.source_document
(source_id,publisher_name,document_title,document_type_code,evidence_grade_code,language_code,archival_status_code,authoritative_status)
VALUES ('SRC-PG05-TEST','TITAN Test Harness','PG05 synthetic rollback fixture','TECHNICAL_REPORT','X','en','LIVE_ONLY','SYNTHETIC');

INSERT INTO titan_core.observation
(observation_id,subject_entity_id,metric_code,quantity_kind_code,value_state_code,data_class_code,numeric_value,unit_code,denominator_id,period_start,period_end,observation_notes)
VALUES
('OBS-PG05-KOT-OUT','PL-IN-RJ-000002','CCTS_EQUIVALENT_OUTPUT','ABSOLUTE','VALUE','M',3666138,'TONNE',NULL,DATE '2025-04-01',DATE '2026-03-31','Synthetic test only'),
('OBS-PG05-KOT-GEI','PL-IN-RJ-000002','CCTS_ACHIEVED_GEI','INTENSITY','VALUE','M',0.7900,'T_CO2E','DEN-CCTS-EQPROD',DATE '2025-04-01',DATE '2026-03-31','Synthetic test only');

INSERT INTO titan_core.observation_model_provenance
(observation_id,model_ref,model_version_ref,assumption_set_ref,uncertainty_text)
VALUES
('OBS-PG05-KOT-OUT','PG05_SYNTHETIC','v1','PG05-TEST','Synthetic input; not plant performance'),
('OBS-PG05-KOT-GEI','PG05_SYNTHETIC','v1','PG05-TEST','Synthetic input; not plant performance');

INSERT INTO titan_core.verification_record
(verification_id,compliance_unit_id,period_start,period_end,output_observation_id,intensity_observation_id,verifier_name_text,verification_status_code,source_id,verification_notes)
VALUES
('VER-PG05-KOT-TST','CU-IN-CCTS-CMTOE085RJ',DATE '2025-04-01',DATE '2026-03-31',
 'OBS-PG05-KOT-OUT','OBS-PG05-KOT-GEI','PG05 synthetic verifier','VERIFIED','SRC-PG05-TEST','Rollback fixture only');

-- Wrong-plant observation cannot be attached to Kotputli verification.
INSERT INTO titan_core.entity_registry(entity_id,entity_type_code,canonical_name,country_geo_id)
VALUES ('OBS-PG05-WRONG-SUBJ','OBSERVATION','PG05 wrong-subject output','CTY-IN');

INSERT INTO titan_core.observation
(observation_id,subject_entity_id,metric_code,quantity_kind_code,value_state_code,data_class_code,numeric_value,unit_code,period_start,period_end)
VALUES ('OBS-PG05-WRONG-SUBJ','PL-IN-GJ-000003','CCTS_EQUIVALENT_OUTPUT','ABSOLUTE','VALUE','M',1,'TONNE',DATE '2025-04-01',DATE '2026-03-31');

INSERT INTO titan_core.observation_model_provenance
(observation_id,model_ref,model_version_ref,assumption_set_ref)
VALUES ('OBS-PG05-WRONG-SUBJ','PG05_SYNTHETIC','v1','PG05-TEST');

DO $$
DECLARE caught boolean := false;
BEGIN
    BEGIN
        INSERT INTO titan_core.verification_record
        (verification_id,compliance_unit_id,period_start,period_end,output_observation_id,verifier_name_text,verification_status_code,source_id)
        VALUES ('VER-PG05-BAD-SUBJ','CU-IN-CCTS-CMTOE085RJ',DATE '2025-04-01',DATE '2026-03-31',
        'OBS-PG05-WRONG-SUBJ','PG05 synthetic verifier','VERIFIED','SRC-PG05-TEST');
    EXCEPTION WHEN OTHERS THEN
        caught:=true;
    END;
    IF NOT caught THEN RAISE EXCEPTION 'PG05-T012 verification wrong-subject observation was not rejected'; END IF;
END;
$$;

-- ---------------------------------------------------------------------------
-- 4. Immutable CCC ledger, banking, transfer, surrender and settlement
-- ---------------------------------------------------------------------------
INSERT INTO titan_core.instrument_lot
(instrument_lot_id,instrument_id,vintage_label,policy_version_id,valid_from,source_id,lot_notes)
VALUES ('LOT-IN-CCC-2526','INST-IN-CCC','FY2025-26','POLV-IN-CCTS-GEI-2025',DATE '2025-04-01','SRC-PG05-IN-GEI-2025','Synthetic quantity ledger test on real instrument definition.');

INSERT INTO titan_core.compliance_account
(account_id,scheme_id,regulated_entity_id,external_account_id,valid_from,account_notes)
VALUES
('ACC-IN-KOT-TST','SCHEME-IN-CCTS','REG-IN-CCTS-CMTOE085RJ','TEST-KOT',DATE '2025-04-01','Synthetic account fixture'),
('ACC-IN-JAF-TST','SCHEME-IN-CCTS','REG-IN-CCTS-CMTOE087GJ','TEST-JAF',DATE '2025-04-01','Synthetic account fixture');

INSERT INTO titan_core.carbon_transaction
(carbon_transaction_id,carbon_transaction_type_code,instrument_lot_id,quantity,transaction_date,to_account_id,source_id,transaction_notes)
VALUES ('CTX-PG05-ISSUE','ISSUE','LOT-IN-CCC-2526',50000,DATE '2026-04-15','ACC-IN-KOT-TST','SRC-PG05-TEST','Synthetic issuance');

INSERT INTO titan_core.carbon_transaction
(carbon_transaction_id,carbon_transaction_type_code,instrument_lot_id,quantity,transaction_date,from_account_id,to_account_id,source_id,transaction_notes)
VALUES ('CTX-PG05-BANK','BANK','LOT-IN-CCC-2526',50000,DATE '2026-04-16','ACC-IN-KOT-TST','ACC-IN-KOT-TST','SRC-PG05-TEST','Banking is state transition; no new units');

INSERT INTO titan_core.carbon_transaction
(carbon_transaction_id,carbon_transaction_type_code,instrument_lot_id,quantity,transaction_date,from_account_id,to_account_id,source_id,transaction_notes)
VALUES ('CTX-PG05-SALE1','SALE','LOT-IN-CCC-2526',20000,DATE '2026-04-20','ACC-IN-KOT-TST','ACC-IN-JAF-TST','SRC-PG05-TEST','Synthetic transfer/sale');

INSERT INTO titan_core.carbon_transaction
(carbon_transaction_id,carbon_transaction_type_code,instrument_lot_id,quantity,transaction_date,from_account_id,obligation_id,source_id,transaction_notes)
VALUES ('CTX-PG05-SURR1','SURRENDER','LOT-IN-CCC-2526',15000,DATE '2026-04-25','ACC-IN-JAF-TST','OBL-IN-JAF-2526','SRC-PG05-TEST','Partial surrender');

SET CONSTRAINTS ct_carbon_transaction_balance IMMEDIATE;
SET CONSTRAINTS ct_carbon_transaction_balance DEFERRED;

INSERT INTO titan_core.compliance_settlement
(settlement_id,obligation_id,settlement_version_no,verification_id,required_quantity,issued_or_allocated_quantity,surrendered_quantity,settlement_status_code,policy_rule_id,source_id,settlement_notes)
VALUES
('SET-PG05-JAF-V1','OBL-IN-JAF-2526',1,NULL,23107.6725,0,15000,'SHORTFALL','POLRULE-IN-CCTS-SHORT','SRC-PG05-TEST','Partial surrender; purchased/transferred balance alone does not close obligation.');

-- Attempt to surrender more than the account balance must fail.
DO $$
DECLARE caught boolean := false;
BEGIN
    BEGIN
        INSERT INTO titan_core.carbon_transaction
        (carbon_transaction_id,carbon_transaction_type_code,instrument_lot_id,quantity,transaction_date,from_account_id,obligation_id,source_id)
        VALUES ('CTX-PG05-OVER','SURRENDER','LOT-IN-CCC-2526',6000,DATE '2026-04-26','ACC-IN-JAF-TST','OBL-IN-JAF-2526','SRC-PG05-TEST');
        SET CONSTRAINTS ct_carbon_transaction_balance IMMEDIATE;
    EXCEPTION WHEN OTHERS THEN
        caught:=true;
    END;
    SET CONSTRAINTS ct_carbon_transaction_balance DEFERRED;
    IF NOT caught THEN RAISE EXCEPTION 'PG05-T013 negative instrument balance / double surrender was not rejected'; END IF;
END;
$$;

-- Purchase/transfer additional units does not itself satisfy the obligation.
INSERT INTO titan_core.carbon_transaction
(carbon_transaction_id,carbon_transaction_type_code,instrument_lot_id,quantity,transaction_date,from_account_id,to_account_id,source_id)
VALUES ('CTX-PG05-SALE2','SALE','LOT-IN-CCC-2526',5000,DATE '2026-04-27','ACC-IN-KOT-TST','ACC-IN-JAF-TST','SRC-PG05-TEST');

INSERT INTO titan_core.carbon_transaction
(carbon_transaction_id,carbon_transaction_type_code,instrument_lot_id,quantity,transaction_date,from_account_id,obligation_id,source_id)
VALUES ('CTX-PG05-SURR2','SURRENDER','LOT-IN-CCC-2526',8107.6725,DATE '2026-04-28','ACC-IN-JAF-TST','OBL-IN-JAF-2526','SRC-PG05-TEST');

SET CONSTRAINTS ct_carbon_transaction_balance IMMEDIATE;
SET CONSTRAINTS ct_carbon_transaction_balance DEFERRED;

INSERT INTO titan_core.compliance_settlement
(settlement_id,obligation_id,settlement_version_no,required_quantity,issued_or_allocated_quantity,surrendered_quantity,settlement_status_code,policy_rule_id,source_id,supersedes_settlement_id,settlement_notes)
VALUES
('SET-PG05-JAF-V2','OBL-IN-JAF-2526',2,23107.6725,0,23107.6725,'COMPLIANT','POLRULE-IN-CCTS-SHORT','SRC-PG05-TEST','SET-PG05-JAF-V1','Later surrender completes the same obligation; v1 remains.');

-- Immutable transaction ledger rejects edits.
DO $$
DECLARE caught boolean := false;
BEGIN
    BEGIN
        UPDATE titan_core.carbon_transaction SET quantity=49999 WHERE carbon_transaction_id='CTX-PG05-ISSUE';
    EXCEPTION WHEN OTHERS THEN
        caught:=true;
    END;
    IF NOT caught THEN RAISE EXCEPTION 'PG05-T014 carbon transaction mutation was not rejected'; END IF;
END;
$$;

-- Enforcement history is separate from CCC shortfall/settlement.
INSERT INTO titan_core.enforcement_event
(enforcement_id,obligation_id,enforcement_event_type_code,enforcement_status_code,event_date,amount_formula_text,source_id,enforcement_notes,supersedes_enforcement_id)
VALUES
('ENF-PG05-JAF-TST-V1','OBL-IN-JAF-2526','COMPENSATION','OPEN',DATE '2026-04-26',
 'Environmental compensation basis: twice the average CCC trading price for the compliance-year trading cycle, applied under the governing rule to the shortfall.',
 'SRC-PG05-IN-GEI-2025','Synthetic enforcement-history test after partial surrender; no market price or actual enforcement asserted.',NULL),
('ENF-PG05-JAF-TST-V2','OBL-IN-JAF-2526','CORRECTION','CLOSED',DATE '2026-04-29',
 NULL,'SRC-PG05-TEST','Synthetic correction after later complete surrender; prior enforcement history remains.','ENF-PG05-JAF-TST-V1');

-- ---------------------------------------------------------------------------
-- 5. China ETS line-level policy replay
-- ---------------------------------------------------------------------------
INSERT INTO titan_core.entity_registry(entity_id,entity_type_code,canonical_name,country_geo_id) VALUES
('KL-CN-TST-L1','CLINKER_LINE','PG05 China Test Clinker Line 1','CTY-CN'),
('KL-CN-TST-L2','CLINKER_LINE','PG05 China Test Clinker Line 2','CTY-CN'),
('KL-CN-TST-NEW','CLINKER_LINE','PG05 China Test New Line','CTY-CN'),
('KL-CN-TST-CLOSED','CLINKER_LINE','PG05 China Test Closed Line','CTY-CN');

INSERT INTO titan_core.regulated_entity
(regulated_entity_id,scheme_id,external_registration_id,valid_from)
VALUES ('REG-CN-PG05-A','SCHEME-CN-ETS','PG05-TEST-A',DATE '2024-01-01');

INSERT INTO titan_core.regulated_entity_name_history
(regulated_entity_id,official_name,valid_from,source_id)
VALUES ('REG-CN-PG05-A','PG05 Synthetic China Key Emitter',DATE '2024-01-01','SRC-PG05-TEST');

INSERT INTO titan_core.compliance_unit
(compliance_unit_id,regulated_entity_id,compliance_unit_type_code,subject_entity_id,valid_from)
VALUES
('CU-CN-PG05-L1','REG-CN-PG05-A','KILN_LINE','KL-CN-TST-L1',DATE '2024-01-01'),
('CU-CN-PG05-L2','REG-CN-PG05-A','KILN_LINE','KL-CN-TST-L2',DATE '2024-01-01'),
('CU-CN-PG05-NEW','REG-CN-PG05-A','KILN_LINE','KL-CN-TST-NEW',DATE '2025-01-01'),
('CU-CN-PG05-CLOSED','REG-CN-PG05-A','KILN_LINE','KL-CN-TST-CLOSED',DATE '2024-01-01');

INSERT INTO titan_core.regulatory_asset_mapping
(regulatory_asset_mapping_id,regulated_entity_id,compliance_unit_id,titan_entity_id,regulatory_mapping_role_code,valid_from,mapping_confidence,source_id)
VALUES
('RAM-CN-PG05-L1','REG-CN-PG05-A','CU-CN-PG05-L1','KL-CN-TST-L1','CLINKER_LINE',DATE '2024-01-01',1.0,'SRC-PG05-TEST'),
('RAM-CN-PG05-L2','REG-CN-PG05-A','CU-CN-PG05-L2','KL-CN-TST-L2','CLINKER_LINE',DATE '2024-01-01',1.0,'SRC-PG05-TEST'),
('RAM-CN-PG05-NEW','REG-CN-PG05-A','CU-CN-PG05-NEW','KL-CN-TST-NEW','CLINKER_LINE',DATE '2025-01-01',1.0,'SRC-PG05-TEST'),
('RAM-CN-PG05-CLOSED','REG-CN-PG05-A','CU-CN-PG05-CLOSED','KL-CN-TST-CLOSED','CLINKER_LINE',DATE '2024-01-01',1.0,'SRC-PG05-TEST');

INSERT INTO titan_core.compliance_obligation
(obligation_id,policy_version_id,compliance_unit_id,compliance_period_label,period_start,period_end,obligation_method_code,metric_code,target_value_state_code,target_value,target_unit_code,denominator_id,policy_rule_id)
VALUES
('OBL-CN-PG05-L1-2024','POLV-CN-ETS-ALLOC-2425','CU-CN-PG05-L1','2024',DATE '2024-01-01',DATE '2024-12-31','VERIFIED_EMISSIONS_ALLOCATION','CEA_ALLOCATION','NOT_APPLICABLE',NULL,NULL,'DEN-CLINKER','POLRULE-CN-CEM-2024'),
('OBL-CN-PG05-L1-2025','POLV-CN-ETS-ALLOC-2425','CU-CN-PG05-L1','2025',DATE '2025-01-01',DATE '2025-12-31','BENCHMARK_ALLOCATION','CEA_ALLOCATION','NOT_APPLICABLE',NULL,NULL,'DEN-CLINKER','POLRULE-CN-CEM-2025'),
('OBL-CN-PG05-L2-2025','POLV-CN-ETS-ALLOC-2425','CU-CN-PG05-L2','2025',DATE '2025-01-01',DATE '2025-12-31','BENCHMARK_ALLOCATION','CEA_ALLOCATION','NOT_APPLICABLE',NULL,NULL,'DEN-CLINKER','POLRULE-CN-CEM-2025'),
('OBL-CN-PG05-NEW-2025','POLV-CN-ETS-ALLOC-2425','CU-CN-PG05-NEW','2025',DATE '2025-01-01',DATE '2025-12-31','BENCHMARK_ALLOCATION','CEA_ALLOCATION','NOT_APPLICABLE',NULL,NULL,'DEN-CLINKER','POLRULE-CN-CEM-2025'),
('OBL-CN-PG05-CLOSED-2025','POLV-CN-ETS-ALLOC-2425','CU-CN-PG05-CLOSED','2025',DATE '2025-01-01',DATE '2025-12-31','BENCHMARK_ALLOCATION','CEA_ALLOCATION','NOT_APPLICABLE',NULL,NULL,'DEN-CLINKER','POLRULE-CN-CEM-2025');

DO $$
DECLARE a numeric;
DECLARE rollup numeric;
BEGIN
    a:=titan_core.cn_cement_allowance_2024(1000000,true);
    IF a<>1000000 THEN RAISE EXCEPTION 'PG05-T015 China 2024 allowance failed'; END IF;

    a:=titan_core.cn_cement_allowance_2025(1000000,1200000,0.86,true);
    IF abs(a-1004651.1627906977)>0.00001 THEN RAISE EXCEPTION 'PG05-T016 China line 1 formula failed: %',a; END IF;

    rollup:=a;
    a:=titan_core.cn_cement_allowance_2025(600000,650000,0.86,true);
    IF abs(a-593398.9266547406)>0.00001 THEN RAISE EXCEPTION 'PG05-T017 China line 2 formula failed: %',a; END IF;
    rollup:=rollup+a;

    IF abs(rollup-1598050.0894454383)>0.00002 THEN
        RAISE EXCEPTION 'PG05-T018 China regulated-entity line roll-up failed: %',rollup;
    END IF;

    IF titan_core.cn_cement_allowance_2025(300000,350000,0.86,false)<>0 THEN
        RAISE EXCEPTION 'PG05-T019 new line exclusion failed';
    END IF;

    IF titan_core.cn_cement_allowance_2025(500000,550000,0.86,false)<>0 THEN
        RAISE EXCEPTION 'PG05-T020 closed-line exclusion failed';
    END IF;

    IF titan_core.cn_cement_allowance_actual_emissions(300000,true)<>300000 THEN
        RAISE EXCEPTION 'PG05-T021 special-line actual-emissions allocation failed';
    END IF;

    IF abs(titan_core.cn_cement_allowance_2025(1000000,1500000,0.86,true)-1030000)>0.00001 THEN
        RAISE EXCEPTION 'PG05-T022 positive alpha cap failed';
    END IF;

    IF abs(titan_core.cn_cement_allowance_2025(1000000,900000,0.86,true)-970000)>0.00001 THEN
        RAISE EXCEPTION 'PG05-T023 negative alpha cap failed';
    END IF;
END;
$$;

-- China 2026 remains approved-in-principle, not silently treated as promulgated.
DO $$
DECLARE current_state text;
DECLARE final_count integer;
DECLARE formula_count integer;
BEGIN
    SELECT policy_status_code INTO current_state
    FROM titan_core.policy_version_current_status
    WHERE policy_version_id='POLV-CN-ETS-ALLOC-2026';

    SELECT count(*) INTO final_count
    FROM titan_core.policy_status_history
    WHERE policy_version_id='POLV-CN-ETS-ALLOC-2026'
      AND policy_status_code IN ('PROMULGATED','EFFECTIVE');

    SELECT count(*) INTO formula_count
    FROM titan_core.policy_formula_rule
    WHERE policy_version_id='POLV-CN-ETS-ALLOC-2026';

    IF current_state<>'APPROVED_IN_PRINCIPLE' THEN
        RAISE EXCEPTION 'PG05-T024 current China 2026 status expected APPROVED_IN_PRINCIPLE, got %',current_state;
    END IF;
    IF final_count<>0 THEN RAISE EXCEPTION 'PG05-T025 China 2026 draft was incorrectly treated as final'; END IF;
    IF formula_count<>0 THEN RAISE EXCEPTION 'PG05-T026 no production formula may bind to unpromulgated China 2026 policy'; END IF;
END;
$$;

-- Overlapping status history must fail.
DO $$
DECLARE caught boolean:=false;
BEGIN
    BEGIN
        INSERT INTO titan_core.policy_status_history
        (policy_status_history_id,policy_version_id,policy_status_code,valid_from,valid_to,source_id)
        VALUES ('POLSTAT-CN-ALLOC26-BAD','POLV-CN-ETS-ALLOC-2026','CONSULTATION',DATE '2026-08-01',DATE '2026-08-30','SRC-PG05-CN-ALLOC-2026-CONS');
    EXCEPTION WHEN exclusion_violation THEN
        caught:=true;
    END;
    IF NOT caught THEN RAISE EXCEPTION 'PG05-T027 overlapping policy statuses were not rejected'; END IF;
END;
$$;

-- Regulatory mapping cannot attach a compliance unit from another regulated entity.
INSERT INTO titan_core.regulated_entity(regulated_entity_id,scheme_id,external_registration_id,valid_from)
VALUES ('REG-CN-PG05-B','SCHEME-CN-ETS','PG05-TEST-B',DATE '2025-01-01');

DO $$
DECLARE caught boolean:=false;
BEGIN
    BEGIN
        INSERT INTO titan_core.regulatory_asset_mapping
        (regulatory_asset_mapping_id,regulated_entity_id,compliance_unit_id,titan_entity_id,regulatory_mapping_role_code,valid_from,mapping_confidence,source_id)
        VALUES ('RAM-CN-PG05-BAD','REG-CN-PG05-B','CU-CN-PG05-L1','KL-CN-TST-L1','CLINKER_LINE',DATE '2025-01-01',1.0,'SRC-PG05-TEST');
    EXCEPTION WHEN OTHERS THEN
        caught:=true;
    END;
    IF NOT caught THEN RAISE EXCEPTION 'PG05-T028 mismatched regulated-entity/compliance-unit mapping was not rejected'; END IF;
END;
$$;

-- Target-intensity obligation without denominator must fail.
DO $$
DECLARE caught boolean:=false;
BEGIN
    BEGIN
        INSERT INTO titan_core.compliance_obligation
        (obligation_id,policy_version_id,compliance_unit_id,compliance_period_label,period_start,period_end,obligation_method_code,metric_code,target_value_state_code,target_value,target_unit_code)
        VALUES ('OBL-PG05-BAD-DEN','POLV-IN-CCTS-GEI-2025','CU-IN-CCTS-CMTOE085RJ','BAD',DATE '2027-04-01',DATE '2028-03-31','TARGET_INTENSITY','CCTS_GEI','VALUE',0.7,'T_CO2E');
    EXCEPTION WHEN check_violation THEN
        caught:=true;
    END;
    IF NOT caught THEN RAISE EXCEPTION 'PG05-T029 target-intensity obligation without denominator was not rejected'; END IF;
END;
$$;

-- Final ledger checks.
DO $$
DECLARE kot_bal numeric;
DECLARE jaf_bal numeric;
DECLARE versions integer;
DECLARE bank_rows integer;
DECLARE rule_links integer;
DECLARE threshold_rule numeric;
BEGIN
    SELECT balance_quantity INTO kot_bal
    FROM titan_core.compliance_account_lot_balance
    WHERE account_id='ACC-IN-KOT-TST' AND instrument_lot_id='LOT-IN-CCC-2526';

    SELECT balance_quantity INTO jaf_bal
    FROM titan_core.compliance_account_lot_balance
    WHERE account_id='ACC-IN-JAF-TST' AND instrument_lot_id='LOT-IN-CCC-2526';

    SELECT count(*) INTO versions
    FROM titan_core.compliance_settlement
    WHERE obligation_id='OBL-IN-JAF-2526';

    SELECT count(*) INTO bank_rows
    FROM titan_core.carbon_transaction
    WHERE carbon_transaction_id='CTX-PG05-BANK'
      AND carbon_transaction_type_code='BANK';

    SELECT count(*) INTO rule_links
    FROM titan_core.compliance_obligation_rule_link
    WHERE obligation_id='OBL-IN-KOT-2526'
      AND obligation_rule_role_code IN ('ISSUE','SHORTFALL','BANK');

    SELECT (parameter_schema->>'threshold_tCO2e')::numeric INTO threshold_rule
    FROM titan_core.policy_formula_rule
    WHERE policy_rule_id='POLRULE-CN-THRESHOLD-2027';

    IF abs(kot_bal-25000)>0.000001 THEN RAISE EXCEPTION 'PG05-T030 Kotputli synthetic ledger balance failed: %',kot_bal; END IF;
    IF abs(jaf_bal-1892.3275)>0.000001 THEN RAISE EXCEPTION 'PG05-T031 Jafrabad synthetic ledger balance failed: %',jaf_bal; END IF;
    IF versions<>2 THEN RAISE EXCEPTION 'PG05-T032 settlement version lineage failed'; END IF;
    IF bank_rows<>1 THEN RAISE EXCEPTION 'PG05-T033 banking event was lost'; END IF;
    IF rule_links<>3 THEN RAISE EXCEPTION 'PG05-T034 obligation must retain issuance, shortfall and banking rule links'; END IF;
    IF threshold_rule<>26000 THEN RAISE EXCEPTION 'PG05-T035 China 2027 key-emitter threshold seed failed'; END IF;
END;
$$;

SET CONSTRAINTS ALL IMMEDIATE;

ROLLBACK;

\echo 'PG-05 policy/compliance tests passed if execution reached this line.'
