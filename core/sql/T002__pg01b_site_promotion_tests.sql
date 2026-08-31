-- PG-01B post-site-resolution/promotion acceptance tests
\set ON_ERROR_STOP on

DO $$
DECLARE n_plants integer;
DECLARE n_sites integer;
DECLARE n_promoted integer;
DECLARE n_bad_links integer;
BEGIN
    SELECT count(*) INTO n_promoted
    FROM titan_migration.pg01_plant_identity_stage
    WHERE migration_status='PROMOTED';

    SELECT count(*) INTO n_plants
    FROM titan_core.plant_master
    WHERE plant_id IN (
        'PL-IN-RJ-000002','PL-IN-GJ-000003','PL-IN-MP-000013','PL-IN-UP-000018','PL-IN-KA-000006',
        'PL-CN-AH-000004','PL-CN-AH-000002','PL-CN-AH-000003','PL-CN-AH-000019','PL-CN-SC-000008'
    );

    SELECT count(DISTINCT site_id) INTO n_sites
    FROM titan_core.plant_master
    WHERE plant_id IN (
        'PL-IN-RJ-000002','PL-IN-GJ-000003','PL-IN-MP-000013','PL-IN-UP-000018','PL-IN-KA-000006',
        'PL-CN-AH-000004','PL-CN-AH-000002','PL-CN-AH-000003','PL-CN-AH-000019','PL-CN-SC-000008'
    );

    SELECT count(*) INTO n_bad_links
    FROM titan_core.plant_master p
    LEFT JOIN titan_core.entity_registry pe ON pe.entity_id=p.plant_id AND pe.entity_type_code='PHYSICAL_PLANT'
    LEFT JOIN titan_core.physical_site ps ON ps.site_id=p.site_id
    LEFT JOIN titan_core.entity_registry se ON se.entity_id=ps.site_id AND se.entity_type_code='PHYSICAL_SITE'
    WHERE p.plant_id IN (
        'PL-IN-RJ-000002','PL-IN-GJ-000003','PL-IN-MP-000013','PL-IN-UP-000018','PL-IN-KA-000006',
        'PL-CN-AH-000004','PL-CN-AH-000002','PL-CN-AH-000003','PL-CN-AH-000019','PL-CN-SC-000008'
    )
      AND (pe.entity_id IS NULL OR ps.site_id IS NULL OR se.entity_id IS NULL);

    IF n_promoted <> 10 THEN RAISE EXCEPTION 'PG01B-T001 expected 10 promoted staging rows, found %', n_promoted; END IF;
    IF n_plants <> 10 THEN RAISE EXCEPTION 'PG01B-T002 expected 10 core pilot plants, found %', n_plants; END IF;
    IF n_sites <> 10 THEN RAISE EXCEPTION 'PG01B-T003 expected 10 distinct physical sites, found %', n_sites; END IF;
    IF n_bad_links <> 0 THEN RAISE EXCEPTION 'PG01B-T004 found % broken typed plant/site links', n_bad_links; END IF;
END;
$$;

DO $$
DECLARE mismatches integer;
BEGIN
    WITH expected(plant_id,site_id) AS (
        VALUES
        ('PL-IN-RJ-000002','SITE-IN-RJ-000001'),
        ('PL-IN-GJ-000003','SITE-IN-GJ-000001'),
        ('PL-IN-MP-000013','SITE-IN-MP-000001'),
        ('PL-IN-UP-000018','SITE-IN-UP-000001'),
        ('PL-IN-KA-000006','SITE-IN-KA-000001'),
        ('PL-CN-AH-000004','SITE-CN-AH-000001'),
        ('PL-CN-AH-000002','SITE-CN-AH-000002'),
        ('PL-CN-AH-000003','SITE-CN-AH-000003'),
        ('PL-CN-AH-000019','SITE-CN-AH-000004'),
        ('PL-CN-SC-000008','SITE-CN-SC-000001')
    )
    SELECT count(*) INTO mismatches
    FROM expected e
    LEFT JOIN titan_core.plant_master p ON p.plant_id=e.plant_id
    WHERE p.site_id IS DISTINCT FROM e.site_id;

    IF mismatches <> 0 THEN
        RAISE EXCEPTION 'PG01B-T005 expected PL-to-SITE map has % mismatches', mismatches;
    END IF;
END;
$$;

DO $$
DECLARE duplicate_site_groups integer;
BEGIN
    SELECT count(*) INTO duplicate_site_groups
    FROM (
        SELECT site_id
        FROM titan_core.plant_master
        WHERE plant_id IN (
            'PL-IN-RJ-000002','PL-IN-GJ-000003','PL-IN-MP-000013','PL-IN-UP-000018','PL-IN-KA-000006',
            'PL-CN-AH-000004','PL-CN-AH-000002','PL-CN-AH-000003','PL-CN-AH-000019','PL-CN-SC-000008'
        )
        GROUP BY site_id
        HAVING count(*) > 1
    ) x;

    IF duplicate_site_groups <> 0 THEN
        RAISE EXCEPTION 'PG01B-T006 unexpected co-location among pilot PL records';
    END IF;
END;
$$;

\echo 'PG-01B site-resolution and promotion tests passed if execution reached this line.'
