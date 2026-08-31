-- PG-01B permanent physical SITE issuance for the 10-asset pilot
-- Evidence screen completed 2026-08-29.
-- Existing TITAN PL IDs remain unchanged.
BEGIN;

DO $$
DECLARE n integer;
BEGIN
    SELECT count(*) INTO n
    FROM titan_migration.pg01_plant_identity_stage
    WHERE site_resolution_status='NOT_SCREENED'
      AND resolved_site_id IS NULL
      AND migration_status='STAGED';

    IF n <> 10 THEN
        RAISE EXCEPTION 'PG01B expected 10 unresolved staged pilot plants before site issuance, found %', n;
    END IF;
END;
$$;

INSERT INTO titan_core.entity_registry(entity_id,entity_type_code,canonical_name,country_geo_id) VALUES
('SITE-IN-RJ-000001','PHYSICAL_SITE','Kotputli Cement Works Site','CTY-IN'),
('SITE-IN-GJ-000001','PHYSICAL_SITE','Narmada Cement Jafrabad Works Site','CTY-IN'),
('SITE-IN-MP-000001','PHYSICAL_SITE','RCCPL Maihar Integrated Unit Site','CTY-IN'),
('SITE-IN-UP-000001','PHYSICAL_SITE','Kundanganj Grinding Unit Site','CTY-IN'),
('SITE-IN-KA-000001','PHYSICAL_SITE','JK Cement Works Muddapur Site','CTY-IN'),
('SITE-CN-AH-000001','PHYSICAL_SITE','Wuhu Conch Site','CTY-CN'),
('SITE-CN-AH-000002','PHYSICAL_SITE','Tongling Conch Site','CTY-CN'),
('SITE-CN-AH-000003','PHYSICAL_SITE','Ningguo Cement Plant Site','CTY-CN'),
('SITE-CN-AH-000004','PHYSICAL_SITE','Ma''anshan Conch Site','CTY-CN'),
('SITE-CN-SC-000001','PHYSICAL_SITE','Dujiangyan Lafarge/Holcim Site','CTY-CN');

INSERT INTO titan_core.physical_site(site_id,primary_geo_id,site_status_code) VALUES
('SITE-IN-RJ-000001','SUB-IN-RJ','ACTIVE'),
('SITE-IN-GJ-000001','SUB-IN-GJ','ACTIVE'),
('SITE-IN-MP-000001','SUB-IN-MP','ACTIVE'),
('SITE-IN-UP-000001','SUB-IN-UP','ACTIVE'),
('SITE-IN-KA-000001','SUB-IN-KA','ACTIVE'),
('SITE-CN-AH-000001','SUB-CN-AH','ACTIVE'),
('SITE-CN-AH-000002','SUB-CN-AH','ACTIVE'),
('SITE-CN-AH-000003','SUB-CN-AH','ACTIVE'),
('SITE-CN-AH-000004','SUB-CN-AH','ACTIVE'),
('SITE-CN-SC-000001','SUB-CN-SC','ACTIVE');

INSERT INTO titan_core.site_address_history(site_id,address_text,locality_text,source_id) VALUES
('SITE-IN-RJ-000001','Village & Post Mohanpura, Tehsil Kotputli, Rajasthan 303108','Mohanpura / Kotputli','PG01B-SRC-001'),
('SITE-IN-GJ-000001','Village Babarkot, Taluka Jafrabad, District Amreli, Gujarat 365540','Babarkot / Jafrabad','PG01B-SRC-001'),
('SITE-IN-MP-000001','Village Bharauli-Itahara, Maihar, District Satna, Madhya Pradesh','Bharauli-Itahara / Maihar','PG01B-SRC-006'),
('SITE-IN-UP-000001','Village Karanpur, near Kundanganj Railway Station, District Raebareli, Uttar Pradesh 229303','Karanpur / Kundanganj','PG01B-SRC-005'),
('SITE-IN-KA-000001','P.O. Muddapur, Taluka Mudhol, District Bagalkot, Karnataka 587122','Muddapur / Mudhol','PG01B-SRC-008'),
('SITE-CN-AH-000001','安徽省芜湖市繁昌区繁阳镇代冲村','Daichong Village / Fanyang / Fanchang / Wuhu','PG01B-SRC-010'),
('SITE-CN-AH-000002','安徽省铜陵市郊区古圣村','Gusheng Village / Tongling','PG01B-SRC-012'),
('SITE-CN-AH-000003','安徽省宁国市港口镇宁国水泥厂','Gangkou Town / Ningguo','PG01B-SRC-014'),
('SITE-CN-AH-000004','安徽省马鞍山市慈湖国家高新开发区海螺大道','Cihu National High-Tech Development Zone / Maanshan','PG01B-SRC-016'),
('SITE-CN-SC-000001','四川省都江堰市经济开发区九鼎大道21号','Jiuding Avenue 21 / Dujiangyan','PG01B-SRC-018');

UPDATE titan_migration.pg01_plant_identity_stage
SET site_resolution_status='UNIQUE_SITE_CONFIRMED',
    resolved_site_id=CASE legacy_plant_id
        WHEN 'PL-IN-RJ-000002' THEN 'SITE-IN-RJ-000001'
        WHEN 'PL-IN-GJ-000003' THEN 'SITE-IN-GJ-000001'
        WHEN 'PL-IN-MP-000013' THEN 'SITE-IN-MP-000001'
        WHEN 'PL-IN-UP-000018' THEN 'SITE-IN-UP-000001'
        WHEN 'PL-IN-KA-000006' THEN 'SITE-IN-KA-000001'
        WHEN 'PL-CN-AH-000004' THEN 'SITE-CN-AH-000001'
        WHEN 'PL-CN-AH-000002' THEN 'SITE-CN-AH-000002'
        WHEN 'PL-CN-AH-000003' THEN 'SITE-CN-AH-000003'
        WHEN 'PL-CN-AH-000019' THEN 'SITE-CN-AH-000004'
        WHEN 'PL-CN-SC-000008' THEN 'SITE-CN-SC-000001'
    END,
    site_resolution_notes='PG-01B official company/regulatory evidence screen completed 2026-08-29; see implementation workbook site evidence register.',
    migration_status='READY_FOR_PROMOTION'
WHERE legacy_plant_id IN (
    'PL-IN-RJ-000002','PL-IN-GJ-000003','PL-IN-MP-000013','PL-IN-UP-000018','PL-IN-KA-000006',
    'PL-CN-AH-000004','PL-CN-AH-000002','PL-CN-AH-000003','PL-CN-AH-000019','PL-CN-SC-000008'
);

DO $$
DECLARE n_ready integer;
DECLARE n_sites integer;
BEGIN
    SELECT count(*) INTO n_ready
    FROM titan_migration.pg01_site_resolution_gate
    WHERE site_gate_passed AND migration_status='READY_FOR_PROMOTION';

    SELECT count(DISTINCT resolved_site_id) INTO n_sites
    FROM titan_migration.pg01_plant_identity_stage
    WHERE migration_status='READY_FOR_PROMOTION';

    IF n_ready <> 10 THEN
        RAISE EXCEPTION 'PG01B site gate expected 10 ready rows, found %', n_ready;
    END IF;
    IF n_sites <> 10 THEN
        RAISE EXCEPTION 'PG01B expected 10 distinct SITE IDs, found %', n_sites;
    END IF;
END;
$$;

COMMIT;
