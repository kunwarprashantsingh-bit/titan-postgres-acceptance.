-- PG-06 verified current CCUS / CBAM seed
-- Verification cut-off: 2026-08-30.
BEGIN;

-- Additional geographic identities used by current CCUS/CBAM integration.
INSERT INTO titan_core.entity_registry(entity_id,entity_type_code,canonical_name,country_geo_id) VALUES
('REG-EU','GEO_REGION','European Union',NULL),
('CTY-NO','GEO_COUNTRY','Norway','CTY-NO'),
('CTY-DE','GEO_COUNTRY','Germany','CTY-DE'),
('CTY-NL','GEO_COUNTRY','Netherlands','CTY-NL'),
('CTY-FR','GEO_COUNTRY','France','CTY-FR'),
('CTY-AE','GEO_COUNTRY','United Arab Emirates','CTY-AE');

INSERT INTO titan_core.geo_unit(geo_id,geo_type_code,parent_geo_id,official_name,iso_alpha2) VALUES
('REG-EU','REGION',NULL,'European Union',NULL),
('CTY-NO','COUNTRY',NULL,'Norway','NO'),
('CTY-DE','COUNTRY','REG-EU','Germany','DE'),
('CTY-NL','COUNTRY','REG-EU','Netherlands','NL'),
('CTY-FR','COUNTRY','REG-EU','France','FR'),
('CTY-AE','COUNTRY',NULL,'United Arab Emirates','AE');

INSERT INTO titan_core.unit_master(unit_code,symbol,dimension_code,base_unit_symbol,factor_to_base,definition)
VALUES ('T_CO2_PER_YEAR','tCO2/y','RATE_CO2',NULL,NULL,'Annual CO2 design/nameplate capacity; not actual annual capture'),
('EUR_PER_T_CO2E','EUR/tCO2e','CARBON_PRICE',NULL,NULL,'Euro per tonne CO2e; carbon-price rate, not total payment');

-- Current evidence sources.
INSERT INTO titan_core.entity_registry(entity_id,entity_type_code,canonical_name,country_geo_id) VALUES
('SRC-PG06-HM-ASR25','SOURCE','Heidelberg Materials Annual and Sustainability Report 2025','CTY-DE'),
('SRC-PG06-HM-CCUS-CURR','SOURCE','Heidelberg Materials current CCUS page — Brevik operational','CTY-DE'),
('SRC-PG06-NL-CERT','SOURCE','Northern Lights first CO2 storage certificates','CTY-NO'),
('SRC-PG06-EU-CBAM-BASE','SOURCE','EU CBAM Regulation consolidated definitive regime',NULL),
('SRC-PG06-EU-CBAM-THRESH','SOURCE','EU 2025/2083 CBAM simplification threshold',NULL),
('SRC-PG06-EU-CBAM-METHOD','SOURCE','EU 2025/2547 CBAM embedded emissions methods',NULL),
('SRC-PG06-EU-CBAM-PRICE','SOURCE','EU CBAM certificate price page',NULL),
('SRC-PG06-EU-CBAM-PRICE-REG','SOURCE','EU 2025/2548 CBAM price methodology',NULL),
('SRC-PG06-EU-CBAM-DEFAULT','SOURCE','EU 2026/1740 corrected CBAM default values',NULL),
('SRC-PG06-EU-CBAM-FCP-DRAFT','SOURCE','EU CBAM carbon price paid third countries — draft implementing act',NULL);

INSERT INTO titan_core.source_document
(source_id,publisher_name,document_title,document_type_code,evidence_grade_code,publication_date,language_code,mime_type,archival_status_code,authoritative_status,source_notes)
VALUES
('SRC-PG06-HM-ASR25','Heidelberg Materials','Annual and Sustainability Report 2025','SUSTAINABILITY_REPORT','P2',DATE '2026-03-26','en','application/pdf','LIVE_ONLY','PUBLISHED','Reports 58,408 t CO2 transferred to Northern Lights, 37,500 t permanently stored, 4,125 t biogenic origin provisional, 1,236 tCO2e lifecycle emissions.'),
('SRC-PG06-HM-CCUS-CURR','Heidelberg Materials','CCUS: more future with less CO2','COMPANY_WEBPAGE','P3',NULL,'en','text/html','LIVE_ONLY','CURRENT','Brevik CCS described as operational; 400,000 tCO2/y design capacity.'),
('SRC-PG06-NL-CERT','Northern Lights','Northern Lights has issued first CO2 storage certificates','COMPANY_WEBPAGE','P3',DATE '2025-12-08','en','text/html','LIVE_ONLY','PUBLISHED','First storage certificates issued for Brevik cargoes; certificates detail stored quantity and lifecycle emissions.'),
('SRC-PG06-EU-CBAM-BASE','EUR-Lex / European Commission','Regulation (EU) 2023/956 consolidated','REGULATORY_NOTICE','P1',NULL,'en','text/html','LIVE_ONLY','IN_FORCE','Core definitive CBAM obligations and Article 9 carbon-price-paid principle.'),
('SRC-PG06-EU-CBAM-THRESH','EUR-Lex','Regulation (EU) 2025/2083','REGULATORY_NOTICE','P1',DATE '2025-10-08','en','text/html','LIVE_ONLY','IN_FORCE','50-tonne annual mass threshold for mass-based sectors.'),
('SRC-PG06-EU-CBAM-METHOD','EUR-Lex','Implementing Regulation (EU) 2025/2547','REGULATORY_NOTICE','P1',DATE '2025-12-22','en','text/html','LIVE_ONLY','IN_FORCE','Actual/default embedded emissions, system boundaries and precursor rules.'),
('SRC-PG06-EU-CBAM-PRICE','European Commission / TAXUD','Price of CBAM certificates','GOVERNMENT_WEBPAGE','P1',NULL,'en','text/html','LIVE_ONLY','CURRENT','Q1 2026 EUR 75.36; Q2 2026 EUR 75.28; Q3 publication due 5 Oct 2026.'),
('SRC-PG06-EU-CBAM-PRICE-REG','EUR-Lex','Implementing Regulation (EU) 2025/2548','REGULATORY_NOTICE','P1',DATE '2025-12-10','en','text/html','LIVE_ONLY','IN_FORCE','Quarterly 2026 CBAM certificate pricing methodology.'),
('SRC-PG06-EU-CBAM-DEFAULT','EUR-Lex','Implementing Regulation (EU) 2026/1740','REGULATORY_NOTICE','P1',DATE '2026-07-31','en','text/html','LIVE_ONLY','IN_FORCE','Corrected definitive default values; legal mark-up schedule includes 10% in 2026.'),
('SRC-PG06-EU-CBAM-FCP-DRAFT','European Commission / EUR-Lex','Carbon price paid in third countries — draft implementing regulation Ares(2026)4841230','REGULATORY_NOTICE','P1',DATE '2026-05-13','en','text/html','LIVE_ONLY','CONSULTATION','Detailed conversion/evidence mechanics remain draft in current official guidance at cut-off.');

INSERT INTO titan_core.source_endpoint(endpoint_id,endpoint_url,endpoint_access_status_code) VALUES
('ENDP-PG06-HM-ASR25','https://www.heidelbergmaterials.com/system/files/2026-03/HM_ASR25_en.pdf','ACTIVE'),
('ENDP-PG06-HM-CCUS','https://www.heidelbergmaterials.com/en/sustainability/we-decarbonize-the-construction-industry/ccus','ACTIVE'),
('ENDP-PG06-NL-CERT','https://norlights.com/news/northern-lights-has-issued-first-co%E2%82%82-storage-certificates/','ACTIVE'),
('ENDP-PG06-EU-BASE','https://eur-lex.europa.eu/eli/reg/2023/956/','ACTIVE'),
('ENDP-PG06-EU-THRESH','https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:32025R2083','ACTIVE'),
('ENDP-PG06-EU-METHOD','https://eur-lex.europa.eu/legal-content/en/TXT/?uri=CELEX:32025R2547','ACTIVE'),
('ENDP-PG06-EU-PRICE','https://taxation-customs.ec.europa.eu/carbon-border-adjustment-mechanism/price-cbam-certificates_en','ACTIVE'),
('ENDP-PG06-EU-PRICE-REG','https://eur-lex.europa.eu/legal-content/EN/ALL/?uri=CELEX:32025R2548','ACTIVE'),
('ENDP-PG06-EU-DEFAULT','https://eur-lex.europa.eu/eli/reg_impl/2026/1740/oj/eng','ACTIVE'),
('ENDP-PG06-EU-FCP-DRAFT','https://eur-lex.europa.eu/legal-content/DE/PIN/?uri=intcom:Ares(2026)4841230','ACTIVE');

-- Brevik exact evidence extractions.
INSERT INTO titan_core.extraction_record
(extraction_id,source_id,location_ref,extracted_text,extracted_numeric_value,extracted_unit_text,extraction_method_code,reviewer_ref,extraction_confidence)
VALUES
('EXT-PG06-BREVIK-TRANSFER','SRC-PG06-HM-ASR25','E1 Climate change — GHG removals/storage table','Total amount of CO2 transferred to Northern Lights: 58,408 t CO2',58408,'t CO2','MANUAL','PG06 verification',1.0),
('EXT-PG06-BREVIK-STORED','SRC-PG06-HM-ASR25','E1 Climate change — GHG removals/storage table','Total amount of CO2 in permanent storage: 37,500 t',37500,'t CO2','MANUAL','PG06 verification',1.0),
('EXT-PG06-BREVIK-BIO','SRC-PG06-HM-ASR25','E1 Climate change — GHG removals/storage table / narrative','Share of CO2 from biogenic origins: about 4,125 t; final fraction to be confirmed during ETS reporting',4125,'t CO2','MANUAL','PG06 verification',1.0),
('EXT-PG06-BREVIK-LIFE','SRC-PG06-HM-ASR25','E1 Climate change — GHG removals/storage table','GHG emissions associated with removal and storage activity: 1,236 tCO2e',1236,'t CO2e','MANUAL','PG06 verification',1.0),
('EXT-PG06-BREVIK-DESIGN','SRC-PG06-HM-CCUS-CURR','Brevik operational project description','Brevik CCS is operational and designed to capture around 400,000 tonnes CO2 annually',400000,'t CO2/y','MANUAL','PG06 verification',1.0),
('EXT-PG06-NL-CERT','SRC-PG06-NL-CERT','First storage certificates article','Northern Lights issued first storage certificates for Brevik cargoes; certificates document transported/stored quantity and lifecycle emissions.',NULL,NULL,'MANUAL','PG06 verification',1.0);

-- Brevik project identity without inventing a TITAN physical PL ID.
INSERT INTO titan_core.entity_registry(entity_id,entity_type_code,canonical_name,country_geo_id) VALUES
('CCS-NO-BREVIK-001','CCUS_PROJECT','Brevik CCS','CTY-NO'),
('OBS-PG06-BREVIK-DESIGN','OBSERVATION','Brevik CCS annual design capture capacity','CTY-NO'),
('OBS-PG06-BREVIK-TRANSFER','OBSERVATION','Brevik 2025 CO2 transferred to Northern Lights','CTY-NO'),
('OBS-PG06-BREVIK-STORED','OBSERVATION','Brevik 2025 CO2 permanently stored','CTY-NO'),
('OBS-PG06-BREVIK-BIO','OBSERVATION','Brevik 2025 biogenic-origin CO2 share','CTY-NO'),
('OBS-PG06-BREVIK-LIFE','OBSERVATION','Brevik 2025 CCUS lifecycle emissions','CTY-NO'),
('OBS-PG06-BREVIK-RESIDUAL','OBSERVATION','Brevik 2025 transferred minus certified stored residual','CTY-NO');

INSERT INTO titan_core.observation
(observation_id,subject_entity_id,metric_code,quantity_kind_code,value_state_code,data_class_code,numeric_value,unit_code,period_start,period_end,observation_notes)
VALUES
('OBS-PG06-BREVIK-DESIGN','CCS-NO-BREVIK-001','CCUS_DESIGN_CAPTURE_CAPACITY_ANNUAL','LIMIT','VALUE','R',400000,'T_CO2_PER_YEAR',DATE '2026-08-30',DATE '2026-08-30','Design/nameplate; not actual capture.'),
('OBS-PG06-BREVIK-TRANSFER','CCS-NO-BREVIK-001','CO2_TRANSFERRED_TO_STORAGE_CHAIN','ABSOLUTE','VALUE','R',58408,'T_CO2',DATE '2025-01-01',DATE '2025-12-31','Actual 2025 transferred quantity.'),
('OBS-PG06-BREVIK-STORED','CCS-NO-BREVIK-001','CO2_PERMANENTLY_STORED','ABSOLUTE','VALUE','R',37500,'T_CO2',DATE '2025-01-01',DATE '2025-12-31','Actual 2025 permanently stored quantity reported/assured.'),
('OBS-PG06-BREVIK-BIO','CCS-NO-BREVIK-001','CO2_BIOGENIC_ORIGIN_STORED','ABSOLUTE','PROVISIONAL','R',4125,'T_CO2',DATE '2025-01-01',DATE '2025-12-31','Reported as about 4,125 t; final fraction pending ETS confirmation.'),
('OBS-PG06-BREVIK-LIFE','CCS-NO-BREVIK-001','CCUS_LIFECYCLE_EMISSIONS','ABSOLUTE','VALUE','R',1236,'T_CO2E',DATE '2025-01-01',DATE '2025-12-31','Capture facility operation plus partner transport/storage emissions.'),
('OBS-PG06-BREVIK-RESIDUAL','CCS-NO-BREVIK-001','CO2_IN_CHAIN_UNRECONCILED','ABSOLUTE','VALUE','D',20908,'T_CO2',DATE '2025-01-01',DATE '2025-12-31','Transferred minus permanently stored at reporting cut-off; not automatically a loss.');

INSERT INTO titan_core.observation_evidence_link(observation_id,extraction_id,support_type_code) VALUES
('OBS-PG06-BREVIK-DESIGN','EXT-PG06-BREVIK-DESIGN','SUPPORTS'),
('OBS-PG06-BREVIK-TRANSFER','EXT-PG06-BREVIK-TRANSFER','SUPPORTS'),
('OBS-PG06-BREVIK-STORED','EXT-PG06-BREVIK-STORED','SUPPORTS'),
('OBS-PG06-BREVIK-BIO','EXT-PG06-BREVIK-BIO','SUPPORTS'),
('OBS-PG06-BREVIK-LIFE','EXT-PG06-BREVIK-LIFE','SUPPORTS');

INSERT INTO titan_core.observation_derivation(observation_id,formula_text,calculation_notes)
VALUES ('OBS-PG06-BREVIK-RESIDUAL','CO2 transferred to storage chain - CO2 permanently stored','Residual remains in-chain/unreconciled unless separate evidence identifies release/loss.');

INSERT INTO titan_core.observation_derivation_input(observation_id,input_observation_id,input_role) VALUES
('OBS-PG06-BREVIK-RESIDUAL','OBS-PG06-BREVIK-TRANSFER','TRANSFERRED'),
('OBS-PG06-BREVIK-RESIDUAL','OBS-PG06-BREVIK-STORED','PERMANENTLY_STORED');

INSERT INTO titan_core.ccus_project
(ccus_project_id,project_name,source_name_text,ccus_project_maturity_code,valid_from,source_id,project_notes)
VALUES
('CCS-NO-BREVIK-001','Brevik CCS','Brevik cement plant, Norway','OPERATING',DATE '2025-06-18','SRC-PG06-HM-CCUS-CURR','No new TITAN physical PL ID created in PG-06; physical plant identity will be reused when/if Brevik is admitted to the TITAN plant master.');

INSERT INTO titan_core.capture_asset
(capture_asset_id,ccus_project_id,asset_name,technology,design_capacity_observation_id,valid_from,source_id)
VALUES ('CAP-BREVIK-001','CCS-NO-BREVIK-001','Brevik CCS capture plant','Amine-based capture','OBS-PG06-BREVIK-DESIGN',DATE '2025-06-18','SRC-PG06-HM-CCUS-CURR');

INSERT INTO titan_core.capture_stream
(capture_stream_id,capture_asset_id,stream_name,source_process,source_id)
VALUES ('CSTR-BREVIK-001','CAP-BREVIK-001','Brevik captured CO2 stream','Cement production process and fuel emissions','SRC-PG06-HM-ASR25');

INSERT INTO titan_core.co2_batch
(co2_batch_id,capture_stream_id,batch_label,capture_period_start,capture_period_end,captured_quantity_observation_id,current_state_code,source_id,batch_notes)
VALUES ('CO2B-BREVIK-2025','CSTR-BREVIK-001','Brevik aggregate 2025 reporting batch',DATE '2025-01-01',DATE '2025-12-31','OBS-PG06-BREVIK-TRANSFER','IN_CHAIN_UNRECONCILED','SRC-PG06-HM-ASR25','Annual aggregate reporting representation; not an assertion that the annual total was one physical cargo.');

INSERT INTO titan_core.co2_batch_origin_component
(co2_batch_id,carbon_origin_code,origin_share,quantity_observation_id,source_id)
VALUES ('CO2B-BREVIK-2025','BIOGENIC',NULL,'OBS-PG06-BREVIK-BIO','SRC-PG06-HM-ASR25');

INSERT INTO titan_core.co2_custody_event
(custody_event_id,co2_batch_id,custody_event_type_code,event_time,from_party_or_asset,to_party_or_asset,quantity_observation_id,source_id,event_notes)
VALUES ('CUST-BREVIK-2025-TRANSFER','CO2B-BREVIK-2025','LOAD',TIMESTAMPTZ '2025-12-31 23:59:59+01','Brevik CCS','Northern Lights','OBS-PG06-BREVIK-TRANSFER','SRC-PG06-HM-ASR25','Aggregate annual transfer representation.');

INSERT INTO titan_core.co2_chain_state
(co2_chain_state_id,co2_batch_id,co2_batch_state_code,as_of_date,quantity_observation_id,source_id,state_notes)
VALUES
('CSTATE-BREVIK-2025-STORED','CO2B-BREVIK-2025','STORED_CERTIFIED',DATE '2025-12-31','OBS-PG06-BREVIK-STORED','SRC-PG06-HM-ASR25','Permanent storage quantity verified by assurance provider per annual report.'),
('CSTATE-BREVIK-2025-RESID','CO2B-BREVIK-2025','IN_CHAIN_UNRECONCILED',DATE '2025-12-31','OBS-PG06-BREVIK-RESIDUAL','SRC-PG06-HM-ASR25','Mainly still in Northern Lights infrastructure; minor losses may occur but are not inferred from residual.');

INSERT INTO titan_core.storage_site
(storage_site_id,storage_site_name,jurisdiction_geo_id,operator_name,storage_type,source_id)
VALUES ('STOR-NL-AURORA','Aurora reservoir / Northern Lights storage complex','CTY-NO','Northern Lights','PERMANENT_GEOLOGIC','SRC-PG06-NL-CERT');

INSERT INTO titan_core.permanence_assessment
(permanence_assessment_id,co2_batch_id,permanence_outcome_code,assessed_quantity_observation_id,source_id,assessment_notes)
VALUES ('PERM-BREVIK-2025','CO2B-BREVIK-2025','PERMANENT_GEOLOGIC','OBS-PG06-BREVIK-STORED','SRC-PG06-NL-CERT','Permanent storage certification exists; no aggregate certificate number invented in TITAN.');

INSERT INTO titan_core.ccus_accounting_result
(ccus_accounting_result_id,co2_batch_id,ccus_accounting_class_code,quantity_observation_id,source_id,accounting_notes)
VALUES ('CCAR-BREVIK-2025-PEND','CO2B-BREVIK-2025','PENDING','OBS-PG06-BREVIK-STORED','SRC-PG06-HM-ASR25','Stored quantity is physically verified; final accounting classification must distinguish mineral/fossil emission-not-released from provisional biogenic removal treatment.');

-- EU CBAM scheme and exact current policy versions.
INSERT INTO titan_core.carbon_scheme
(scheme_id,scheme_name,scheme_type_code,jurisdiction_geo_id,governing_authority_name,instrument_unit_label,scheme_notes)
VALUES ('SCHEME-EU-CBAM','EU Carbon Border Adjustment Mechanism','BORDER_ADJUSTMENT','REG-EU','European Commission / national competent authorities','CBAM certificate','Definitive regime from 1 Jan 2026.');

INSERT INTO titan_core.policy_version
(policy_version_id,scheme_id,legal_title,legal_citation,publication_date,effective_from,primary_source_id,policy_notes)
VALUES
('POLV-EU-CBAM-BASE','SCHEME-EU-CBAM','Regulation (EU) 2023/956 — consolidated','Regulation (EU) 2023/956',NULL,DATE '2026-01-01','SRC-PG06-EU-CBAM-BASE','Core definitive regime and Article 9 carbon-price-paid principle.'),
('POLV-EU-CBAM-THRESH','SCHEME-EU-CBAM','Regulation (EU) 2025/2083','Regulation (EU) 2025/2083',DATE '2025-10-08',DATE '2026-01-01','SRC-PG06-EU-CBAM-THRESH','50 t mass threshold simplification.'),
('POLV-EU-CBAM-METHOD','SCHEME-EU-CBAM','Implementing Regulation (EU) 2025/2547','EU 2025/2547',DATE '2025-12-22',DATE '2026-01-01','SRC-PG06-EU-CBAM-METHOD','Embedded-emissions and precursor methodology.'),
('POLV-EU-CBAM-PRICE','SCHEME-EU-CBAM','Implementing Regulation (EU) 2025/2548','EU 2025/2548',DATE '2025-12-10',DATE '2026-01-01','SRC-PG06-EU-CBAM-PRICE-REG','Quarterly prices in 2026, weekly from 2027.'),
('POLV-EU-CBAM-DEFAULT26','SCHEME-EU-CBAM','Implementing Regulation (EU) 2026/1740','EU 2026/1740',DATE '2026-07-31',DATE '2026-01-01','SRC-PG06-EU-CBAM-DEFAULT','Corrected default values; 2026 cement default mark-up 10%.'),
('POLV-EU-CBAM-FCP-DRAFT','SCHEME-EU-CBAM','Carbon price paid in third countries — draft implementing regulation','Ares(2026)4841230',DATE '2026-05-13',NULL,'SRC-PG06-EU-CBAM-FCP-DRAFT','Draft/consultation only; no final relief conversion formula bound.');

INSERT INTO titan_core.policy_status_history
(policy_status_history_id,policy_version_id,policy_status_code,valid_from,source_id,status_notes)
VALUES
('POLSTAT-EU-CBAM-BASE','POLV-EU-CBAM-BASE','EFFECTIVE',DATE '2026-01-01','SRC-PG06-EU-CBAM-BASE','Definitive regime effective.'),
('POLSTAT-EU-CBAM-THRESH','POLV-EU-CBAM-THRESH','EFFECTIVE',DATE '2026-01-01','SRC-PG06-EU-CBAM-THRESH','Threshold rule effective.'),
('POLSTAT-EU-CBAM-METHOD','POLV-EU-CBAM-METHOD','EFFECTIVE',DATE '2026-01-01','SRC-PG06-EU-CBAM-METHOD','Embedded-emissions method effective.'),
('POLSTAT-EU-CBAM-PRICE','POLV-EU-CBAM-PRICE','EFFECTIVE',DATE '2026-01-01','SRC-PG06-EU-CBAM-PRICE-REG','Price method effective.'),
('POLSTAT-EU-CBAM-DEFAULT26','POLV-EU-CBAM-DEFAULT26','EFFECTIVE',DATE '2026-01-01','SRC-PG06-EU-CBAM-DEFAULT','Corrected default values applicable to 2026.'),
('POLSTAT-EU-CBAM-FCP-DRAFT','POLV-EU-CBAM-FCP-DRAFT','CONSULTATION',DATE '2026-05-13','SRC-PG06-EU-CBAM-FCP-DRAFT','Detailed conversion/evidence act not final at cut-off.');

INSERT INTO titan_core.policy_formula_rule
(policy_rule_id,policy_version_id,rule_code,rule_title,rule_expression,parameter_schema,source_location_ref,source_id)
VALUES
('POLRULE-EU-CBAM-50T','POLV-EU-CBAM-THRESH','ANNUAL_50T_THRESHOLD','Annual covered-goods mass threshold','IN_SCOPE if cumulative covered net mass > 50 tonnes','{"threshold_t":50,"operator":">"}'::jsonb,'Regulation 2025/2083 threshold provision','SRC-PG06-EU-CBAM-THRESH'),
('POLRULE-EU-CBAM-DEF26','POLV-EU-CBAM-DEFAULT26','DEFAULT_MARKUP_2026','2026 legal default-value mark-up','effective_default = base_default * 1.10','{"markup":0.10,"year":2026}'::jsonb,'Implementing Regulation 2026/1740','SRC-PG06-EU-CBAM-DEFAULT'),
('POLRULE-EU-CBAM-ART9-PRINCIPLE','POLV-EU-CBAM-BASE','CARBON_PRICE_PAID_PRINCIPLE','Carbon price effectively paid deduction principle','Corresponding amount may reduce CBAM certificates where legal/evidence conditions are met; final detailed conversion act required','{}'::jsonb,'Article 9','SRC-PG06-EU-CBAM-BASE');

INSERT INTO titan_core.cbam_price_reference
(cbam_price_reference_id,price_year,price_period_label,period_start,period_end,price_eur_per_certificate,publication_date,policy_version_id,source_id)
VALUES
('CBP-2026-Q1',2026,'Q1',DATE '2026-01-01',DATE '2026-03-31',75.36,DATE '2026-04-07','POLV-EU-CBAM-PRICE','SRC-PG06-EU-CBAM-PRICE'),
('CBP-2026-Q2',2026,'Q2',DATE '2026-04-01',DATE '2026-06-30',75.28,DATE '2026-07-06','POLV-EU-CBAM-PRICE','SRC-PG06-EU-CBAM-PRICE');

COMMIT;
