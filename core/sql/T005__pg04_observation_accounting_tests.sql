-- PG-04 Observation & Accounting Layer acceptance tests
-- Run in disposable DB after V001-V009.
\set ON_ERROR_STOP on

BEGIN;

-- Evidence/method fixtures.
INSERT INTO titan_core.entity_registry(entity_id,entity_type_code,canonical_name,country_geo_id) VALUES
('SRC-PG04-0001','SOURCE','PG04 Test Accounting Source','CTY-IN'),
('SRC-PG04-0002','SOURCE','PG04 Test EPD Source','CTY-IN'),
('BND-PG04-0001','BOUNDARY','PG04 Test Plant Boundary','CTY-IN'),
('BND-PG04-0002','BOUNDARY','PG04 Test Comparison Plant Boundary','CTY-IN'),
('OBS-PG04-R1','OBSERVATION','PG04 Reported clinker intensity','CTY-IN'),
('OBS-PG04-R2','OBSERVATION','PG04 Reported cementitious intensity','CTY-IN'),
('OBS-PG04-R3','OBSERVATION','PG04 Reported second clinker intensity','CTY-IN'),
('OBS-PG04-D1','OBSERVATION','PG04 Derived blended clinker intensity','CTY-IN'),
('OBS-PG04-M1','OBSERVATION','PG04 Modelled future intensity','CTY-IN'),
('OBS-PG04-P1','OBSERVATION','PG04 Proxy intensity','CTY-IN'),
('OBS-PG04-U1','OBSERVATION','PG04 Unknown metric','CTY-IN'),
('OBS-PG04-Z1','OBSERVATION','PG04 Zero metric','CTY-IN'),
('OBS-PG04-S2L','OBSERVATION','PG04 Scope 2 LB','CTY-IN'),
('OBS-PG04-S2M','OBSERVATION','PG04 Scope 2 MB','CTY-IN'),
('OBS-PG04-FLOW','OBSERVATION','PG04 Material flow quantity','CTY-IN'),
('OBS-PG04-EPD','OBSERVATION','PG04 EPD result','CTY-IN'),
('PROD-PG04-0001','PRODUCT','PG04 Test Product','CTY-IN'),
('EPD-PG04-0001','EPD','PG04 Test EPD','CTY-IN');

INSERT INTO titan_core.source_document
(source_id,publisher_name,document_title,document_type_code,evidence_grade_code,publication_date,language_code,archival_status_code)
VALUES
('SRC-PG04-0001','Test Authority','Accounting method and plant disclosure','TECHNICAL_REPORT','P1',DATE '2026-01-01','en','LIVE_ONLY'),
('SRC-PG04-0002','Test EPD Programme','Synthetic EPD','EPD_PCR','P2',DATE '2026-02-01','en','LIVE_ONLY');

INSERT INTO titan_core.source_endpoint(endpoint_id,endpoint_url,endpoint_access_status_code) VALUES
('ENDP-PG04-0001','https://example.test/pg04/accounting','ACTIVE');

INSERT INTO titan_core.extraction_record
(extraction_id,source_id,location_ref,extracted_text,extracted_numeric_value,extracted_unit_text,extraction_method_code)
VALUES
('EXT-PG04-0001','SRC-PG04-0001','p.10 clinker intensity','0.80 tCO2e/t clinker',0.80,'tCO2e/t clinker','MANUAL'),
('EXT-PG04-0002','SRC-PG04-0001','p.11 cementitious intensity','0.65 tCO2e/t cementitious',0.65,'tCO2e/t cementitious','MANUAL'),
('EXT-PG04-0003','SRC-PG04-0002','A1-A3 GWP result','650 kgCO2e/t product',650,'kgCO2e/t product','MANUAL'),
('EXT-PG04-0004','SRC-PG04-0001','p.12 second clinker source','0.90 tCO2e/t clinker',0.90,'tCO2e/t clinker','MANUAL'),
('EXT-PG04-0005','SRC-PG04-0001','p.13 onsite clinker output','Onsite clinker output = 0 t',0,'t','MANUAL'),
('EXT-PG04-0006','SRC-PG04-0001','p.14 Scope 2 LB','Scope 2 location-based = 100 tCO2e',100,'tCO2e','MANUAL'),
('EXT-PG04-0007','SRC-PG04-0001','p.14 Scope 2 MB','Scope 2 market-based = 20 tCO2e',20,'tCO2e','MANUAL'),
('EXT-PG04-0008','SRC-PG04-0001','p.15 tender flow','Tender quantity = 150000 t',150000,'t','MANUAL');

INSERT INTO titan_core.methodology_master(methodology_id,methodology_family_code,methodology_name,authority_name)
VALUES
('METH-PG04-ACC','CEMENT_CO2_ENERGY','PG04 Test Cement Accounting','Test Authority'),
('METH-PG04-EPD','PRODUCT_LCA','PG04 Test EPD Method','Test EPD Programme');

INSERT INTO titan_core.methodology_version
(methodology_version_id,methodology_id,version_label,methodology_status_code,valid_from,source_id)
VALUES
('METHV-PG04-ACC-V1','METH-PG04-ACC','v1','CURRENT',DATE '2026-01-01','SRC-PG04-0001'),
('METHV-PG04-EPD-V1','METH-PG04-EPD','PCR-v1','CURRENT',DATE '2026-01-01','SRC-PG04-0002');

INSERT INTO titan_core.boundary_master(boundary_id,boundary_type_code,canonical_name,owner_entity_id)
VALUES
('BND-PG04-0001','PHYSICAL_SITE','PG04 Test Plant Boundary','PL-IN-KA-000006'),
('BND-PG04-0002','PHYSICAL_SITE','PG04 Comparison Plant Boundary','PL-IN-RJ-000002');

INSERT INTO titan_core.boundary_version(boundary_id,version_no,valid_from,methodology_ref,source_id)
VALUES
('BND-PG04-0001',1,DATE '2026-01-01','PG04 test boundary','SRC-PG04-0001'),
('BND-PG04-0002',1,DATE '2026-01-01','PG04 test comparison boundary','SRC-PG04-0001');

-- T001/T002: two reported intensities with different denominators can coexist but require evidence.
INSERT INTO titan_core.observation
(observation_id,subject_entity_id,metric_code,quantity_kind_code,value_state_code,data_class_code,numeric_value,unit_code,denominator_id,boundary_version_id,methodology_version_id,period_start,period_end)
SELECT 'OBS-PG04-R1','PL-IN-KA-000006','GHG_INTENSITY','INTENSITY','VALUE','R',0.80,'T_CO2E','DEN-CLINKER',boundary_version_id,'METHV-PG04-ACC-V1',DATE '2026-01-01',DATE '2026-12-31'
FROM titan_core.boundary_version WHERE boundary_id='BND-PG04-0001' AND version_no=1;

INSERT INTO titan_core.observation_evidence_link(observation_id,extraction_id,support_type_code)
VALUES ('OBS-PG04-R1','EXT-PG04-0001','SUPPORTS');

INSERT INTO titan_core.observation
(observation_id,subject_entity_id,metric_code,quantity_kind_code,value_state_code,data_class_code,numeric_value,unit_code,denominator_id,boundary_version_id,methodology_version_id,period_start,period_end)
SELECT 'OBS-PG04-R2','PL-IN-KA-000006','GHG_INTENSITY','INTENSITY','VALUE','R',0.65,'T_CO2E','DEN-CEMENTITIOUS',boundary_version_id,'METHV-PG04-ACC-V1',DATE '2026-01-01',DATE '2026-12-31'
FROM titan_core.boundary_version WHERE boundary_id='BND-PG04-0001' AND version_no=1;

INSERT INTO titan_core.observation_evidence_link(observation_id,extraction_id,support_type_code)
VALUES ('OBS-PG04-R2','EXT-PG04-0002','SUPPORTS');

INSERT INTO titan_core.observation
(observation_id,subject_entity_id,metric_code,quantity_kind_code,value_state_code,data_class_code,numeric_value,unit_code,denominator_id,boundary_version_id,methodology_version_id,period_start,period_end)
SELECT 'OBS-PG04-R3','PL-IN-GJ-000003','GHG_INTENSITY','INTENSITY','VALUE','R',0.90,'T_CO2E','DEN-CLINKER',boundary_version_id,'METHV-PG04-ACC-V1',DATE '2026-01-01',DATE '2026-12-31'
FROM titan_core.boundary_version WHERE boundary_id='BND-PG04-0002' AND version_no=1;

INSERT INTO titan_core.observation_evidence_link(observation_id,extraction_id,support_type_code)
VALUES ('OBS-PG04-R3','EXT-PG04-0004','SUPPORTS');

-- T003: reported VALUE without evidence must fail at constraint check.
DO $$
DECLARE caught boolean := false;
BEGIN
    BEGIN
        INSERT INTO titan_core.entity_registry(entity_id,entity_type_code,canonical_name,country_geo_id)
        VALUES ('OBS-PG04-BAD-R','OBSERVATION','Bad reported observation','CTY-IN');

        INSERT INTO titan_core.observation
        (observation_id,subject_entity_id,metric_code,quantity_kind_code,value_state_code,data_class_code,numeric_value,unit_code,period_start,period_end)
        VALUES ('OBS-PG04-BAD-R','PL-IN-KA-000006','TEST_METRIC','ABSOLUTE','VALUE','R',1,'TONNE',DATE '2026-01-01',DATE '2026-12-31');

        SET CONSTRAINTS ct_observation_provenance IMMEDIATE;
    EXCEPTION WHEN OTHERS THEN
        caught := true;
    END;
    SET CONSTRAINTS ct_observation_provenance DEFERRED;
    IF NOT caught THEN RAISE EXCEPTION 'PG04-T003 reported observation without evidence was not rejected'; END IF;
END;
$$;

-- T003B: non-value state cannot masquerade as R/D/M/P.
DO $$
DECLARE caught boolean := false;
BEGIN
    BEGIN
        INSERT INTO titan_core.entity_registry(entity_id,entity_type_code,canonical_name,country_geo_id)
        VALUES ('OBS-PG04-BAD-U','OBSERVATION','Bad unknown classification','CTY-IN');
        INSERT INTO titan_core.observation
        (observation_id,subject_entity_id,metric_code,quantity_kind_code,value_state_code,data_class_code,period_start,period_end)
        VALUES ('OBS-PG04-BAD-U','PL-IN-MP-000013','BAD_UNKNOWN','ABSOLUTE','NOT_PUBLICLY_VERIFIED','R',DATE '2026-01-01',DATE '2026-12-31');
    EXCEPTION WHEN check_violation THEN
        caught := true;
    END;
    IF NOT caught THEN RAISE EXCEPTION 'PG04-T003B non-value state with data class was not rejected'; END IF;
END;
$$;

-- T004: derived observation requires derivation + input.
INSERT INTO titan_core.observation
(observation_id,subject_entity_id,metric_code,quantity_kind_code,value_state_code,data_class_code,numeric_value,unit_code,denominator_id,period_start,period_end)
VALUES ('OBS-PG04-D1','PL-IN-UP-000018','BLENDED_CLINKER_INTENSITY','INTENSITY','VALUE','D',0.84,'T_CO2E','DEN-CLINKER',DATE '2026-01-01',DATE '2026-12-31');

INSERT INTO titan_core.observation_derivation(observation_id,formula_text,calculation_notes)
VALUES ('OBS-PG04-D1','weighted_average(input intensity, physical quantity)','Synthetic derivation');

INSERT INTO titan_core.observation_derivation_input(observation_id,input_observation_id,input_role) VALUES
('OBS-PG04-D1','OBS-PG04-R1','INPUT_INTENSITY_1'),
('OBS-PG04-D1','OBS-PG04-R3','INPUT_INTENSITY_2');

-- T004B: derived VALUE without derivation/input must fail.
DO $$
DECLARE caught boolean := false;
BEGIN
    BEGIN
        INSERT INTO titan_core.entity_registry(entity_id,entity_type_code,canonical_name,country_geo_id)
        VALUES ('OBS-PG04-BAD-D','OBSERVATION','Bad derived observation','CTY-IN');
        INSERT INTO titan_core.observation
        (observation_id,subject_entity_id,metric_code,quantity_kind_code,value_state_code,data_class_code,numeric_value,unit_code,period_start,period_end)
        VALUES ('OBS-PG04-BAD-D','PL-IN-UP-000018','BAD_DERIVED','ABSOLUTE','VALUE','D',1,'TONNE',DATE '2026-01-01',DATE '2026-12-31');
        SET CONSTRAINTS ct_observation_provenance IMMEDIATE;
    EXCEPTION WHEN OTHERS THEN
        caught := true;
    END;
    SET CONSTRAINTS ct_observation_provenance DEFERRED;
    IF NOT caught THEN RAISE EXCEPTION 'PG04-T004B derived observation without derivation provenance was not rejected'; END IF;
END;
$$;

-- T005: modelled observation requires model provenance.
INSERT INTO titan_core.observation
(observation_id,subject_entity_id,metric_code,quantity_kind_code,value_state_code,data_class_code,numeric_value,unit_code,denominator_id,period_start,period_end)
VALUES ('OBS-PG04-M1','PL-IN-KA-000006','FORECAST_GHG_INTENSITY','INTENSITY','VALUE','M',0.55,'T_CO2E','DEN-CEMENTITIOUS',DATE '2030-01-01',DATE '2030-12-31');

INSERT INTO titan_core.observation_model_provenance
(observation_id,model_ref,model_version_ref,assumption_set_ref,uncertainty_text)
VALUES ('OBS-PG04-M1','MODEL-CEMENT-NZ','v0.1','ASM-PG04-001','Synthetic only');

-- T005B: modelled VALUE without model provenance must fail.
DO $$
DECLARE caught boolean := false;
BEGIN
    BEGIN
        INSERT INTO titan_core.entity_registry(entity_id,entity_type_code,canonical_name,country_geo_id)
        VALUES ('OBS-PG04-BAD-M','OBSERVATION','Bad modelled observation','CTY-IN');
        INSERT INTO titan_core.observation
        (observation_id,subject_entity_id,metric_code,quantity_kind_code,value_state_code,data_class_code,numeric_value,unit_code,period_start,period_end)
        VALUES ('OBS-PG04-BAD-M','PL-IN-KA-000006','BAD_MODELLED','ABSOLUTE','VALUE','M',1,'TONNE',DATE '2026-01-01',DATE '2026-12-31');
        SET CONSTRAINTS ct_observation_provenance IMMEDIATE;
    EXCEPTION WHEN OTHERS THEN
        caught := true;
    END;
    SET CONSTRAINTS ct_observation_provenance DEFERRED;
    IF NOT caught THEN RAISE EXCEPTION 'PG04-T005B modelled observation without model provenance was not rejected'; END IF;
END;
$$;

-- T006: proxy observation requires source observation + rationale.
INSERT INTO titan_core.observation
(observation_id,subject_entity_id,metric_code,quantity_kind_code,value_state_code,data_class_code,numeric_value,unit_code,denominator_id,period_start,period_end)
VALUES ('OBS-PG04-P1','PL-IN-MP-000013','PROXY_GHG_INTENSITY','INTENSITY','VALUE','P',0.80,'T_CO2E','DEN-CLINKER',DATE '2026-01-01',DATE '2026-12-31');

INSERT INTO titan_core.observation_proxy_provenance
(observation_id,proxy_source_observation_id,proxy_rationale,uncertainty_text)
VALUES ('OBS-PG04-P1','OBS-PG04-R1','Synthetic comparable plant proxy for schema test','High uncertainty; not a plant fact');

-- T006B: proxy VALUE without proxy source/rationale must fail.
DO $$
DECLARE caught boolean := false;
BEGIN
    BEGIN
        INSERT INTO titan_core.entity_registry(entity_id,entity_type_code,canonical_name,country_geo_id)
        VALUES ('OBS-PG04-BAD-P','OBSERVATION','Bad proxy observation','CTY-IN');
        INSERT INTO titan_core.observation
        (observation_id,subject_entity_id,metric_code,quantity_kind_code,value_state_code,data_class_code,numeric_value,unit_code,period_start,period_end)
        VALUES ('OBS-PG04-BAD-P','PL-IN-MP-000013','BAD_PROXY','ABSOLUTE','VALUE','P',1,'TONNE',DATE '2026-01-01',DATE '2026-12-31');
        SET CONSTRAINTS ct_observation_provenance IMMEDIATE;
    EXCEPTION WHEN OTHERS THEN
        caught := true;
    END;
    SET CONSTRAINTS ct_observation_provenance DEFERRED;
    IF NOT caught THEN RAISE EXCEPTION 'PG04-T006B proxy observation without proxy provenance was not rejected'; END IF;
END;
$$;

-- T007: UNKNOWN has no fabricated numeric payload and needs no data class.
INSERT INTO titan_core.observation
(observation_id,subject_entity_id,metric_code,quantity_kind_code,value_state_code,period_start,period_end)
VALUES ('OBS-PG04-U1','PL-IN-MP-000013','UNKNOWN_TEST','ABSOLUTE','NOT_PUBLICLY_VERIFIED',DATE '2026-01-01',DATE '2026-12-31');

-- T008: ZERO must be numeric zero.
INSERT INTO titan_core.observation
(observation_id,subject_entity_id,metric_code,quantity_kind_code,value_state_code,data_class_code,numeric_value,unit_code,period_start,period_end)
VALUES ('OBS-PG04-Z1','PL-IN-UP-000018','ONSITE_CLINKER_OUTPUT','ABSOLUTE','ZERO','R',0,'TONNE',DATE '2026-01-01',DATE '2026-12-31');

INSERT INTO titan_core.observation_evidence_link(observation_id,extraction_id,support_type_code)
VALUES ('OBS-PG04-Z1','EXT-PG04-0005','SUPPORTS');

-- T009: non-zero payload with ZERO must fail.
DO $$
DECLARE caught boolean := false;
BEGIN
    BEGIN
        INSERT INTO titan_core.entity_registry(entity_id,entity_type_code,canonical_name,country_geo_id)
        VALUES ('OBS-PG04-BAD-Z','OBSERVATION','Bad zero observation','CTY-IN');
        INSERT INTO titan_core.observation
        (observation_id,subject_entity_id,metric_code,quantity_kind_code,value_state_code,data_class_code,numeric_value,unit_code,period_start,period_end)
        VALUES ('OBS-PG04-BAD-Z','PL-IN-UP-000018','BAD_ZERO','ABSOLUTE','ZERO','R',1,'TONNE',DATE '2026-01-01',DATE '2026-12-31');
    EXCEPTION WHEN check_violation THEN
        caught := true;
    END;
    IF NOT caught THEN RAISE EXCEPTION 'PG04-T009 non-zero ZERO state was not rejected'; END IF;
END;
$$;

-- T010: intensity without denominator must fail.
DO $$
DECLARE caught boolean := false;
BEGIN
    BEGIN
        INSERT INTO titan_core.entity_registry(entity_id,entity_type_code,canonical_name,country_geo_id)
        VALUES ('OBS-PG04-BAD-DEN','OBSERVATION','Bad denominator observation','CTY-IN');
        INSERT INTO titan_core.observation
        (observation_id,subject_entity_id,metric_code,quantity_kind_code,value_state_code,data_class_code,numeric_value,unit_code,period_start,period_end)
        VALUES ('OBS-PG04-BAD-DEN','PL-IN-KA-000006','BAD_INTENSITY','INTENSITY','VALUE','R',0.7,'T_CO2E',DATE '2026-01-01',DATE '2026-12-31');
    EXCEPTION WHEN check_violation THEN
        caught := true;
    END;
    IF NOT caught THEN RAISE EXCEPTION 'PG04-T010 intensity without denominator was not rejected'; END IF;
END;
$$;

-- T011: Scope 2 LB and MB can coexist as distinct components.
INSERT INTO titan_core.observation
(observation_id,subject_entity_id,metric_code,quantity_kind_code,value_state_code,data_class_code,numeric_value,unit_code,boundary_version_id,methodology_version_id,period_start,period_end)
SELECT 'OBS-PG04-S2L','PL-IN-KA-000006','SCOPE2_LB','ABSOLUTE','VALUE','R',100,'T_CO2E',boundary_version_id,'METHV-PG04-ACC-V1',DATE '2026-01-01',DATE '2026-12-31'
FROM titan_core.boundary_version WHERE boundary_id='BND-PG04-0001' AND version_no=1
UNION ALL
SELECT 'OBS-PG04-S2M','PL-IN-KA-000006','SCOPE2_MB','ABSOLUTE','VALUE','R',20,'T_CO2E',boundary_version_id,'METHV-PG04-ACC-V1',DATE '2026-01-01',DATE '2026-12-31'
FROM titan_core.boundary_version WHERE boundary_id='BND-PG04-0001' AND version_no=1;

INSERT INTO titan_core.observation_evidence_link(observation_id,extraction_id,support_type_code)
VALUES
('OBS-PG04-S2L','EXT-PG04-0006','SUPPORTS'),
('OBS-PG04-S2M','EXT-PG04-0007','SUPPORTS');

INSERT INTO titan_core.inventory_master
(inventory_id,boundary_version_id,methodology_version_id,period_start,period_end,inventory_type_code,inventory_version_status_code)
SELECT 'INV-PG04-ORIG',boundary_version_id,'METHV-PG04-ACC-V1',DATE '2026-01-01',DATE '2026-12-31','PLANT','ORIGINAL'
FROM titan_core.boundary_version WHERE boundary_id='BND-PG04-0001' AND version_no=1;

INSERT INTO titan_core.inventory_component
(inventory_component_id,inventory_id,observation_id,inventory_component_type_code,gross_net_role_code)
VALUES
('INVC-PG04-LB','INV-PG04-ORIG','OBS-PG04-S2L','SCOPE2_LB','GROSS'),
('INVC-PG04-MB','INV-PG04-ORIG','OBS-PG04-S2M','SCOPE2_MB','GROSS');

-- T011B: component from another boundary cannot enter this inventory.
DO $$
DECLARE caught boolean := false;
BEGIN
    BEGIN
        INSERT INTO titan_core.inventory_component
        (inventory_component_id,inventory_id,observation_id,inventory_component_type_code,gross_net_role_code)
        VALUES ('INVC-PG04-BAD','INV-PG04-ORIG','OBS-PG04-R3','PROCESS_CO2','GROSS');
    EXCEPTION WHEN OTHERS THEN
        caught := true;
    END;
    IF NOT caught THEN RAISE EXCEPTION 'PG04-T011B inventory component context mismatch was not rejected'; END IF;
END;
$$;

-- T012: restated inventory coexists with original and keeps reason.
INSERT INTO titan_core.inventory_master
(inventory_id,boundary_version_id,methodology_version_id,period_start,period_end,inventory_type_code,inventory_version_status_code,supersedes_inventory_id,restatement_reason)
SELECT 'INV-PG04-RESTATED',boundary_version_id,'METHV-PG04-ACC-V1',DATE '2026-01-01',DATE '2026-12-31','PLANT','RESTATED','INV-PG04-ORIG','Synthetic acquisition/perimeter restatement'
FROM titan_core.boundary_version WHERE boundary_id='BND-PG04-0001' AND version_no=1;

-- T013: product composition cannot exceed 100%.
INSERT INTO titan_core.material_master(material_id,material_name,material_class) VALUES
('MAT-PG04-CLINKER','Clinker','CLINKER'),
('MAT-PG04-SLAG','Slag','SCM');

INSERT INTO titan_core.product_master(product_id,product_name,product_category)
VALUES ('PROD-PG04-0001','PG04 Test Cement','CEMENT');

INSERT INTO titan_core.product_version(product_version_id,product_id,version_label,product_version_status_code,valid_from)
VALUES ('PRODV-PG04-0001','PROD-PG04-0001','2026 formulation','CURRENT',DATE '2026-01-01');

INSERT INTO titan_core.product_composition(product_composition_id,product_version_id,material_id,mass_share)
VALUES
('COMP-PG04-001','PRODV-PG04-0001','MAT-PG04-CLINKER',0.70),
('COMP-PG04-002','PRODV-PG04-0001','MAT-PG04-SLAG',0.30);

SET CONSTRAINTS ct_product_composition_total IMMEDIATE;
SET CONSTRAINTS ct_product_composition_total DEFERRED;

DO $$
DECLARE caught boolean := false;
BEGIN
    BEGIN
        INSERT INTO titan_core.material_master(material_id,material_name,material_class)
        VALUES ('MAT-PG04-LIMESTONE','Limestone','SCM');
        INSERT INTO titan_core.product_composition(product_composition_id,product_version_id,material_id,mass_share)
        VALUES ('COMP-PG04-003','PRODV-PG04-0001','MAT-PG04-LIMESTONE',0.10);
        SET CONSTRAINTS ct_product_composition_total IMMEDIATE;
    EXCEPTION WHEN OTHERS THEN
        caught := true;
    END;
    SET CONSTRAINTS ct_product_composition_total DEFERRED;
    IF NOT caught THEN RAISE EXCEPTION 'PG04-T013 product composition over 100% was not rejected'; END IF;
END;
$$;

-- T014: tender material flow remains explicitly non-actual.
INSERT INTO titan_core.observation
(observation_id,subject_entity_id,metric_code,quantity_kind_code,value_state_code,data_class_code,numeric_value,unit_code,period_start,period_end)
VALUES ('OBS-PG04-FLOW','PL-CN-AH-000019','MATERIAL_FLOW_QUANTITY','ABSOLUTE','VALUE','R',150000,'TONNE',DATE '2026-01-01',DATE '2026-12-31');

INSERT INTO titan_core.observation_evidence_link(observation_id,extraction_id,support_type_code)
VALUES ('OBS-PG04-FLOW','EXT-PG04-0008','SUPPORTS');

INSERT INTO titan_core.material_flow
(material_flow_id,material_id,origin_entity_id,destination_entity_id,quantity_observation_id,material_flow_status_code,cross_border_flag,flow_notes)
VALUES ('FLOW-PG04-001','MAT-PG04-SLAG','PL-CN-AH-000004','PL-CN-AH-000019','OBS-PG04-FLOW','TENDER',false,'Synthetic tender quantity; not actual use');

-- T015: EPD member + EPD result use exact product/version and observation.
INSERT INTO titan_core.epd_master
(epd_id,source_id,programme_name,registration_number,epd_type_code,valid_from,valid_to,pcr_version_ref,gpi_version_ref,declared_or_functional_unit,lifecycle_scope)
VALUES ('EPD-PG04-0001','SRC-PG04-0002','Test Programme','EPD-PG04-REG-001','PLANT_SPECIFIC',DATE '2026-02-01',DATE '2031-01-31','PCR-v1','GPI-v1','1 tonne cement','A1-A3');

INSERT INTO titan_core.epd_member(epd_member_id,epd_id,product_version_id,weighting_method,weighting_share)
VALUES ('EPM-PG04-001','EPD-PG04-0001','PRODV-PG04-0001','SINGLE_PRODUCT',1.0);

INSERT INTO titan_core.observation
(observation_id,subject_entity_id,metric_code,quantity_kind_code,value_state_code,data_class_code,numeric_value,unit_code,denominator_id,methodology_version_id,period_start,period_end)
VALUES ('OBS-PG04-EPD','PROD-PG04-0001','EPD_GWP_A1_A3','INTENSITY','VALUE','R',650,'KG_CO2E','DEN-PRODUCT-MASS','METHV-PG04-EPD-V1',DATE '2025-01-01',DATE '2025-12-31');

INSERT INTO titan_core.observation_evidence_link(observation_id,extraction_id,support_type_code)
VALUES ('OBS-PG04-EPD','EXT-PG04-0003','SUPPORTS');

INSERT INTO titan_core.epd_result(epd_result_id,epd_id,observation_id,indicator_code,impact_method_version,lifecycle_module)
VALUES ('EPDR-PG04-001','EPD-PG04-0001','OBS-PG04-EPD','GWP-GHG','Test impact method v1','A1-A3');

-- T016/T017: comparability distinguishes denominator mismatch.
INSERT INTO titan_core.comparability_rule
(comparability_rule_id,metric_family,rule_version,required_same_fields,prohibited_mixes,rule_notes)
VALUES
('CMP-RULE-PG04-GHG','CO2_INTENSITY','v1',
 '["unit_code","denominator_id","methodology_version_id","quantity_kind_code"]'::jsonb,
 '["GROSS_vs_NET","SCOPE2_LB_vs_MB"]'::jsonb,
 'Synthetic structural rule');

INSERT INTO titan_core.comparison_result
(comparison_id,comparability_rule_id,observation_a_id,observation_b_id,comparability_result_code,failure_reason_codes,analytical_purpose)
VALUES
('CMPR-PG04-001','CMP-RULE-PG04-GHG','OBS-PG04-R1','OBS-PG04-R2','NOT_COMPARABLE','["DENOMINATOR_MISMATCH"]'::jsonb,'Test clinker vs cementitious intensity');

INSERT INTO titan_core.entity_registry(entity_id,entity_type_code,canonical_name,country_geo_id)
VALUES ('OBS-PG04-R1B','OBSERVATION','PG04 Same-basis intensity','CTY-IN');

INSERT INTO titan_core.observation
(observation_id,subject_entity_id,metric_code,quantity_kind_code,value_state_code,data_class_code,numeric_value,unit_code,denominator_id,boundary_version_id,methodology_version_id,period_start,period_end)
SELECT 'OBS-PG04-R1B','PL-IN-RJ-000002','GHG_INTENSITY','INTENSITY','VALUE','R',0.82,'T_CO2E','DEN-CLINKER',boundary_version_id,'METHV-PG04-ACC-V1',DATE '2026-01-01',DATE '2026-12-31'
FROM titan_core.boundary_version WHERE boundary_id='BND-PG04-0002' AND version_no=1;

INSERT INTO titan_core.observation_evidence_link(observation_id,extraction_id,support_type_code)
VALUES ('OBS-PG04-R1B','EXT-PG04-0001','QUALIFIES');

INSERT INTO titan_core.comparison_result
(comparison_id,comparability_rule_id,observation_a_id,observation_b_id,comparability_result_code,failure_reason_codes,analytical_purpose)
VALUES
('CMPR-PG04-002','CMP-RULE-PG04-GHG','OBS-PG04-R1','OBS-PG04-R1B','COMPARABLE','[]'::jsonb,'Test same-basis plant intensity comparison');

-- T017B/T017C: machine-readable basic comparison gate.
DO $$
DECLARE r text;
BEGIN
    SELECT titan_core.basic_observation_comparability('OBS-PG04-R1','OBS-PG04-R2') INTO r;
    IF r <> 'DENOMINATOR_MISMATCH' THEN
        RAISE EXCEPTION 'PG04-T017B expected DENOMINATOR_MISMATCH, got %', r;
    END IF;

    SELECT titan_core.basic_observation_comparability('OBS-PG04-R1','OBS-PG04-R1B') INTO r;
    IF r <> 'LIKE_FOR_LIKE' THEN
        RAISE EXCEPTION 'PG04-T017C expected LIKE_FOR_LIKE, got %', r;
    END IF;
END;
$$;

-- T018: conditionally comparable requires normalization.
DO $$
DECLARE caught boolean := false;
BEGIN
    BEGIN
        INSERT INTO titan_core.comparison_result
        (comparison_id,comparability_rule_id,observation_a_id,observation_b_id,comparability_result_code,analytical_purpose)
        VALUES ('CMPR-PG04-BAD','CMP-RULE-PG04-GHG','OBS-PG04-R1','OBS-PG04-R2','CONDITIONALLY_COMPARABLE','Missing normalization test');
    EXCEPTION WHEN check_violation THEN
        caught := true;
    END;
    IF NOT caught THEN RAISE EXCEPTION 'PG04-T018 conditional comparison without normalization was not rejected'; END IF;
END;
$$;

-- Force all deferred provenance/composition controls now.
SET CONSTRAINTS ALL IMMEDIATE;

-- Final control counts.
DO $$
DECLARE n_reported integer;
DECLARE n_components integer;
DECLARE n_inventory_versions integer;
DECLARE n_comparisons integer;
DECLARE flow_actual boolean;
BEGIN
    SELECT count(*) INTO n_reported
    FROM titan_core.observation
    WHERE data_class_code='R'
      AND observation_id LIKE 'OBS-PG04-%';

    SELECT count(*) INTO n_components
    FROM titan_core.inventory_component
    WHERE inventory_id='INV-PG04-ORIG';

    SELECT count(*) INTO n_inventory_versions
    FROM titan_core.inventory_master
    WHERE inventory_id IN ('INV-PG04-ORIG','INV-PG04-RESTATED');

    SELECT count(*) INTO n_comparisons
    FROM titan_core.comparison_result
    WHERE comparison_id IN ('CMPR-PG04-001','CMPR-PG04-002');

    SELECT actual_flow_flag INTO flow_actual
    FROM titan_ref.material_flow_status
    WHERE material_flow_status_code='TENDER';

    IF n_reported < 7 THEN RAISE EXCEPTION 'PG04-T019 expected reported observation fixtures'; END IF;
    IF n_components <> 2 THEN RAISE EXCEPTION 'PG04-T020 expected both Scope 2 methods as distinct components'; END IF;
    IF n_inventory_versions <> 2 THEN RAISE EXCEPTION 'PG04-T021 expected original and restated inventory versions'; END IF;
    IF n_comparisons <> 2 THEN RAISE EXCEPTION 'PG04-T022 expected two comparison results'; END IF;
    IF flow_actual IS DISTINCT FROM false THEN RAISE EXCEPTION 'PG04-T023 TENDER must remain non-actual'; END IF;
END;
$$;

ROLLBACK;

\echo 'PG-04 observation/accounting tests passed if execution reached this line.'
