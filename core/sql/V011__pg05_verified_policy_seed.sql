-- PG-05 verified regulatory source/policy seed
-- Current verification cut-off: 2026-08-29.
-- India: principal cement targets remain bound to G.S.R. 739(E), 8 Oct 2025.
-- Amendment G.S.R. 25(E), 13 Jan 2026 is retained separately and does not overwrite
-- the five pilot cement target rows absent a specific amendment to those registrations.
-- China: 2026 allocation plan remains APPROVED_IN_PRINCIPLE, not PROMULGATED at cut-off.
BEGIN;

-- Source identities.
INSERT INTO titan_core.entity_registry(entity_id,entity_type_code,canonical_name,country_geo_id) VALUES
('SRC-PG05-IN-GEI-2025','SOURCE','India GHG Emission Intensity Target Rules 2025','CTY-IN'),
('SRC-PG05-IN-DPROC','SOURCE','India CCTS Detailed Compliance Procedure','CTY-IN'),
('SRC-PG05-IN-AMEND-2026','SOURCE','India GHG Intensity Target Amendment Rules 2025 — Jan 2026','CTY-IN'),
('SRC-PG05-CN-ALLOC-2425','SOURCE','China ETS 2024/2025 Steel Cement Aluminium Allocation Plan — Final','CTY-CN'),
('SRC-PG05-CN-WORK-2026','SOURCE','China ETS 2026 Work Notice','CTY-CN'),
('SRC-PG05-CN-ALLOC-2026-CONS','SOURCE','China ETS 2026 Allocation Plan — Consultation','CTY-CN'),
('SRC-PG05-CN-ALLOC-2026-MTG','SOURCE','MEE Executive Meeting — 2026 Allocation Plan Approved in Principle','CTY-CN');

INSERT INTO titan_core.source_document
(source_id,publisher_name,document_title,document_type_code,evidence_grade_code,publication_date,language_code,mime_type,archival_status_code,authoritative_status,source_notes)
VALUES
('SRC-PG05-IN-GEI-2025','Ministry of Environment, Forest and Climate Change / BEE','Greenhouse Gases Emission Intensity Target Rules, 2025','REGULATORY_NOTICE','P1',DATE '2025-10-08','en','application/pdf','LIVE_ONLY','PROMULGATED','Principal rules including cement First Schedule and CCC formulas.'),
('SRC-PG05-IN-DPROC','Bureau of Energy Efficiency','Detailed Procedure for Compliance Mechanism under the Indian Carbon Market','TECHNICAL_REPORT','P1',NULL,'en','application/pdf','LIVE_ONLY','PROCEDURE','Compliance workflow, verification, surrender and banking procedure.'),
('SRC-PG05-IN-AMEND-2026','Ministry of Environment, Forest and Climate Change','Greenhouse Gases Emission Intensity Target (Amendment) Rules, 2025 — G.S.R. 25(E)','REGULATORY_NOTICE','P1',DATE '2026-01-13','en','application/pdf','LIVE_ONLY','PROMULGATED','Adds Second Schedule for additional sectors and modifies notes; retained separately from principal cement schedule.'),
('SRC-PG05-CN-ALLOC-2425','Ministry of Ecology and Environment','2024/2025 National ETS Steel, Cement and Aluminium Allocation Plan','REGULATORY_NOTICE','P1',DATE '2025-11-17','zh','application/pdf','LIVE_ONLY','PROMULGATED','Final plan; 2024 verified-emissions allocation and 2025 line-level cement performance adjustment.'),
('SRC-PG05-CN-WORK-2026','Ministry of Ecology and Environment','Notice on 2026 National ETS Work','GOVERNMENT_WEBPAGE','P1',DATE '2026-02-09','zh','text/html','LIVE_ONLY','EFFECTIVE','2026 data-quality, list, allocation and surrender timetable; 26,000 tCO2e threshold context.'),
('SRC-PG05-CN-ALLOC-2026-CONS','Ministry of Ecology and Environment','2026 Steel, Cement and Aluminium Allocation Plan — Consultation Draft','GOVERNMENT_WEBPAGE','P1',DATE '2026-07-27','zh','text/html','LIVE_ONLY','CONSULTATION','Draft only; no final production formula may bind to this version.'),
('SRC-PG05-CN-ALLOC-2026-MTG','Ministry of Ecology and Environment','MEE Executive Meeting — 2026 Allocation Plan','GOVERNMENT_WEBPAGE','P1',DATE '2026-08-24','zh','text/html','LIVE_ONLY','APPROVED_IN_PRINCIPLE','Executive meeting approved 2026 allocation plan in principle; formal promulgation not yet verified.');

INSERT INTO titan_core.source_endpoint(endpoint_id,endpoint_url,endpoint_access_status_code) VALUES
('ENDP-PG05-IN-GEI','https://beeindia.gov.in/sites/default/files/Greenhouse_Gases_Emission_Intensity_Target_Rules_2025.pdf','ACTIVE'),
('ENDP-PG05-IN-DPROC','https://beeindia.gov.in/sites/default/files/2024-07/Detailed%20Procedure%20for%20Compliance%20Procedure%20under%20CCTS.pdf','ACTIVE'),
('ENDP-PG05-IN-AMEND','https://egazette.gov.in/WriteReadData/2026/269375.pdf','ACTIVE'),
('ENDP-PG05-CN-ALLOC-2425','https://www.mee.gov.cn/xxgk2018/xxgk/xxgk03/202511/W020251118634892868994.pdf','ACTIVE'),
('ENDP-PG05-CN-WORK-2026','https://www.mee.gov.cn/xxgk2018/xxgk/xxgk06/202602/t20260209_1143900.html','ACTIVE'),
('ENDP-PG05-CN-ALLOC-2026-CONS','https://www.mee.gov.cn/xxgk2018/xxgk/xxgk06/202607/t20260727_1162839.html','ACTIVE'),
('ENDP-PG05-CN-ALLOC-2026-MTG','https://www.mee.gov.cn/ywdt/hjywnews/202608/t20260824_1164432.shtml','ACTIVE');

-- Exact extractions/locators used by PG-05.
INSERT INTO titan_core.extraction_record
(extraction_id,source_id,location_ref,extracted_text,extracted_numeric_value,extracted_unit_text,extraction_method_code,reviewer_ref,extraction_confidence)
VALUES
('EXT-PG05-IN-FORMULA','SRC-PG05-IN-GEI-2025','Rule 5(2)-(4)','CCC issue=(target-achieved)*equivalent product; purchase=(achieved-target)*equivalent product; issued or purchased CCC may be banked.',NULL,NULL,'MANUAL','PG05 policy verification',1.0),
('EXT-PG05-IN-KOT','SRC-PG05-IN-GEI-2025','First Schedule — Cement — CMTOE085RJ','CMTOE085RJ | baseline output 3666138 | baseline GEI 0.8086 | FY2025-26 0.8032 | FY2026-27 0.7891',3666138,'t equivalent product','MANUAL','PG05 policy verification',1.0),
('EXT-PG05-IN-JAF','SRC-PG05-IN-GEI-2025','First Schedule — Cement — CMTOE087GJ','CMTOE087GJ | baseline output 1400465 | baseline GEI 0.7994 | FY2025-26 0.7935 | FY2026-27 0.7783',1400465,'t equivalent product','MANUAL','PG05 policy verification',1.0),
('EXT-PG05-IN-MAI','SRC-PG05-IN-GEI-2025','First Schedule — Cement — CMTOE019MP','CMTOE019MP | baseline output 5390695 | baseline GEI 0.5923 | FY2025-26 0.5885 | FY2026-27 0.5788',5390695,'t equivalent product','MANUAL','PG05 policy verification',1.0),
('EXT-PG05-IN-KUN','SRC-PG05-IN-GEI-2025','First Schedule — Cement grinding — CGUOE005UP','CGUOE005UP | baseline output 2787464 | baseline GEI 0.0128 | no FY2025-26 target | FY2026-27 0.0125',2787464,'t equivalent product','MANUAL','PG05 policy verification',1.0),
('EXT-PG05-IN-MUD','SRC-PG05-IN-GEI-2025','First Schedule — Cement — CMTOE001KA','CMTOE001KA | baseline output 3532948 | baseline GEI 0.4455 | FY2025-26 0.4440 | FY2026-27 0.4402',3532948,'t equivalent product','MANUAL','PG05 policy verification',1.0),
('EXT-PG05-CN-SCOPE','SRC-PG05-CN-ALLOC-2425','Allocation plan pp.4-5 / scope section','Cement covers direct CO2 emissions; purchased electricity/heat indirect emissions are outside current allocation scope.',NULL,NULL,'MANUAL','PG05 policy verification',1.0),
('EXT-PG05-CN-FORMULA','SRC-PG05-CN-ALLOC-2425','Allocation plan pp.5-8 / formula and Table 1','2024 allocation equals verified emissions. 2025 cement allocation is calculated by clinker production line: A=E*(1+alpha); X=(B-I)/B; alpha=0.15X for -20%<X<20%, +0.03 for X>=20%, -0.03 for X<=-20%.',NULL,NULL,'MANUAL','PG05 policy verification',1.0),
('EXT-PG05-CN-ELIG','SRC-PG05-CN-ALLOC-2425','Allocation plan scope/eligibility','Lines closed before final allocation and newly commissioned lines in the relevant year are excluded; specified special clinker lines receive verified-emissions allocation in 2025.',NULL,NULL,'MANUAL','PG05 policy verification',1.0);

-- Schemes and policy versions.
INSERT INTO titan_core.carbon_scheme
(scheme_id,scheme_name,scheme_type_code,jurisdiction_geo_id,governing_authority_name,instrument_unit_label,scheme_notes)
VALUES
('SCHEME-IN-CCTS','India Carbon Credit Trading Scheme — Compliance Mechanism','INTENSITY_CREDIT','CTY-IN','Bureau of Energy Efficiency / MoEFCC','CCC','Annual GHG emission-intensity target mechanism for obligated entities.'),
('SCHEME-CN-ETS','China National Carbon Emissions Trading Market','ETS','CTY-CN','Ministry of Ecology and Environment','CEA / tCO2e','National ETS; cement allocation is line-based under the final 2024/2025 plan.');

INSERT INTO titan_core.policy_version
(policy_version_id,scheme_id,legal_title,legal_citation,publication_date,effective_from,primary_source_id,policy_notes)
VALUES
('POLV-IN-CCTS-GEI-2025','SCHEME-IN-CCTS','Greenhouse Gases Emission Intensity Target Rules, 2025','G.S.R. 739(E)',DATE '2025-10-08',DATE '2025-10-08','SRC-PG05-IN-GEI-2025','Principal cement target schedule.'),
('POLV-IN-CCTS-GEI-AM1','SCHEME-IN-CCTS','Greenhouse Gases Emission Intensity Target (Amendment) Rules, 2025','G.S.R. 25(E)',DATE '2026-01-13',DATE '2026-01-13','SRC-PG05-IN-AMEND-2026','Adds Second Schedule/additional sectors; stored as an amendment, not as silent overwrite of cement target rows.'),
('POLV-CN-ETS-ALLOC-2425','SCHEME-CN-ETS','2024/2025 National ETS Steel, Cement and Aluminium Allocation Plan','国环规气候〔2025〕2号',DATE '2025-11-17',DATE '2025-11-17','SRC-PG05-CN-ALLOC-2425','Final governing 2024/2025 allocation plan.'),
('POLV-CN-ETS-WORK-2026','SCHEME-CN-ETS','Notice on 2026 National ETS Work','环办气候函〔2026〕32号',DATE '2026-02-09',DATE '2026-02-09','SRC-PG05-CN-WORK-2026','Implementation calendar and 2027 list threshold context.'),
('POLV-CN-ETS-ALLOC-2026','SCHEME-CN-ETS','2026 Steel, Cement and Aluminium Allocation Plan — policy lifecycle','Consultation released 2026-07-27',DATE '2026-07-27',NULL,'SRC-PG05-CN-ALLOC-2026-CONS','Current status at 2026-08-29: APPROVED_IN_PRINCIPLE, not formally promulgated.');

INSERT INTO titan_core.policy_status_history
(policy_status_history_id,policy_version_id,policy_status_code,valid_from,valid_to,source_id,status_notes)
VALUES
('POLSTAT-IN-GEI-2025-EFF','POLV-IN-CCTS-GEI-2025','EFFECTIVE',DATE '2025-10-08',NULL,'SRC-PG05-IN-GEI-2025','Principal rules effective upon Gazette publication.'),
('POLSTAT-IN-GEI-AM1-EFF','POLV-IN-CCTS-GEI-AM1','EFFECTIVE',DATE '2026-01-13',NULL,'SRC-PG05-IN-AMEND-2026','Amendment effective upon Gazette publication.'),
('POLSTAT-CN-2425-FINAL','POLV-CN-ETS-ALLOC-2425','EFFECTIVE',DATE '2025-11-17',NULL,'SRC-PG05-CN-ALLOC-2425','Final allocation plan.'),
('POLSTAT-CN-WORK26-EFF','POLV-CN-ETS-WORK-2026','EFFECTIVE',DATE '2026-02-09',NULL,'SRC-PG05-CN-WORK-2026','2026 implementation notice.'),
('POLSTAT-CN-ALLOC26-CONS','POLV-CN-ETS-ALLOC-2026','CONSULTATION',DATE '2026-07-27',DATE '2026-08-23','SRC-PG05-CN-ALLOC-2026-CONS','Public consultation stage.'),
('POLSTAT-CN-ALLOC26-AIP','POLV-CN-ETS-ALLOC-2026','APPROVED_IN_PRINCIPLE',DATE '2026-08-24',NULL,'SRC-PG05-CN-ALLOC-2026-MTG','MEE executive meeting approved the scheme in principle; formal issuance not yet verified.');

INSERT INTO titan_core.policy_version_relationship
(policy_version_relationship_id,from_policy_version_id,to_policy_version_id,policy_relationship_type_code,source_id,relationship_notes)
VALUES
('POLREL-IN-AM1-BASE','POLV-IN-CCTS-GEI-AM1','POLV-IN-CCTS-GEI-2025','AMENDS','SRC-PG05-IN-AMEND-2026','Amendment inserts Second Schedule/additional sectors; principal cement First Schedule remains independently traceable.'),
('POLREL-CN-WORK26-2425','POLV-CN-ETS-WORK-2026','POLV-CN-ETS-ALLOC-2425','IMPLEMENTS','SRC-PG05-CN-WORK-2026','2026 work notice administers verification/allocation/surrender work for prior-year emissions and current market operations.');

INSERT INTO titan_core.policy_formula_rule
(policy_rule_id,policy_version_id,rule_code,rule_title,rule_expression,parameter_schema,source_location_ref,source_id)
VALUES
('POLRULE-IN-CCTS-ISSUE','POLV-IN-CCTS-GEI-2025','CCC_ISSUE','CCC issuance for over-achievement','max((target_gei-achieved_gei)*equivalent_output,0)','{"target_gei":"numeric","achieved_gei":"numeric","equivalent_output":"tonne"}'::jsonb,'Rule 5(2)','SRC-PG05-IN-GEI-2025'),
('POLRULE-IN-CCTS-SHORT','POLV-IN-CCTS-GEI-2025','CCC_SHORTFALL','CCC required for shortfall','max((achieved_gei-target_gei)*equivalent_output,0)','{"target_gei":"numeric","achieved_gei":"numeric","equivalent_output":"tonne"}'::jsonb,'Rule 5(3)','SRC-PG05-IN-GEI-2025'),
('POLRULE-IN-CCTS-BANK','POLV-IN-CCTS-GEI-2025','CCC_BANK','CCC banking','issued_or_purchased_CCC may be banked subject to detailed procedure','{}'::jsonb,'Rule 5(4)','SRC-PG05-IN-GEI-2025'),
('POLRULE-CN-CEM-2024','POLV-CN-ETS-ALLOC-2425','CEMENT_2024','2024 cement allowance','A=E for eligible covered unit','{"E":"verified tCO2e","eligible":"boolean"}'::jsonb,'Allocation plan, allocation method','SRC-PG05-CN-ALLOC-2425'),
('POLRULE-CN-CEM-2025','POLV-CN-ETS-ALLOC-2425','CEMENT_2025_STANDARD','2025 cement standard clinker-line allowance','A=E*(1+alpha); X=(B-I)/B; alpha=0.15X if -20%<X<20%, +0.03 if X>=20%, -0.03 if X<=-20%','{"E":"verified tCO2e","output":"t clinker","B":"industry balance tCO2e/t clinker","eligible":"boolean"}'::jsonb,'Allocation plan pp.5-8, Table 1','SRC-PG05-CN-ALLOC-2425'),
('POLRULE-CN-CEM-2025-SPECIAL','POLV-CN-ETS-ALLOC-2425','CEMENT_2025_SPECIAL','2025 special cement-line allowance','A=E for eligible specified special clinker lines','{"E":"verified tCO2e","eligible":"boolean"}'::jsonb,'Allocation plan pp.4-5','SRC-PG05-CN-ALLOC-2425'),
('POLRULE-CN-THRESHOLD-2027','POLV-CN-ETS-WORK-2026','KEY_EMITTER_THRESHOLD','2027 key-emitter list threshold','annual direct emissions >= 26000 tCO2e for power, steel, cement and aluminium','{"threshold_tCO2e":26000,"emissions_scope":"annual direct"}'::jsonb,'2026 work notice §1(1)','SRC-PG05-CN-WORK-2026');

-- India pilot regulated entities, plant-level compliance units and mappings.
INSERT INTO titan_core.regulated_entity
(regulated_entity_id,scheme_id,external_registration_id,valid_from)
VALUES
('REG-IN-CCTS-CMTOE085RJ','SCHEME-IN-CCTS','CMTOE085RJ',DATE '2025-10-08'),
('REG-IN-CCTS-CMTOE087GJ','SCHEME-IN-CCTS','CMTOE087GJ',DATE '2025-10-08'),
('REG-IN-CCTS-CMTOE019MP','SCHEME-IN-CCTS','CMTOE019MP',DATE '2025-10-08'),
('REG-IN-CCTS-CGUOE005UP','SCHEME-IN-CCTS','CGUOE005UP',DATE '2025-10-08'),
('REG-IN-CCTS-CMTOE001KA','SCHEME-IN-CCTS','CMTOE001KA',DATE '2025-10-08');

INSERT INTO titan_core.regulated_entity_name_history
(regulated_entity_id,official_name,valid_from,source_id)
VALUES
('REG-IN-CCTS-CMTOE085RJ','Kotputli Cement Works',DATE '2025-10-08','SRC-PG05-IN-GEI-2025'),
('REG-IN-CCTS-CMTOE087GJ','Naramada Cement Jafrabad Works',DATE '2025-10-08','SRC-PG05-IN-GEI-2025'),
('REG-IN-CCTS-CMTOE019MP','RCCPL Maihar Integrated Unit',DATE '2025-10-08','SRC-PG05-IN-GEI-2025'),
('REG-IN-CCTS-CGUOE005UP','Kundanganj Grinding Unit',DATE '2025-10-08','SRC-PG05-IN-GEI-2025'),
('REG-IN-CCTS-CMTOE001KA','JK Cement Works Muddapur',DATE '2025-10-08','SRC-PG05-IN-GEI-2025');

INSERT INTO titan_core.compliance_unit
(compliance_unit_id,regulated_entity_id,compliance_unit_type_code,subject_entity_id,valid_from,unit_notes)
VALUES
('CU-IN-CCTS-CMTOE085RJ','REG-IN-CCTS-CMTOE085RJ','PLANT','PL-IN-RJ-000002',DATE '2025-10-08','Scheme obligated entity mapped to TITAN Kotputli plant.'),
('CU-IN-CCTS-CMTOE087GJ','REG-IN-CCTS-CMTOE087GJ','PLANT','PL-IN-GJ-000003',DATE '2025-10-08','Scheme spelling Naramada maps to TITAN Narmada/Jafrabad plant identity.'),
('CU-IN-CCTS-CMTOE019MP','REG-IN-CCTS-CMTOE019MP','PLANT','PL-IN-MP-000013',DATE '2025-10-08','Maihar integrated unit.'),
('CU-IN-CCTS-CGUOE005UP','REG-IN-CCTS-CGUOE005UP','PLANT','PL-IN-UP-000018',DATE '2025-10-08','Kundanganj grinding unit.'),
('CU-IN-CCTS-CMTOE001KA','REG-IN-CCTS-CMTOE001KA','PLANT','PL-IN-KA-000006',DATE '2025-10-08','Muddapur integrated unit.');

INSERT INTO titan_core.regulatory_asset_mapping
(regulatory_asset_mapping_id,regulated_entity_id,compliance_unit_id,titan_entity_id,regulatory_mapping_role_code,valid_from,mapping_confidence,source_id,mapping_notes)
VALUES
('RAM-IN-CCTS-KOT','REG-IN-CCTS-CMTOE085RJ','CU-IN-CCTS-CMTOE085RJ','PL-IN-RJ-000002','PRIMARY_SITE',DATE '2025-10-08',1.0,'SRC-PG05-IN-GEI-2025','Registration and plant identity reconciled.'),
('RAM-IN-CCTS-JAF','REG-IN-CCTS-CMTOE087GJ','CU-IN-CCTS-CMTOE087GJ','PL-IN-GJ-000003','PRIMARY_SITE',DATE '2025-10-08',1.0,'SRC-PG05-IN-GEI-2025','Regulatory spelling Naramada preserved in regulated name; TITAN identity unchanged.'),
('RAM-IN-CCTS-MAI','REG-IN-CCTS-CMTOE019MP','CU-IN-CCTS-CMTOE019MP','PL-IN-MP-000013','PRIMARY_SITE',DATE '2025-10-08',1.0,'SRC-PG05-IN-GEI-2025','Registration and plant identity reconciled.'),
('RAM-IN-CCTS-KUN','REG-IN-CCTS-CGUOE005UP','CU-IN-CCTS-CGUOE005UP','PL-IN-UP-000018','PRIMARY_SITE',DATE '2025-10-08',1.0,'SRC-PG05-IN-GEI-2025','Grinding-unit identity retained.'),
('RAM-IN-CCTS-MUD','REG-IN-CCTS-CMTOE001KA','CU-IN-CCTS-CMTOE001KA','PL-IN-KA-000006','PRIMARY_SITE',DATE '2025-10-08',1.0,'SRC-PG05-IN-GEI-2025','Registration and plant identity reconciled.');

INSERT INTO titan_core.policy_applicability
(policy_applicability_id,policy_version_id,regulated_entity_id,compliance_unit_id,applicability_state_code,trigger_basis,valid_from,value_state_code,source_id)
VALUES
('APP-IN-KOT','POLV-IN-CCTS-GEI-2025','REG-IN-CCTS-CMTOE085RJ','CU-IN-CCTS-CMTOE085RJ','APPLICABLE','Listed obligated entity in Cement First Schedule',DATE '2025-10-08','VALUE','SRC-PG05-IN-GEI-2025'),
('APP-IN-JAF','POLV-IN-CCTS-GEI-2025','REG-IN-CCTS-CMTOE087GJ','CU-IN-CCTS-CMTOE087GJ','APPLICABLE','Listed obligated entity in Cement First Schedule',DATE '2025-10-08','VALUE','SRC-PG05-IN-GEI-2025'),
('APP-IN-MAI','POLV-IN-CCTS-GEI-2025','REG-IN-CCTS-CMTOE019MP','CU-IN-CCTS-CMTOE019MP','APPLICABLE','Listed obligated entity in Cement First Schedule',DATE '2025-10-08','VALUE','SRC-PG05-IN-GEI-2025'),
('APP-IN-KUN','POLV-IN-CCTS-GEI-2025','REG-IN-CCTS-CGUOE005UP','CU-IN-CCTS-CGUOE005UP','APPLICABLE','Listed obligated entity in Cement First Schedule',DATE '2025-10-08','VALUE','SRC-PG05-IN-GEI-2025'),
('APP-IN-MUD','POLV-IN-CCTS-GEI-2025','REG-IN-CCTS-CMTOE001KA','CU-IN-CCTS-CMTOE001KA','APPLICABLE','Listed obligated entity in Cement First Schedule',DATE '2025-10-08','VALUE','SRC-PG05-IN-GEI-2025');

INSERT INTO titan_core.compliance_baseline
(compliance_baseline_id,policy_version_id,regulated_entity_id,baseline_period_label,baseline_output,output_unit_code,baseline_intensity,intensity_unit_code,denominator_id,source_id,baseline_notes)
VALUES
('BASE-IN-KOT','POLV-IN-CCTS-GEI-2025','REG-IN-CCTS-CMTOE085RJ','2023-24',3666138,'TONNE',0.8086,'T_CO2E','DEN-CCTS-EQPROD','SRC-PG05-IN-GEI-2025','Equivalent product baseline.'),
('BASE-IN-JAF','POLV-IN-CCTS-GEI-2025','REG-IN-CCTS-CMTOE087GJ','2023-24',1400465,'TONNE',0.7994,'T_CO2E','DEN-CCTS-EQPROD','SRC-PG05-IN-GEI-2025','Equivalent product baseline.'),
('BASE-IN-MAI','POLV-IN-CCTS-GEI-2025','REG-IN-CCTS-CMTOE019MP','2023-24',5390695,'TONNE',0.5923,'T_CO2E','DEN-CCTS-EQPROD','SRC-PG05-IN-GEI-2025','Equivalent product baseline.'),
('BASE-IN-KUN','POLV-IN-CCTS-GEI-2025','REG-IN-CCTS-CGUOE005UP','2023-24',2787464,'TONNE',0.0128,'T_CO2E','DEN-CCTS-EQPROD','SRC-PG05-IN-GEI-2025','Equivalent product baseline.'),
('BASE-IN-MUD','POLV-IN-CCTS-GEI-2025','REG-IN-CCTS-CMTOE001KA','2023-24',3532948,'TONNE',0.4455,'T_CO2E','DEN-CCTS-EQPROD','SRC-PG05-IN-GEI-2025','Equivalent product baseline.');

INSERT INTO titan_core.compliance_obligation
(obligation_id,policy_version_id,compliance_unit_id,compliance_period_label,period_start,period_end,obligation_method_code,metric_code,target_value_state_code,target_value,target_unit_code,denominator_id,policy_rule_id,obligation_notes)
VALUES
('OBL-IN-KOT-2526','POLV-IN-CCTS-GEI-2025','CU-IN-CCTS-CMTOE085RJ','FY2025-26',DATE '2025-04-01',DATE '2026-03-31','TARGET_INTENSITY','CCTS_GEI','VALUE',0.8032,'T_CO2E','DEN-CCTS-EQPROD','POLRULE-IN-CCTS-ISSUE','Shortfall rule is paired policy rule POLRULE-IN-CCTS-SHORT.'),
('OBL-IN-KOT-2627','POLV-IN-CCTS-GEI-2025','CU-IN-CCTS-CMTOE085RJ','FY2026-27',DATE '2026-04-01',DATE '2027-03-31','TARGET_INTENSITY','CCTS_GEI','VALUE',0.7891,'T_CO2E','DEN-CCTS-EQPROD','POLRULE-IN-CCTS-ISSUE','Principal cement schedule.'),
('OBL-IN-JAF-2526','POLV-IN-CCTS-GEI-2025','CU-IN-CCTS-CMTOE087GJ','FY2025-26',DATE '2025-04-01',DATE '2026-03-31','TARGET_INTENSITY','CCTS_GEI','VALUE',0.7935,'T_CO2E','DEN-CCTS-EQPROD','POLRULE-IN-CCTS-ISSUE','Principal cement schedule.'),
('OBL-IN-JAF-2627','POLV-IN-CCTS-GEI-2025','CU-IN-CCTS-CMTOE087GJ','FY2026-27',DATE '2026-04-01',DATE '2027-03-31','TARGET_INTENSITY','CCTS_GEI','VALUE',0.7783,'T_CO2E','DEN-CCTS-EQPROD','POLRULE-IN-CCTS-ISSUE','Principal cement schedule.'),
('OBL-IN-MAI-2526','POLV-IN-CCTS-GEI-2025','CU-IN-CCTS-CMTOE019MP','FY2025-26',DATE '2025-04-01',DATE '2026-03-31','TARGET_INTENSITY','CCTS_GEI','VALUE',0.5885,'T_CO2E','DEN-CCTS-EQPROD','POLRULE-IN-CCTS-ISSUE','Principal cement schedule.'),
('OBL-IN-MAI-2627','POLV-IN-CCTS-GEI-2025','CU-IN-CCTS-CMTOE019MP','FY2026-27',DATE '2026-04-01',DATE '2027-03-31','TARGET_INTENSITY','CCTS_GEI','VALUE',0.5788,'T_CO2E','DEN-CCTS-EQPROD','POLRULE-IN-CCTS-ISSUE','Principal cement schedule.'),
('OBL-IN-KUN-2526','POLV-IN-CCTS-GEI-2025','CU-IN-CCTS-CGUOE005UP','FY2025-26',DATE '2025-04-01',DATE '2026-03-31','NO_TARGET_THIS_PERIOD','CCTS_GEI','NOT_YET_DUE',NULL,'T_CO2E','DEN-CCTS-EQPROD',NULL,'No FY2025-26 target in principal pilot schedule; not stored as zero.'),
('OBL-IN-KUN-2627','POLV-IN-CCTS-GEI-2025','CU-IN-CCTS-CGUOE005UP','FY2026-27',DATE '2026-04-01',DATE '2027-03-31','TARGET_INTENSITY','CCTS_GEI','VALUE',0.0125,'T_CO2E','DEN-CCTS-EQPROD','POLRULE-IN-CCTS-ISSUE','Principal cement grinding schedule.'),
('OBL-IN-MUD-2526','POLV-IN-CCTS-GEI-2025','CU-IN-CCTS-CMTOE001KA','FY2025-26',DATE '2025-04-01',DATE '2026-03-31','TARGET_INTENSITY','CCTS_GEI','VALUE',0.4440,'T_CO2E','DEN-CCTS-EQPROD','POLRULE-IN-CCTS-ISSUE','Principal cement schedule.'),
('OBL-IN-MUD-2627','POLV-IN-CCTS-GEI-2025','CU-IN-CCTS-CMTOE001KA','FY2026-27',DATE '2026-04-01',DATE '2027-03-31','TARGET_INTENSITY','CCTS_GEI','VALUE',0.4402,'T_CO2E','DEN-CCTS-EQPROD','POLRULE-IN-CCTS-ISSUE','Principal cement schedule.');


INSERT INTO titan_core.compliance_obligation_rule_link
(obligation_id,policy_rule_id,obligation_rule_role_code)
SELECT obligation_id,'POLRULE-IN-CCTS-ISSUE','ISSUE'
FROM titan_core.compliance_obligation
WHERE obligation_id IN (
'OBL-IN-KOT-2526','OBL-IN-KOT-2627','OBL-IN-JAF-2526','OBL-IN-JAF-2627',
'OBL-IN-MAI-2526','OBL-IN-MAI-2627','OBL-IN-KUN-2627','OBL-IN-MUD-2526','OBL-IN-MUD-2627'
);

INSERT INTO titan_core.compliance_obligation_rule_link
(obligation_id,policy_rule_id,obligation_rule_role_code)
SELECT obligation_id,'POLRULE-IN-CCTS-SHORT','SHORTFALL'
FROM titan_core.compliance_obligation
WHERE obligation_id IN (
'OBL-IN-KOT-2526','OBL-IN-KOT-2627','OBL-IN-JAF-2526','OBL-IN-JAF-2627',
'OBL-IN-MAI-2526','OBL-IN-MAI-2627','OBL-IN-KUN-2627','OBL-IN-MUD-2526','OBL-IN-MUD-2627'
);

INSERT INTO titan_core.compliance_obligation_rule_link
(obligation_id,policy_rule_id,obligation_rule_role_code)
SELECT obligation_id,'POLRULE-IN-CCTS-BANK','BANK'
FROM titan_core.compliance_obligation
WHERE obligation_id IN (
'OBL-IN-KOT-2526','OBL-IN-KOT-2627','OBL-IN-JAF-2526','OBL-IN-JAF-2627',
'OBL-IN-MAI-2526','OBL-IN-MAI-2627','OBL-IN-KUN-2627','OBL-IN-MUD-2526','OBL-IN-MUD-2627'
);

INSERT INTO titan_core.carbon_instrument
(instrument_id,scheme_id,instrument_name,instrument_type_code,unit_label,vintage_rule,banking_rule,source_id)
VALUES
('INST-IN-CCC','SCHEME-IN-CCTS','Carbon Credit Certificate','CREDIT','CCC','Compliance-year/vintage retained','Issued or purchased CCC may be banked under detailed procedure','SRC-PG05-IN-GEI-2025'),
('INST-CN-CEA','SCHEME-CN-ETS','China Emission Allowance','ALLOWANCE','tCO2e allowance','Annual allocation/vintage rules','Carry-over/banking governed by applicable allocation plan','SRC-PG05-CN-ALLOC-2425');

COMMIT;
