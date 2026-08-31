\set ON_ERROR_STOP on
\echo 'PG-09 post-migration structural gate'

DO $$
DECLARE missing text;
DECLARE n_plants integer;
DECLARE n_sites integer;
DECLARE n_bad integer;
DECLARE n_assurance integer;
BEGIN
    WITH required(obj) AS (
        VALUES
        ('titan_core.entity_registry'),
        ('titan_core.physical_site'),
        ('titan_core.plant_master'),
        ('titan_core.source_document'),
        ('titan_core.observation'),
        ('titan_core.compliance_obligation'),
        ('titan_core.co2_batch'),
        ('titan_core.trade_shipment'),
        ('titan_core.water_balance'),
        ('titan_core.target_version'),
        ('titan_core.dataset_snapshot'),
        ('titan_core.model_run'),
        ('titan_core.publication_snapshot')
    )
    SELECT string_agg(obj, ', ' ORDER BY obj) INTO missing
    FROM required WHERE to_regclass(obj) IS NULL;
    IF missing IS NOT NULL THEN
        RAISE EXCEPTION 'Missing critical objects after migrations: %',missing;
    END IF;

    SELECT count(*) INTO n_assurance FROM pg_class c
    JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE n.nspname='titan_ref' AND c.relname='assurance_level' AND c.relkind='r';
    IF n_assurance<>1 THEN
        RAISE EXCEPTION 'Expected exactly one titan_ref.assurance_level table, found %',n_assurance;
    END IF;

    SELECT count(*) INTO n_plants FROM titan_core.plant_master
    WHERE plant_id IN (
        'PL-IN-RJ-000002','PL-IN-GJ-000003','PL-IN-MP-000013','PL-IN-UP-000018','PL-IN-KA-000006',
        'PL-CN-AH-000004','PL-CN-AH-000002','PL-CN-AH-000003','PL-CN-AH-000019','PL-CN-SC-000008');
    SELECT count(DISTINCT site_id) INTO n_sites FROM titan_core.plant_master
    WHERE plant_id IN (
        'PL-IN-RJ-000002','PL-IN-GJ-000003','PL-IN-MP-000013','PL-IN-UP-000018','PL-IN-KA-000006',
        'PL-CN-AH-000004','PL-CN-AH-000002','PL-CN-AH-000003','PL-CN-AH-000019','PL-CN-SC-000008');
    SELECT count(*) INTO n_bad
    FROM titan_core.plant_master p
    LEFT JOIN titan_core.entity_registry e ON e.entity_id=p.plant_id AND e.entity_type_code='PHYSICAL_PLANT'
    LEFT JOIN titan_core.physical_site s ON s.site_id=p.site_id
    WHERE p.plant_id IN (
        'PL-IN-RJ-000002','PL-IN-GJ-000003','PL-IN-MP-000013','PL-IN-UP-000018','PL-IN-KA-000006',
        'PL-CN-AH-000004','PL-CN-AH-000002','PL-CN-AH-000003','PL-CN-AH-000019','PL-CN-SC-000008')
      AND (e.entity_id IS NULL OR s.site_id IS NULL);
    IF n_plants<>10 OR n_sites<>10 OR n_bad<>0 THEN
        RAISE EXCEPTION 'Pilot migration gate failed: plants %, sites %, broken links %',n_plants,n_sites,n_bad;
    END IF;
END;
$$;

SELECT 'tables' AS object_type,count(*) AS object_count
FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE n.nspname IN ('titan_ref','titan_core','titan_migration') AND c.relkind='r'
UNION ALL
SELECT 'views',count(*) FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE n.nspname IN ('titan_ref','titan_core','titan_migration') AND c.relkind='v'
UNION ALL
SELECT 'functions',count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
WHERE n.nspname IN ('titan_ref','titan_core','titan_migration')
ORDER BY 1;
