-- PG-06 CCUS & Trade/CBAM integration acceptance tests
-- Run in disposable database after V001-V014.
\set ON_ERROR_STOP on
BEGIN;

-- ---------------------------------------------------------------------------
-- A. Permanent Brevik seed integrity
-- ---------------------------------------------------------------------------
DO $$
DECLARE project_state text;
DECLARE design_cap numeric;
DECLARE transferred numeric;
DECLARE stored numeric;
DECLARE residual numeric;
DECLARE bio numeric;
DECLARE life numeric;
DECLARE invented_cert_count integer;
BEGIN
    SELECT ccus_project_maturity_code INTO project_state
    FROM titan_core.ccus_project
    WHERE ccus_project_id='CCS-NO-BREVIK-001';

    SELECT numeric_value INTO design_cap FROM titan_core.observation WHERE observation_id='OBS-PG06-BREVIK-DESIGN';
    SELECT numeric_value INTO transferred FROM titan_core.observation WHERE observation_id='OBS-PG06-BREVIK-TRANSFER';
    SELECT numeric_value INTO stored FROM titan_core.observation WHERE observation_id='OBS-PG06-BREVIK-STORED';
    SELECT numeric_value INTO residual FROM titan_core.observation WHERE observation_id='OBS-PG06-BREVIK-RESIDUAL';
    SELECT numeric_value INTO bio FROM titan_core.observation WHERE observation_id='OBS-PG06-BREVIK-BIO';
    SELECT numeric_value INTO life FROM titan_core.observation WHERE observation_id='OBS-PG06-BREVIK-LIFE';

    SELECT count(*) INTO invented_cert_count
    FROM titan_core.storage_certificate
    WHERE co2_batch_id='CO2B-BREVIK-2025';

    IF project_state<>'OPERATING' THEN RAISE EXCEPTION 'PG06-T001 Brevik current state expected OPERATING'; END IF;
    IF design_cap<>400000 THEN RAISE EXCEPTION 'PG06-T002 Brevik design capacity expected 400000'; END IF;
    IF transferred<>58408 OR stored<>37500 THEN RAISE EXCEPTION 'PG06-T003 Brevik transferred/stored values failed'; END IF;
    IF residual<>20908 OR residual<>transferred-stored THEN RAISE EXCEPTION 'PG06-T004 Brevik residual calculation failed'; END IF;
    IF bio<>4125 THEN RAISE EXCEPTION 'PG06-T005 Brevik provisional biogenic quantity failed'; END IF;
    IF life<>1236 THEN RAISE EXCEPTION 'PG06-T006 Brevik lifecycle emissions failed'; END IF;
    IF invented_cert_count<>0 THEN RAISE EXCEPTION 'PG06-T007 no aggregate/fictional Brevik certificate number may be invented'; END IF;
END;
$$;

DO $$
DECLARE state_count integer;
DECLARE loss_count integer;
DECLARE pending_count integer;
BEGIN
    SELECT count(*) INTO state_count
    FROM titan_core.co2_chain_state
    WHERE co2_batch_id='CO2B-BREVIK-2025'
      AND co2_batch_state_code='IN_CHAIN_UNRECONCILED'
      AND quantity_observation_id='OBS-PG06-BREVIK-RESIDUAL';

    SELECT count(*) INTO loss_count
    FROM titan_core.co2_chain_state
    WHERE co2_batch_id='CO2B-BREVIK-2025'
      AND co2_batch_state_code IN ('LOST','VENTED');

    SELECT count(*) INTO pending_count
    FROM titan_core.ccus_accounting_result
    WHERE co2_batch_id='CO2B-BREVIK-2025'
      AND ccus_accounting_class_code='PENDING';

    IF state_count<>1 THEN RAISE EXCEPTION 'PG06-T008 residual must remain IN_CHAIN_UNRECONCILED'; END IF;
    IF loss_count<>0 THEN RAISE EXCEPTION 'PG06-T009 residual may not be auto-labelled loss/venting'; END IF;
    IF pending_count<>1 THEN RAISE EXCEPTION 'PG06-T010 mixed-origin stored quantity must not be auto-classified as removal'; END IF;
END;
$$;

-- Origin shares cannot exceed physical whole.
INSERT INTO titan_core.entity_registry(entity_id,entity_type_code,canonical_name,country_geo_id)
VALUES ('OBS-PG06-ORIGIN-TEST','OBSERVATION','PG06 synthetic origin component','CTY-NO');

INSERT INTO titan_core.observation
(observation_id,subject_entity_id,metric_code,quantity_kind_code,value_state_code,data_class_code,numeric_value,unit_code,period_start,period_end)
VALUES ('OBS-PG06-ORIGIN-TEST','CCS-NO-BREVIK-001','SYNTHETIC_ORIGIN','ABSOLUTE','VALUE','M',100,'T_CO2',DATE '2025-01-01',DATE '2025-12-31');

INSERT INTO titan_core.observation_model_provenance
(observation_id,model_ref,model_version_ref,assumption_set_ref)
VALUES ('OBS-PG06-ORIGIN-TEST','PG06_SYNTHETIC','v1','PG06-TEST');

DO $$
DECLARE caught boolean:=false;
BEGIN
    BEGIN
        INSERT INTO titan_core.co2_batch_origin_component
        (co2_batch_id,carbon_origin_code,origin_share,quantity_observation_id,source_id)
        VALUES ('CO2B-BREVIK-2025','FOSSIL_FUEL',1.01,'OBS-PG06-ORIGIN-TEST','SRC-PG06-HM-ASR25');
    EXCEPTION WHEN check_violation THEN
        caught:=true;
    END;
    IF NOT caught THEN RAISE EXCEPTION 'PG06-T011 origin share above 100% was not rejected'; END IF;
END;
$$;

-- ---------------------------------------------------------------------------
-- B. Storage-backed carbon attribute ledger
-- ---------------------------------------------------------------------------
INSERT INTO titan_core.entity_registry(entity_id,entity_type_code,canonical_name,country_geo_id) VALUES
('SRC-PG06-TEST','SOURCE','PG06 synthetic rollback test source','CTY-DE'),
('OBS-PG06-CERT25','OBSERVATION','PG06 synthetic certified stored quantity','CTY-NO');

INSERT INTO titan_core.source_document
(source_id,publisher_name,document_title,document_type_code,evidence_grade_code,language_code,archival_status_code,authoritative_status)
VALUES ('SRC-PG06-TEST','TITAN Test Harness','PG06 synthetic fixtures','TECHNICAL_REPORT','X','en','LIVE_ONLY','SYNTHETIC');

INSERT INTO titan_core.observation
(observation_id,subject_entity_id,metric_code,quantity_kind_code,value_state_code,data_class_code,numeric_value,unit_code,period_start,period_end)
VALUES ('OBS-PG06-CERT25','CCS-NO-BREVIK-001','SYNTHETIC_CERTIFIED_STORAGE','ABSOLUTE','VALUE','M',25000,'T_CO2',DATE '2025-01-01',DATE '2025-12-31');

INSERT INTO titan_core.observation_model_provenance
(observation_id,model_ref,model_version_ref,assumption_set_ref)
VALUES ('OBS-PG06-CERT25','PG06_SYNTHETIC','v1','PG06-TEST');

INSERT INTO titan_core.storage_certificate
(storage_certificate_id,co2_batch_id,storage_site_id,certificate_number,certificate_date,certified_stored_observation_id,source_id,certificate_notes)
VALUES ('SCERT-PG06-TST','CO2B-BREVIK-2025','STOR-NL-AURORA','SYNTHETIC-TEST-CERT',DATE '2026-01-15','OBS-PG06-CERT25','SRC-PG06-TEST','Rollback test only; not a real Northern Lights certificate number.');

INSERT INTO titan_core.carbon_attribute_scheme
(attribute_scheme_id,scheme_name,scheme_owner_name,generation_basis,assurance_basis,source_id)
VALUES ('ATTRSCHEME-PG06-TST','PG06 synthetic storage-backed attribute scheme','TITAN Test Harness','Cannot generate more attributes than certified stored quantity','Synthetic test','SRC-PG06-TEST');

INSERT INTO titan_core.carbon_attribute_lot
(attribute_lot_id,attribute_scheme_id,ccus_project_id,storage_certificate_id,eligible_quantity_observation_id,vintage_label,source_id)
VALUES ('ATTRLOT-PG06-TST','ATTRSCHEME-PG06-TST','CCS-NO-BREVIK-001','SCERT-PG06-TST','OBS-PG06-CERT25','2025','SRC-PG06-TEST');

INSERT INTO titan_core.carbon_attribute_transaction
(attribute_transaction_id,attribute_transaction_type_code,attribute_lot_id,quantity,transaction_date,to_account_ref,source_id)
VALUES ('ATX-PG06-GEN','GENERATE','ATTRLOT-PG06-TST',25000,DATE '2026-01-16','ATTR-BANK','SRC-PG06-TEST');

INSERT INTO titan_core.carbon_attribute_transaction
(attribute_transaction_id,attribute_transaction_type_code,attribute_lot_id,quantity,transaction_date,from_account_ref,to_account_ref,source_id)
VALUES ('ATX-PG06-ALLOC','ALLOCATE','ATTRLOT-PG06-TST',24000,DATE '2026-01-17','ATTR-BANK','CUSTOMER-A','SRC-PG06-TEST');

SET CONSTRAINTS ct_attribute_balance IMMEDIATE;
SET CONSTRAINTS ct_attribute_balance DEFERRED;

-- Generation above certified storage rejected.
DO $$
DECLARE caught boolean:=false;
BEGIN
    BEGIN
        INSERT INTO titan_core.carbon_attribute_transaction
        (attribute_transaction_id,attribute_transaction_type_code,attribute_lot_id,quantity,transaction_date,to_account_ref,source_id)
        VALUES ('ATX-PG06-OVERGEN','GENERATE','ATTRLOT-PG06-TST',1000,DATE '2026-01-18','ATTR-BANK','SRC-PG06-TEST');
        SET CONSTRAINTS ct_attribute_balance IMMEDIATE;
    EXCEPTION WHEN OTHERS THEN
        caught:=true;
    END;
    SET CONSTRAINTS ct_attribute_balance DEFERRED;
    IF NOT caught THEN RAISE EXCEPTION 'PG06-T012 attribute generation above certified storage was not rejected'; END IF;
END;
$$;

-- Allocation above available balance rejected.
DO $$
DECLARE caught boolean:=false;
BEGIN
    BEGIN
        INSERT INTO titan_core.carbon_attribute_transaction
        (attribute_transaction_id,attribute_transaction_type_code,attribute_lot_id,quantity,transaction_date,from_account_ref,to_account_ref,source_id)
        VALUES ('ATX-PG06-OVERALLOC','ALLOCATE','ATTRLOT-PG06-TST',2000,DATE '2026-01-18','ATTR-BANK','CUSTOMER-B','SRC-PG06-TEST');
        SET CONSTRAINTS ct_attribute_balance IMMEDIATE;
    EXCEPTION WHEN OTHERS THEN
        caught:=true;
    END;
    SET CONSTRAINTS ct_attribute_balance DEFERRED;
    IF NOT caught THEN RAISE EXCEPTION 'PG06-T013 attribute allocation above available balance was not rejected'; END IF;
END;
$$;

DO $$
DECLARE bal numeric;
DECLARE caught boolean:=false;
BEGIN
    SELECT balance_quantity INTO bal
    FROM titan_core.carbon_attribute_account_balance
    WHERE account_ref='ATTR-BANK' AND attribute_lot_id='ATTRLOT-PG06-TST';
    IF bal<>1000 THEN RAISE EXCEPTION 'PG06-T014 attribute bank balance expected 1000, got %',bal; END IF;

    BEGIN
        UPDATE titan_core.carbon_attribute_transaction
        SET quantity=24999 WHERE attribute_transaction_id='ATX-PG06-GEN';
    EXCEPTION WHEN OTHERS THEN caught:=true; END;
    IF NOT caught THEN RAISE EXCEPTION 'PG06-T015 attribute transaction mutation was not rejected'; END IF;
END;
$$;

-- ---------------------------------------------------------------------------
-- C. Current CBAM seed integrity
-- ---------------------------------------------------------------------------
DO $$
DECLARE q1 numeric;
DECLARE q2 numeric;
DECLARE q3 integer;
DECLARE draft_status text;
DECLARE final_relief_rules integer;
BEGIN
    SELECT price_eur_per_certificate INTO q1 FROM titan_core.cbam_price_reference WHERE cbam_price_reference_id='CBP-2026-Q1';
    SELECT price_eur_per_certificate INTO q2 FROM titan_core.cbam_price_reference WHERE cbam_price_reference_id='CBP-2026-Q2';
    SELECT count(*) INTO q3 FROM titan_core.cbam_price_reference WHERE price_year=2026 AND price_period_label='Q3';
    SELECT policy_status_code INTO draft_status
    FROM titan_core.policy_version_current_status
    WHERE policy_version_id='POLV-EU-CBAM-FCP-DRAFT';

    SELECT count(*) INTO final_relief_rules
    FROM titan_core.policy_formula_rule
    WHERE policy_version_id='POLV-EU-CBAM-FCP-DRAFT';

    IF q1<>75.36 OR q2<>75.28 THEN RAISE EXCEPTION 'PG06-T016 current Q1/Q2 CBAM prices failed'; END IF;
    IF q3<>0 THEN RAISE EXCEPTION 'PG06-T017 Q3 2026 price must not exist before publication'; END IF;
    IF draft_status<>'CONSULTATION' THEN RAISE EXCEPTION 'PG06-T018 carbon-price-paid detailed act expected CONSULTATION'; END IF;
    IF final_relief_rules<>0 THEN RAISE EXCEPTION 'PG06-T019 draft carbon-price conversion formula must not be production-bound'; END IF;
END;
$$;

DO $$
DECLARE s50 text;
DECLARE s50p text;
DECLARE def numeric;
BEGIN
    SELECT titan_core.cbam_threshold_state_50t(50) INTO s50;
    SELECT titan_core.cbam_threshold_state_50t(50.0001) INTO s50p;
    SELECT titan_core.cbam_2026_default_effective_intensity(0.90) INTO def;

    IF s50<>'BELOW_THRESHOLD' THEN RAISE EXCEPTION 'PG06-T020 exactly 50 t must remain below >50 threshold'; END IF;
    IF s50p<>'IN_SCOPE' THEN RAISE EXCEPTION 'PG06-T021 >50 t must be in scope'; END IF;
    IF abs(def-0.99)>0.0000001 THEN RAISE EXCEPTION 'PG06-T022 2026 10%% default mark-up failed'; END IF;
END;
$$;

-- ---------------------------------------------------------------------------
-- D. Shipment, route, precursor and exposure integration
-- ---------------------------------------------------------------------------
INSERT INTO titan_core.entity_registry(entity_id,entity_type_code,canonical_name,country_geo_id) VALUES
('CO-PG06-EU-IMPORTER','LEGAL_ENTITY','PG06 Synthetic EU Importer','CTY-DE'),
('PROD-PG06-CEM','PRODUCT','PG06 Synthetic Portland Cement','CTY-CN'),
('OBS-PG06-SHP1-EED','OBSERVATION','PG06 shipment 1 embedded emissions','CTY-DE'),
('OBS-PG06-SHP1-EXP','OBSERVATION','PG06 shipment 1 gross CBAM exposure','CTY-DE'),
('OBS-PG06-PREC-A-Q','OBSERVATION','PG06 precursor A quantity','CTY-CN'),
('OBS-PG06-PREC-A-I','OBSERVATION','PG06 precursor A intensity','CTY-CN'),
('OBS-PG06-PREC-B-Q','OBSERVATION','PG06 precursor B quantity','CTY-CN'),
('OBS-PG06-PREC-B-I','OBSERVATION','PG06 precursor B intensity','CTY-CN'),
('OBS-PG06-PREC-TOT','OBSERVATION','PG06 precursor weighted emissions','CTY-CN'),
('OBS-PG06-SHP2-EED','OBSERVATION','PG06 shipment 2 embedded emissions','CTY-DE'),
('OBS-PG06-SHP2-EXP','OBSERVATION','PG06 shipment 2 gross CBAM exposure','CTY-DE'),
('OBS-PG06-FCP-GROSS','OBSERVATION','PG06 synthetic foreign carbon price gross','CTY-DE'),
('OBS-PG06-FCP-REBATE','OBSERVATION','PG06 synthetic foreign carbon price rebate','CTY-DE'),
('OBS-PG06-FCP-NET','OBSERVATION','PG06 synthetic foreign carbon price net','CTY-DE');

INSERT INTO titan_core.material_master(material_id,material_name,material_class) VALUES
('MAT-PG06-CLINKER','PG06 Synthetic Clinker','CLINKER'),
('MAT-PG06-SLAG','PG06 Synthetic Slag','SCM');

INSERT INTO titan_core.product_master(product_id,product_name,product_category)
VALUES ('PROD-PG06-CEM','PG06 Synthetic Portland Cement','CEMENT');

INSERT INTO titan_core.product_version(product_version_id,product_id,version_label,product_version_status_code,valid_from)
VALUES ('PRODV-PG06-CEM','PROD-PG06-CEM','2026 synthetic formulation','CURRENT',DATE '2026-01-01');

INSERT INTO titan_core.extraction_record
(extraction_id,source_id,location_ref,extracted_text,extracted_numeric_value,extracted_unit_text,extraction_method_code)
VALUES
('EXT-PG06-SHP1','SRC-PG06-TEST','synthetic shipment 1','Synthetic verified intensity 0.82 tCO2e/t and 10,000 t mass',0.82,'tCO2e/t','MANUAL'),
('EXT-PG06-SHP2','SRC-PG06-TEST','synthetic shipment 2','Synthetic cement total embedded emissions 4,450 tCO2e',4450,'tCO2e','MANUAL');

INSERT INTO titan_core.observation
(observation_id,subject_entity_id,metric_code,quantity_kind_code,value_state_code,data_class_code,numeric_value,unit_code,period_start,period_end)
VALUES
('OBS-PG06-SHP1-EED','CO-PG06-EU-IMPORTER','CBAM_EMBEDDED_EMISSIONS','ABSOLUTE','VALUE','R',8200,'T_CO2E',DATE '2026-04-01',DATE '2026-06-30'),
('OBS-PG06-SHP1-EXP','CO-PG06-EU-IMPORTER','CBAM_GROSS_EXPOSURE','ABSOLUTE','VALUE','D',617296,'EUR',DATE '2026-04-01',DATE '2026-06-30'),
('OBS-PG06-PREC-A-Q','PL-CN-AH-000004','PRECURSOR_QUANTITY','ABSOLUTE','VALUE','M',60000,'TONNE',DATE '2026-01-01',DATE '2026-12-31'),
('OBS-PG06-PREC-A-I','PL-CN-AH-000004','CBAM_PRECURSOR_INTENSITY','INTENSITY','VALUE','M',0.80,'T_CO2E','DEN-CLINKER',DATE '2026-01-01',DATE '2026-12-31'),
('OBS-PG06-PREC-B-Q','PL-CN-AH-000002','PRECURSOR_QUANTITY','ABSOLUTE','VALUE','M',40000,'TONNE',DATE '2026-01-01',DATE '2026-12-31'),
('OBS-PG06-PREC-B-I','PL-CN-AH-000002','CBAM_PRECURSOR_INTENSITY','INTENSITY','VALUE','M',0.90,'T_CO2E','DEN-CLINKER',DATE '2026-01-01',DATE '2026-12-31'),
('OBS-PG06-PREC-TOT','PL-CN-AH-000019','CBAM_PRECURSOR_EMBEDDED_EMISSIONS','ABSOLUTE','VALUE','D',84000,'T_CO2E',DATE '2026-01-01',DATE '2026-12-31'),
('OBS-PG06-SHP2-EED','CO-PG06-EU-IMPORTER','CBAM_EMBEDDED_EMISSIONS','ABSOLUTE','VALUE','R',4450,'T_CO2E',DATE '2026-01-01',DATE '2026-03-31'),
('OBS-PG06-SHP2-EXP','CO-PG06-EU-IMPORTER','CBAM_GROSS_EXPOSURE','ABSOLUTE','VALUE','D',335352,'EUR',DATE '2026-01-01',DATE '2026-03-31'),
('OBS-PG06-FCP-GROSS','CO-PG06-EU-IMPORTER','FOREIGN_CARBON_PRICE_GROSS','ABSOLUTE','VALUE','M',30,'EUR_PER_T_CO2E',DATE '2026-01-01',DATE '2026-12-31'),
('OBS-PG06-FCP-REBATE','CO-PG06-EU-IMPORTER','FOREIGN_CARBON_PRICE_REBATE','ABSOLUTE','VALUE','M',10,'EUR_PER_T_CO2E',DATE '2026-01-01',DATE '2026-12-31'),
('OBS-PG06-FCP-NET','CO-PG06-EU-IMPORTER','FOREIGN_CARBON_PRICE_NET','ABSOLUTE','VALUE','D',20,'EUR_PER_T_CO2E',DATE '2026-01-01',DATE '2026-12-31');

INSERT INTO titan_core.observation_evidence_link(observation_id,extraction_id,support_type_code) VALUES
('OBS-PG06-SHP1-EED','EXT-PG06-SHP1','SUPPORTS'),
('OBS-PG06-SHP2-EED','EXT-PG06-SHP2','SUPPORTS');

INSERT INTO titan_core.observation_model_provenance(observation_id,model_ref,model_version_ref,assumption_set_ref) VALUES
('OBS-PG06-PREC-A-Q','PG06_SYNTHETIC','v1','PG06-TEST'),
('OBS-PG06-PREC-A-I','PG06_SYNTHETIC','v1','PG06-TEST'),
('OBS-PG06-PREC-B-Q','PG06_SYNTHETIC','v1','PG06-TEST'),
('OBS-PG06-PREC-B-I','PG06_SYNTHETIC','v1','PG06-TEST'),
('OBS-PG06-FCP-GROSS','PG06_SYNTHETIC','v1','PG06-TEST'),
('OBS-PG06-FCP-REBATE','PG06_SYNTHETIC','v1','PG06-TEST');

INSERT INTO titan_core.observation_derivation(observation_id,formula_text,calculation_notes) VALUES
('OBS-PG06-SHP1-EXP','embedded emissions * applicable quarter CBAM certificate price','8,200 * 75.28'),
('OBS-PG06-PREC-TOT','60000*0.80 + 40000*0.90','Weighted precursor embedded emissions'),
('OBS-PG06-SHP2-EXP','embedded emissions * applicable quarter CBAM certificate price','4,450 * 75.36'),
('OBS-PG06-FCP-NET','gross carbon price - rebate/compensation','Synthetic only');

INSERT INTO titan_core.observation_derivation_input(observation_id,input_observation_id,input_role) VALUES
('OBS-PG06-SHP1-EXP','OBS-PG06-SHP1-EED','EMBEDDED_EMISSIONS'),
('OBS-PG06-PREC-TOT','OBS-PG06-PREC-A-Q','SOURCE_A_QUANTITY'),
('OBS-PG06-PREC-TOT','OBS-PG06-PREC-A-I','SOURCE_A_INTENSITY'),
('OBS-PG06-PREC-TOT','OBS-PG06-PREC-B-Q','SOURCE_B_QUANTITY'),
('OBS-PG06-PREC-TOT','OBS-PG06-PREC-B-I','SOURCE_B_INTENSITY'),
('OBS-PG06-SHP2-EXP','OBS-PG06-SHP2-EED','EMBEDDED_EMISSIONS'),
('OBS-PG06-FCP-NET','OBS-PG06-FCP-GROSS','GROSS_PRICE'),
('OBS-PG06-FCP-NET','OBS-PG06-FCP-REBATE','REBATE');

INSERT INTO titan_core.trade_shipment
(shipment_id,shipment_date,importer_entity_id,country_of_dispatch_geo_id,customs_origin_geo_id,destination_geo_id,source_id,shipment_notes)
VALUES
('SHP-PG06-CLINKER',DATE '2026-05-15','CO-PG06-EU-IMPORTER','CTY-AE','CTY-IN','CTY-DE','SRC-PG06-TEST','Synthetic clinker shipment via UAE transshipment; production/customs origin remain India.'),
('SHP-PG06-CEMENT',DATE '2026-02-15','CO-PG06-EU-IMPORTER','CTY-CN','CTY-CN','CTY-NL','SRC-PG06-TEST','Synthetic complex cement shipment.');

INSERT INTO titan_core.shipment_line
(shipment_line_id,shipment_id,cn_hs_code,classification_version,material_id,net_mass_tonnes,source_id)
VALUES ('SHPL-PG06-CLINKER','SHP-PG06-CLINKER','2523 10 00','CN 2026','MAT-PG06-CLINKER',10000,'SRC-PG06-TEST');

INSERT INTO titan_core.shipment_line
(shipment_line_id,shipment_id,cn_hs_code,classification_version,product_version_id,net_mass_tonnes,source_id)
VALUES ('SHPL-PG06-CEMENT','SHP-PG06-CEMENT','2523 29 00','CN 2026','PRODV-PG06-CEM',5000,'SRC-PG06-TEST');

INSERT INTO titan_core.route_segment
(route_segment_id,shipment_id,segment_no,mode_code,origin_geo_id,destination_geo_id,source_id,route_notes)
VALUES
('ROUTESEG-PG06-1A','SHP-PG06-CLINKER',1,'SHIP','CTY-IN','CTY-AE','SRC-PG06-TEST','India to UAE transshipment'),
('ROUTESEG-PG06-1B','SHP-PG06-CLINKER',2,'SHIP','CTY-AE','CTY-DE','SRC-PG06-TEST','UAE to Germany');

INSERT INTO titan_core.production_installation_link
(production_installation_link_id,shipment_line_id,installation_entity_id,production_period_start,production_period_end,attribution_share,source_id)
VALUES
('PRDLINK-PG06-CLINKER','SHPL-PG06-CLINKER','PL-IN-RJ-000002',DATE '2026-01-01',DATE '2026-12-31',1.0,'SRC-PG06-TEST'),
('PRDLINK-PG06-CEMENT','SHPL-PG06-CEMENT','PL-CN-AH-000019',DATE '2026-01-01',DATE '2026-12-31',1.0,'SRC-PG06-TEST');

INSERT INTO titan_core.precursor_allocation
(precursor_allocation_id,shipment_line_id,precursor_material_id,source_installation_entity_id,production_period_start,production_period_end,quantity_observation_id,intensity_observation_id,embedded_emissions_method_code,source_id)
VALUES
('PREC-PG06-A','SHPL-PG06-CEMENT','MAT-PG06-CLINKER','PL-CN-AH-000004',DATE '2026-01-01',DATE '2026-12-31','OBS-PG06-PREC-A-Q','OBS-PG06-PREC-A-I','ACTUAL_VERIFIED','SRC-PG06-TEST'),
('PREC-PG06-B','SHPL-PG06-CEMENT','MAT-PG06-CLINKER','PL-CN-AH-000002',DATE '2026-01-01',DATE '2026-12-31','OBS-PG06-PREC-B-Q','OBS-PG06-PREC-B-I','ACTUAL_VERIFIED','SRC-PG06-TEST');

INSERT INTO titan_core.embedded_emissions_declaration
(embedded_emissions_declaration_id,shipment_line_id,embedded_emissions_method_code,policy_version_id,total_embedded_emissions_observation_id,verifier_name_text,source_id,declaration_notes)
VALUES
('EED-PG06-CLINKER','SHPL-PG06-CLINKER','ACTUAL_VERIFIED','POLV-EU-CBAM-METHOD','OBS-PG06-SHP1-EED','PG06 synthetic verifier','SRC-PG06-TEST','Synthetic actual-verified branch test'),
('EED-PG06-CEMENT','SHPL-PG06-CEMENT','ACTUAL_VERIFIED','POLV-EU-CBAM-METHOD','OBS-PG06-SHP2-EED','PG06 synthetic verifier','SRC-PG06-TEST','Synthetic complex-good precursor branch test');

INSERT INTO titan_core.cbam_threshold_assessment
(cbam_threshold_assessment_id,importer_entity_id,assessment_year,cumulative_covered_mass_tonnes,threshold_tonnes,cbam_threshold_state_code,policy_version_id,source_id,assessment_notes)
VALUES ('CBTH-PG06-2026','CO-PG06-EU-IMPORTER',2026,65,50,'IN_SCOPE','POLV-EU-CBAM-THRESH','SRC-PG06-TEST','Synthetic annual covered mass across CBAM mass sectors.');

INSERT INTO titan_core.cbam_exposure
(cbam_exposure_id,shipment_line_id,embedded_emissions_declaration_id,cbam_threshold_assessment_id,cbam_price_reference_id,gross_exposure_observation_id,policy_version_id,source_id)
VALUES
('CBX-PG06-CLINKER','SHPL-PG06-CLINKER','EED-PG06-CLINKER','CBTH-PG06-2026','CBP-2026-Q2','OBS-PG06-SHP1-EXP','POLV-EU-CBAM-BASE','SRC-PG06-TEST'),
('CBX-PG06-CEMENT','SHPL-PG06-CEMENT','EED-PG06-CEMENT','CBTH-PG06-2026','CBP-2026-Q1','OBS-PG06-SHP2-EXP','POLV-EU-CBAM-BASE','SRC-PG06-TEST');

-- Foreign carbon price: principle exists, detailed conversion remains pending.
INSERT INTO titan_core.foreign_carbon_price_evidence
(foreign_carbon_price_evidence_id,embedded_emissions_declaration_id,foreign_scheme_name,gross_price_paid_observation_id,rebate_compensation_observation_id,net_effective_price_observation_id,independent_certifier_name,relief_eligibility_state_code,conversion_policy_version_id,source_id,evidence_notes)
VALUES ('FCP-PG06-TST','EED-PG06-CLINKER','Synthetic third-country carbon scheme','OBS-PG06-FCP-GROSS','OBS-PG06-FCP-REBATE','OBS-PG06-FCP-NET','PG06 synthetic certifier','PENDING_RULE',NULL,'SRC-PG06-TEST','Headline 30 less 10 rebate = 20 net; no final conversion calculation.');

INSERT INTO titan_core.policy_relief_calculation
(policy_relief_calculation_id,foreign_carbon_price_evidence_id,relief_calculation_status_code,relief_observation_id,governing_policy_version_id,calculation_method,source_id,calculation_notes)
VALUES ('REL-CALC-PG06-DRAFT','FCP-PG06-TST','DRAFT_CALC',NULL,NULL,'No numeric CBAM reduction calculated until final Article 9 conversion act is promulgated','SRC-PG06-TEST','Correctly held as draft/pending.');

-- Final relief cannot be fabricated without governing final rule + relief observation.
DO $$
DECLARE caught boolean:=false;
BEGIN
    BEGIN
        INSERT INTO titan_core.policy_relief_calculation
        (policy_relief_calculation_id,foreign_carbon_price_evidence_id,relief_calculation_status_code,calculation_method,source_id)
        VALUES ('REL-CALC-PG06-BAD','FCP-PG06-TST','FINAL_CALC','Analyst chosen EUR-for-EUR shortcut','SRC-PG06-TEST');
    EXCEPTION WHEN check_violation THEN
        caught:=true;
    END;
    IF NOT caught THEN RAISE EXCEPTION 'PG06-T023 final foreign-carbon-price relief without governing rule was not rejected'; END IF;
END;
$$;

-- Actual-verified EED without verifier must fail.
DO $$
DECLARE caught boolean:=false;
BEGIN
    BEGIN
        INSERT INTO titan_core.embedded_emissions_declaration
        (embedded_emissions_declaration_id,shipment_line_id,embedded_emissions_method_code,policy_version_id,total_embedded_emissions_observation_id,source_id)
        VALUES ('EED-PG06-BAD','SHPL-PG06-CLINKER','ACTUAL_VERIFIED','POLV-EU-CBAM-METHOD','OBS-PG06-SHP1-EED','SRC-PG06-TEST');
    EXCEPTION WHEN check_violation THEN caught:=true; END;
    IF NOT caught THEN RAISE EXCEPTION 'PG06-T024 actual-verified EED without verifier was not rejected'; END IF;
END;
$$;

-- Precursor weighted average + exposure formula checks.
DO $$
DECLARE weighted numeric;
DECLARE intensity numeric;
DECLARE e1 numeric;
DECLARE e2 numeric;
DECLARE dispatch_geo text;
DECLARE origin_geo text;
BEGIN
    weighted := 60000*0.80 + 40000*0.90;
    intensity := weighted/100000;
    e1 := titan_core.cbam_gross_exposure(8200,75.28);
    e2 := titan_core.cbam_gross_exposure(4450,75.36);

    SELECT country_of_dispatch_geo_id,customs_origin_geo_id INTO dispatch_geo,origin_geo
    FROM titan_core.trade_shipment WHERE shipment_id='SHP-PG06-CLINKER';

    IF weighted<>84000 OR abs(intensity-0.84)>0.0000001 THEN
        RAISE EXCEPTION 'PG06-T025 precursor weighted average failed';
    END IF;
    IF abs(e1-617296)>0.000001 OR abs(e2-335352)>0.000001 THEN
        RAISE EXCEPTION 'PG06-T026 CBAM quarter exposure calculation failed';
    END IF;
    IF dispatch_geo<>'CTY-AE' OR origin_geo<>'CTY-IN' THEN
        RAISE EXCEPTION 'PG06-T027 transshipment incorrectly changed customs/production origin';
    END IF;
END;
$$;

-- 2026 default example 0.90 × 1.10 × 1000 t × Q2 price.
DO $$
DECLARE eff numeric;
DECLARE em numeric;
DECLARE exp numeric;
BEGIN
    eff:=titan_core.cbam_2026_default_effective_intensity(0.90);
    em:=eff*1000;
    exp:=titan_core.cbam_gross_exposure(em,75.28);
    IF abs(eff-0.99)>0.000001 OR abs(em-990)>0.000001 OR abs(exp-74527.2)>0.0001 THEN
        RAISE EXCEPTION 'PG06-T028 default-value exposure replay failed';
    END IF;
END;
$$;

-- Attribute allocation cannot silently reduce CBAM exposure.
DO $$
DECLARE exposure_before numeric;
DECLARE exposure_after numeric;
BEGIN
    SELECT numeric_value INTO exposure_before
    FROM titan_core.observation WHERE observation_id='OBS-PG06-SHP1-EXP';

    -- Allocate a valid storage-backed product attribute to a customer account.
    INSERT INTO titan_core.carbon_attribute_transaction
    (attribute_transaction_id,attribute_transaction_type_code,attribute_lot_id,quantity,transaction_date,from_account_ref,to_account_ref,source_id)
    VALUES ('ATX-PG06-CBAM-SEPARATION','ALLOCATE','ATTRLOT-PG06-TST',500,DATE '2026-05-15','ATTR-BANK','CO-PG06-EU-IMPORTER','SRC-PG06-TEST');

    SELECT numeric_value INTO exposure_after
    FROM titan_core.observation WHERE observation_id='OBS-PG06-SHP1-EXP';

    IF exposure_after IS DISTINCT FROM exposure_before THEN
        RAISE EXCEPTION 'PG06-T029 product attribute silently changed CBAM exposure';
    END IF;
END;
$$;

-- CBAM settlement for 2026 imports is not yet due in 2026.
INSERT INTO titan_core.cbam_settlement
(cbam_settlement_id,importer_entity_id,reporting_year,settlement_version_no,cbam_settlement_status_code,policy_version_id,source_id,settlement_notes)
VALUES ('CBS-PG06-2026-V1','CO-PG06-EU-IMPORTER',2026,1,'NOT_DUE','POLV-EU-CBAM-BASE','SRC-PG06-EU-CBAM-BASE','2026 imports first declaration/surrender due in 2027; no premature certificate surrender record.');

-- Final controls.
DO $$
DECLARE n_prices integer;
DECLARE n_q3 integer;
DECLARE attr_bal numeric;
DECLARE threshold_state text;
DECLARE settlement_state text;
DECLARE relief_state text;
BEGIN
    SELECT count(*) INTO n_prices FROM titan_core.cbam_price_reference WHERE price_year=2026;
    SELECT count(*) INTO n_q3 FROM titan_core.cbam_price_reference WHERE price_year=2026 AND price_period_label='Q3';
    SELECT balance_quantity INTO attr_bal
    FROM titan_core.carbon_attribute_account_balance
    WHERE account_ref='ATTR-BANK' AND attribute_lot_id='ATTRLOT-PG06-TST';
    SELECT cbam_threshold_state_code INTO threshold_state
    FROM titan_core.cbam_threshold_assessment WHERE cbam_threshold_assessment_id='CBTH-PG06-2026';
    SELECT cbam_settlement_status_code INTO settlement_state
    FROM titan_core.cbam_settlement WHERE cbam_settlement_id='CBS-PG06-2026-V1';
    SELECT relief_eligibility_state_code INTO relief_state
    FROM titan_core.foreign_carbon_price_evidence WHERE foreign_carbon_price_evidence_id='FCP-PG06-TST';

    IF n_prices<>2 OR n_q3<>0 THEN RAISE EXCEPTION 'PG06-T030 price reference count failed'; END IF;
    IF attr_bal<>500 THEN RAISE EXCEPTION 'PG06-T031 attribute bank expected 500 after CBAM-separation allocation, got %',attr_bal; END IF;
    IF threshold_state<>'IN_SCOPE' THEN RAISE EXCEPTION 'PG06-T032 annual threshold assessment failed'; END IF;
    IF settlement_state<>'NOT_DUE' THEN RAISE EXCEPTION 'PG06-T033 2026 settlement timing failed'; END IF;
    IF relief_state<>'PENDING_RULE' THEN RAISE EXCEPTION 'PG06-T034 foreign carbon price relief should remain PENDING_RULE'; END IF;
END;
$$;

SET CONSTRAINTS ALL IMMEDIATE;
ROLLBACK;

\echo 'PG-06 CCUS/trade integration tests passed if execution reached this line.'
