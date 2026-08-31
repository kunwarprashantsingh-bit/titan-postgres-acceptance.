-- PG-01 controlled vocabulary and pilot geography seed
BEGIN;

INSERT INTO titan_ref.entity_type (entity_type_code,id_prefix,domain_name,definition) VALUES
('GEO_REGION','REG','Geographic','Region'),
('GEO_COUNTRY','CTY','Geographic','Country'),
('GEO_SUBNATIONAL','SUB','Geographic','State/province/emirate or nested subnational unit'),
('PHYSICAL_SITE','SITE','Asset','Physical geospatial/land-envelope site container'),
('INDUSTRIAL_CLUSTER','CLU','Infrastructure','Industrial or CCUS cluster'),
('POLICY','POL','Policy','Policy or regulation'),
('POLICY_TARGET','PTG','Policy','Government climate/industrial target'),
('CARBON_MECHANISM','CBM','Policy','Carbon pricing or border mechanism'),
('STANDARD','STD','Policy','Product/construction standard'),
('PROCUREMENT_RULE','GPP','Policy','Green procurement rule'),
('INCENTIVE','INC','Policy','Grant/tax credit/CfD or similar incentive'),
('ASSOCIATION','AS','Institution','Industry association'),
('CORPORATE_GROUP','CG','Corporate','Ultimate/strategic group'),
('LEGAL_ENTITY','CO','Corporate','Registered legal/operating entity'),
('PHYSICAL_PLANT','PL','Asset','Integrated/grinding/terminal/packing plant identity'),
('CLINKER_LINE','KL','Asset','Individual clinker production line'),
('GRINDING_SYSTEM','GR','Asset','Individual grinding system'),
('QUARRY','QR','Asset','Raw-material quarry or mine'),
('POWER_ASSET','PW','Asset','Captive/renewable/storage power asset'),
('WHR_ASSET','WHR','Asset','Waste-heat recovery system'),
('FUEL_SYSTEM','FS','Asset','Fuel handling/feed system'),
('SCM_SOURCE','SCM','Material','Supplementary cementitious material source'),
('WATER_SYSTEM','WAT','Asset','Water source/treatment/recycling system'),
('LOGISTICS_ASSET','LOG','Asset','Rail/road/river/port/logistics link'),
('ENV_PERMIT','ENV','Compliance','Environmental/mining permit'),
('SUSTAINABILITY_PROJECT','PRJ','Project','Physical sustainability initiative'),
('CCUS_PROJECT','CCS','Project','Capture/transport/storage project'),
('PRODUCT','PROD','Product','Cement/concrete product'),
('EPD','EPD','Product/Evidence','Environmental Product Declaration'),
('TARGET','TGT','Commitment','Entity target/commitment'),
('OBSERVATION','OBS','Fact','Time-stamped structured fact'),
('CLAIM','CLM','Evidence','Material public assertion'),
('SOURCE','SRC','Evidence','Evidence document/source'),
('CONFLICT','CNF','Evidence','Evidence conflict'),
('CHANGE','CHG','Governance','Audit-log record');

INSERT INTO titan_ref.geo_type (geo_type_code,entity_type_code,hierarchy_rank,definition) VALUES
('REGION','GEO_REGION',10,'Global/regional geography'),
('COUNTRY','GEO_COUNTRY',20,'Country'),
('SUBNATIONAL','GEO_SUBNATIONAL',30,'State/province/emirate or nested administrative unit');

INSERT INTO titan_ref.site_status (site_status_code,definition) VALUES
('ACTIVE','Physical site is active'),
('PARTIAL','Physical site is partially active'),
('CLOSED','Physical site is closed'),
('REDEVELOPED','Former industrial site redeveloped/re-purposed'),
('UNKNOWN','Current physical-site status is not verified');

INSERT INTO titan_ref.plant_type (plant_type_code,definition) VALUES
('INTEGRATED','Clinker production and cement manufacture'),
('CLINKER_ONLY','Clinker manufacture without cement grinding as plant scope'),
('GRINDING','Cement grinding/blending without onsite clinker production'),
('TERMINAL','Distribution/terminal asset without production'),
('PACKING','Packing-only asset'),
('OTHER','Other physical plant type requiring explicit documentation');

INSERT INTO titan_ref.alias_type (alias_type_code,definition) VALUES
('OFFICIAL_LOCAL','Official local-language name'),
('OFFICIAL_EN','Official English name'),
('TRADE','Trade/commercial name'),
('HISTORICAL','Historical name'),
('TRANSLITERATION','Transliteration/romanization'),
('REGULATORY','Name/spelling used by regulator'),
('ABBREVIATION','Abbreviation');

INSERT INTO titan_ref.genealogy_type (genealogy_type_code,definition) VALUES
('PREDECESSOR_OF','Source entity is predecessor of target'),
('SUCCESSOR_OF','Source entity is successor of target'),
('SPLIT_INTO','Source entity split into target entity/entities'),
('MERGED_INTO','Source entity merged into target'),
('REPLACED_BY','Source physical asset replaced by target'),
('ADMIN_ROLLUP_OF','Administrative/reporting roll-up only; no physical merge implied');

-- Geography entities used by the 10-pilot PG-01 migration dry-run.
INSERT INTO titan_core.entity_registry(entity_id,entity_type_code,canonical_name,country_geo_id) VALUES
('REG-ASIA','GEO_REGION','Asia',NULL),
('CTY-IN','GEO_COUNTRY','India',NULL),
('CTY-CN','GEO_COUNTRY','China',NULL),
('SUB-IN-RJ','GEO_SUBNATIONAL','Rajasthan',NULL),
('SUB-IN-GJ','GEO_SUBNATIONAL','Gujarat',NULL),
('SUB-IN-MP','GEO_SUBNATIONAL','Madhya Pradesh',NULL),
('SUB-IN-UP','GEO_SUBNATIONAL','Uttar Pradesh',NULL),
('SUB-IN-KA','GEO_SUBNATIONAL','Karnataka',NULL),
('SUB-CN-AH','GEO_SUBNATIONAL','Anhui',NULL),
('SUB-CN-SC','GEO_SUBNATIONAL','Sichuan',NULL);

INSERT INTO titan_core.geo_unit(geo_id,geo_type_code,parent_geo_id,official_name,iso_alpha2,iso_3166_2) VALUES
('REG-ASIA','REGION',NULL,'Asia',NULL,NULL),
('CTY-IN','COUNTRY','REG-ASIA','India','IN',NULL),
('CTY-CN','COUNTRY','REG-ASIA','China','CN',NULL),
('SUB-IN-RJ','SUBNATIONAL','CTY-IN','Rajasthan',NULL,'IN-RJ'),
('SUB-IN-GJ','SUBNATIONAL','CTY-IN','Gujarat',NULL,'IN-GJ'),
('SUB-IN-MP','SUBNATIONAL','CTY-IN','Madhya Pradesh',NULL,'IN-MP'),
('SUB-IN-UP','SUBNATIONAL','CTY-IN','Uttar Pradesh',NULL,'IN-UP'),
('SUB-IN-KA','SUBNATIONAL','CTY-IN','Karnataka',NULL,'IN-KA'),
('SUB-CN-AH','SUBNATIONAL','CTY-CN','Anhui',NULL,'CN-AH'),
('SUB-CN-SC','SUBNATIONAL','CTY-CN','Sichuan',NULL,'CN-SC');

UPDATE titan_core.entity_registry SET country_geo_id='CTY-IN'
 WHERE entity_id IN ('CTY-IN','SUB-IN-RJ','SUB-IN-GJ','SUB-IN-MP','SUB-IN-UP','SUB-IN-KA');

UPDATE titan_core.entity_registry SET country_geo_id='CTY-CN'
 WHERE entity_id IN ('CTY-CN','SUB-CN-AH','SUB-CN-SC');

COMMIT;
