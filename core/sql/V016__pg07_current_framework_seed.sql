-- PG-07 current framework seed
-- Verification cut-off: 2026-08-30.
BEGIN;

INSERT INTO titan_core.unit_master(unit_code,symbol,dimension_code,base_unit_symbol,factor_to_base,definition)
VALUES ('HA','ha','AREA','m2',10000,'Hectare; area unit for quarry/restoration/nature extent');

INSERT INTO titan_core.entity_registry(entity_id,entity_type_code,canonical_name,country_geo_id) VALUES
('SRC-PG07-GRI303','SOURCE','GRI 303 Water and Effluents 2018',NULL),
('SRC-PG07-GRI101','SOURCE','GRI 101 Biodiversity 2024',NULL),
('SRC-PG07-TNFD-LEAP','SOURCE','TNFD LEAP approach guidance',NULL),
('SRC-PG07-SBTN-FW2','SOURCE','SBTN Freshwater Targets Version 2 pilot guidance/status',NULL),
('SRC-PG07-SBTI-CNZ2','SOURCE','SBTi Corporate Net-Zero Standard Version 2.0',NULL),
('SRC-PG07-SBTI-CNZ-TRANS','SOURCE','SBTi Corporate Net-Zero Standard V2 transition guidance',NULL),
('SRC-PG07-IFRS-S2-TP','SOURCE','IFRS S2 transition plan disclosure guidance',NULL),
('SRC-PG07-ISSA5000','SOURCE','IAASB ISSA 5000 sustainability assurance standard/status',NULL);

INSERT INTO titan_core.source_document
(source_id,publisher_name,document_title,document_type_code,evidence_grade_code,publication_date,language_code,mime_type,archival_status_code,authoritative_status,source_notes)
VALUES
('SRC-PG07-GRI303','Global Reporting Initiative','GRI 303: Water and Effluents 2018','TECHNICAL_REPORT','P1',DATE '2018-06-28','en','application/pdf','LIVE_ONLY','CURRENT','Separates withdrawal, discharge and consumption; water impacts are locally contextual.'),
('SRC-PG07-GRI101','Global Reporting Initiative','GRI 101: Biodiversity 2024','TECHNICAL_REPORT','P1',NULL,'en','application/pdf','LIVE_ONLY','EFFECTIVE','Effective for reporting from 1 Jan 2026; location-specific biodiversity impacts and mitigation hierarchy.'),
('SRC-PG07-TNFD-LEAP','Taskforce on Nature-related Financial Disclosures','LEAP approach guidance','TECHNICAL_REPORT','P2',NULL,'en','text/html','LIVE_ONLY','CURRENT','Locate, Evaluate, Assess, Prepare; supports location-specific nature assessment.'),
('SRC-PG07-SBTN-FW2','Science Based Targets Network','Freshwater targets Version 2 — corporate pilot status','TECHNICAL_REPORT','P2',DATE '2026-06-01','en','text/html','LIVE_ONLY','PILOT','Freshwater targets are basin-specific; Version 2 entered corporate pilot in June 2026 and is not yet treated as final production guidance.'),
('SRC-PG07-SBTI-CNZ2','Science Based Targets initiative','Corporate Net-Zero Standard Version 2.0','TECHNICAL_REPORT','P1',DATE '2026-06-11','en','application/pdf','LIVE_ONLY','PUBLISHED','Contains base-year recalculation evaluation and 5% significance threshold for any individual scope.'),
('SRC-PG07-SBTI-CNZ-TRANS','Science Based Targets initiative','Corporate Net-Zero Standard V2.0 — what comes next','TECHNICAL_REPORT','P2',DATE '2026-06-11','en','text/html','LIVE_ONLY','CURRENT','V2 target setting/validation opens from 1 Feb 2027; 2026 submissions continue under V1.3.1.'),
('SRC-PG07-IFRS-S2-TP','IFRS Foundation','Disclosing climate-related transition information under IFRS S2','TECHNICAL_REPORT','P1',DATE '2025-06-01','en','application/pdf','LIVE_ONLY','CURRENT','Net GHG target requires separate associated gross target disclosure; planned carbon-credit reliance must be separately described.'),
('SRC-PG07-ISSA5000','IAASB','International Standard on Sustainability Assurance 5000 — implementation/adoption status','TECHNICAL_REPORT','P1',NULL,'en','text/html','LIVE_ONLY','FUTURE_EFFECTIVE','General effective date 15 Dec 2026 with early application permitted; assurance scope/level/practitioner must be explicit.');

INSERT INTO titan_core.source_endpoint(endpoint_id,endpoint_url,endpoint_access_status_code) VALUES
('ENDP-PG07-GRI303','https://www.globalreporting.org/publications/documents/english/gri-303-water-and-effluents-2018/','ACTIVE'),
('ENDP-PG07-GRI101','https://www.globalreporting.org/standards/standards-development/topic-standard-for-biodiversity/','ACTIVE'),
('ENDP-PG07-TNFD','https://tnfd.global/publication/additional-guidance-on-assessment-of-nature-related-issues-the-leap-approach/','ACTIVE'),
('ENDP-PG07-SBTN-FW2','https://sciencebasedtargetsnetwork.org/companies/take-action/set-targets/freshwater-targets/','ACTIVE'),
('ENDP-PG07-SBTI-CNZ2','https://files.sciencebasedtargets.org/production/files/Corporate-Net-Zero-Standard-version-2.pdf','ACTIVE'),
('ENDP-PG07-SBTI-CNZ-TRANS','https://sciencebasedtargets.org/blog/the-corporate-net-zero-standard-v2-0-is-here-what-comes-next','ACTIVE'),
('ENDP-PG07-IFRS-S2-TP','https://www.ifrs.org/content/dam/ifrs/supporting-implementation/ifrs-s2/transition-plan-disclosure-s2.pdf','ACTIVE'),
('ENDP-PG07-ISSA5000','https://www.iaasb.org/focus-areas/understanding-international-standard-sustainability-assurance-5000','ACTIVE');

INSERT INTO titan_core.extraction_record
(extraction_id,source_id,location_ref,extracted_text,extracted_numeric_value,extracted_unit_text,extraction_method_code,reviewer_ref,extraction_confidence)
VALUES
('EXT-PG07-GRI303','SRC-PG07-GRI303','Disclosure 303-1 and water-use definitions','Water management distinguishes how and where water is withdrawn, consumed and discharged; local context matters.',NULL,NULL,'MANUAL','PG07 verification',1.0),
('EXT-PG07-GRI101','SRC-PG07-GRI101','Standard effective date / location-specific impact disclosures','GRI 101 Biodiversity 2024 is effective for reporting from 1 Jan 2026 and requires location-specific biodiversity information.',NULL,NULL,'MANUAL','PG07 verification',1.0),
('EXT-PG07-SBTN-FW2','SRC-PG07-SBTN-FW2','Freshwater targets page / Version 2 pilot','Freshwater targets are basin-specific; selected companies began piloting Version 2 guidance in June 2026.',NULL,NULL,'MANUAL','PG07 verification',1.0),
('EXT-PG07-SBTI-5PCT','SRC-PG07-SBTI-CNZ2','Section 2.6 / C8.3','5% significance threshold is met when cumulative identified changes vary total emissions by 5% or more in any individual scope.',5,'percent','MANUAL','PG07 verification',1.0),
('EXT-PG07-SBTI-TRANS','SRC-PG07-SBTI-CNZ-TRANS','Transition timing','Version 2.0 target setting is available from 1 Feb 2027; companies setting or renewing targets in 2026 are directed to V1.3.1.',NULL,NULL,'MANUAL','PG07 verification',1.0),
('EXT-PG07-IFRS-S2','SRC-PG07-IFRS-S2-TP','IFRS S2 paragraph 36 guidance','For a net GHG target, the associated gross target is separately disclosed; planned carbon-credit use is separately described.',NULL,NULL,'MANUAL','PG07 verification',1.0),
('EXT-PG07-ISSA5000','SRC-PG07-ISSA5000','Adoption/effective date','ISSA 5000 generally applies for periods beginning on or after 15 Dec 2026, with early application permitted.',NULL,NULL,'MANUAL','PG07 verification',1.0);

INSERT INTO titan_core.methodology_master
(methodology_id,methodology_family_code,methodology_name,authority_name,methodology_notes)
VALUES
('METH-SBTI-CNZ','CORPORATE_GHG','SBTi Corporate Net-Zero Standard','Science Based Targets initiative','Target framework version must stay attached to exact validated target version.');

INSERT INTO titan_core.methodology_version
(methodology_version_id,methodology_id,version_label,methodology_status_code,valid_from,source_id)
VALUES
('METHV-SBTI-CNZ-V2','METH-SBTI-CNZ','2.0','FUTURE_EFFECTIVE',DATE '2027-02-01','SRC-PG07-SBTI-CNZ2');

COMMIT;
