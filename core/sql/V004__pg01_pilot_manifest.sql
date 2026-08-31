-- PG-01 ten-asset pilot migration manifest.
-- These rows stage existing TITAN plant identities unchanged.
-- Permanent SITE IDs are intentionally NOT minted in this file.
-- The full co-location / duplicate-site screen must first confirm the physical site.

BEGIN;

INSERT INTO titan_migration.pg01_plant_identity_stage
(legacy_plant_id,canonical_name,country_geo_id,admin1_geo_id,plant_type_code,source_baseline,source_as_of,site_resolution_status,resolved_site_id,site_resolution_notes,migration_status)
VALUES
('PL-IN-RJ-000002','Kotputli Cement Works','CTY-IN','SUB-IN-RJ','INTEGRATED','TITAN Sustainability Pilot / Architecture v1.0',DATE '2026-08-28','NOT_SCREENED',NULL,'Preserve PL ID; perform site co-location/duplicate screen before issuing permanent SITE ID.','STAGED'),
('PL-IN-GJ-000003','Narmada Cement Jafrabad Works','CTY-IN','SUB-IN-GJ','INTEGRATED','TITAN Sustainability Pilot / Architecture v1.0',DATE '2026-08-28','NOT_SCREENED',NULL,'Integrated plant; captive jetty remains a separate logistics object in later tranche.','STAGED'),
('PL-IN-MP-000013','RCCPL Maihar Integrated Unit','CTY-IN','SUB-IN-MP','INTEGRATED','TITAN Sustainability Pilot / Architecture v1.0',DATE '2026-08-28','NOT_SCREENED',NULL,'Preserve current TITAN identity; clinker-capacity reconciliation remains outside PG-01 identity migration.','STAGED'),
('PL-IN-UP-000018','Kundanganj Grinding Unit','CTY-IN','SUB-IN-UP','GRINDING','TITAN Sustainability Pilot / Architecture v1.0',DATE '2026-08-28','NOT_SCREENED',NULL,'Grinding-only physical plant; shared power relationships are PG-02/PG-04 scope.','STAGED'),
('PL-IN-KA-000006','JK Cement Works Muddapur','CTY-IN','SUB-IN-KA','INTEGRATED','TITAN Sustainability Pilot / Architecture v1.0',DATE '2026-08-28','NOT_SCREENED',NULL,'Preserve PL ID; project-era capacity baselines do not alter plant identity.','STAGED'),
('PL-CN-AH-000004','Wuhu Conch','CTY-CN','SUB-CN-AH','INTEGRATED','TITAN Sustainability Pilot / Architecture v1.0',DATE '2026-08-28','NOT_SCREENED',NULL,'Six-kiln physical plant identity preserved; line IDs migrate later without re-keying.','STAGED'),
('PL-CN-AH-000002','Tongling Conch','CTY-CN','SUB-CN-AH','INTEGRATED','TITAN Sustainability Pilot / Architecture v1.0',DATE '2026-08-28','NOT_SCREENED',NULL,'Plant identity preserved; circularity/AF projects remain separate objects.','STAGED'),
('PL-CN-AH-000003','Ningguo Cement Plant','CTY-CN','SUB-CN-AH','INTEGRATED','TITAN Sustainability Pilot / Architecture v1.0',DATE '2026-08-28','NOT_SCREENED',NULL,'Plant identity unaffected by unresolved retrofit-status conflict.','STAGED'),
('PL-CN-AH-000019','Ma''anshan Conch','CTY-CN','SUB-CN-AH','GRINDING','TITAN Sustainability Pilot / Architecture v1.0',DATE '2026-08-28','NOT_SCREENED',NULL,'Classify plant production scope as grinding; terminal/logistics component migrates separately.','STAGED'),
('PL-CN-SC-000008','Dujiangyan Lafarge/Holcim','CTY-CN','SUB-CN-SC','INTEGRATED','TITAN Sustainability Pilot / Architecture v1.0',DATE '2026-08-28','NOT_SCREENED',NULL,'Plant identity preserved across corporate naming/ownership context; aliases/ownership handled separately.','STAGED');

COMMIT;
