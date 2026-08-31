-- PG-02 Temporal & Relationship Core acceptance tests
-- Run only in disposable test database after V001-V007.
\set ON_ERROR_STOP on

BEGIN;

-- Synthetic entity fixtures. All rolled back at end.
INSERT INTO titan_core.entity_registry(entity_id,entity_type_code,canonical_name,country_geo_id) VALUES
('CG-TST-HOLDCO','CORPORATE_GROUP','PG02 Test HoldCo','CTY-IN'),
('CO-TST-OPERA','LEGAL_ENTITY','PG02 Test Operator A','CTY-IN'),
('CO-TST-OPERB','LEGAL_ENTITY','PG02 Test Operator B','CTY-IN'),
('PW-IN-UP-TST001','POWER_ASSET','PG02 Shared Solar','CTY-IN'),
('BND-IN-TST001','BOUNDARY','PG02 Test Boundary','CTY-IN');

INSERT INTO titan_core.boundary_master(boundary_id,boundary_type_code,canonical_name,owner_entity_id)
VALUES ('BND-IN-TST001','ORGANIZATIONAL','PG02 Organizational Boundary','CG-TST-HOLDCO');

-- T001: adjacent ownership periods are valid.
INSERT INTO titan_core.ownership_interest
(owner_entity_id,owned_entity_id,ownership_interest_type_code,interest_class,economic_share,valid_from,valid_to)
VALUES
('CG-TST-HOLDCO','CO-TST-OPERA','DIRECT_EQUITY','ordinary',0.60,DATE '2020-01-01',DATE '2024-12-31'),
('CG-TST-HOLDCO','CO-TST-OPERA','DIRECT_EQUITY','ordinary',0.70,DATE '2025-01-01',NULL);

-- T002: overlapping same owner/owned/class period must fail.
DO $$
DECLARE caught boolean := false;
BEGIN
    BEGIN
        INSERT INTO titan_core.ownership_interest
        (owner_entity_id,owned_entity_id,ownership_interest_type_code,interest_class,economic_share,valid_from,valid_to)
        VALUES ('CG-TST-HOLDCO','CO-TST-OPERA','DIRECT_EQUITY','ordinary',0.65,DATE '2024-06-01',DATE '2025-06-30');
    EXCEPTION WHEN exclusion_violation THEN
        caught := true;
    END;
    IF NOT caught THEN RAISE EXCEPTION 'PG02-T002 overlapping ownership was not rejected'; END IF;
END;
$$;

-- T003: a second different owner may coexist for a JV.
INSERT INTO titan_core.ownership_interest
(owner_entity_id,owned_entity_id,ownership_interest_type_code,interest_class,economic_share,valid_from,valid_to)
VALUES ('CO-TST-OPERB','CO-TST-OPERA','JV_EQUITY','ordinary',0.30,DATE '2025-01-01',NULL);

-- T004: one primary operator at a time.
INSERT INTO titan_core.operating_control
(controller_entity_id,controlled_entity_id,control_role_code,valid_from,valid_to)
VALUES ('CO-TST-OPERA','PL-IN-UP-000018','PRIMARY_OPERATOR',DATE '2025-01-01',NULL);

DO $$
DECLARE caught boolean := false;
BEGIN
    BEGIN
        INSERT INTO titan_core.operating_control
        (controller_entity_id,controlled_entity_id,control_role_code,valid_from,valid_to)
        VALUES ('CO-TST-OPERB','PL-IN-UP-000018','PRIMARY_OPERATOR',DATE '2026-01-01',NULL);
    EXCEPTION WHEN exclusion_violation THEN
        caught := true;
    END;
    IF NOT caught THEN RAISE EXCEPTION 'PG02-T004 overlapping primary operators were not rejected'; END IF;
END;
$$;

-- T005: manager can coexist with primary operator.
INSERT INTO titan_core.operating_control
(controller_entity_id,controlled_entity_id,control_role_code,valid_from,valid_to)
VALUES ('CO-TST-OPERB','PL-IN-UP-000018','MANAGER',DATE '2026-01-01',NULL);

-- T006: one primary physical location at a time for an asset.
INSERT INTO titan_core.site_asset_relationship
(site_id,asset_entity_id,site_relationship_type_code,valid_from,valid_to)
VALUES ('SITE-IN-UP-000001','PW-IN-UP-TST001','PRIMARY_LOCATION',DATE '2025-01-01',NULL);

DO $$
DECLARE caught boolean := false;
BEGIN
    BEGIN
        INSERT INTO titan_core.site_asset_relationship
        (site_id,asset_entity_id,site_relationship_type_code,valid_from,valid_to)
        VALUES ('SITE-IN-RJ-000001','PW-IN-UP-TST001','PRIMARY_LOCATION',DATE '2026-01-01',NULL);
    EXCEPTION WHEN exclusion_violation THEN
        caught := true;
    END;
    IF NOT caught THEN RAISE EXCEPTION 'PG02-T006 overlapping primary site assignments were not rejected'; END IF;
END;
$$;

-- T007: fixed allocation sums to 1.0.
INSERT INTO titan_core.allocation_rule
(allocation_rule_id,shared_asset_id,allocation_method_code,allocation_metric_code,valid_from,valid_to)
VALUES ('ALLOC-PG02-TST001','PW-IN-UP-TST001','FIXED_SHARE','ELECTRICITY_MWH',DATE '2025-01-01',NULL);

INSERT INTO titan_core.allocation_share(allocation_rule_id,beneficiary_entity_id,allocation_share) VALUES
('ALLOC-PG02-TST001','PL-IN-UP-000018',0.60),
('ALLOC-PG02-TST001','PL-IN-RJ-000002',0.40);

SET CONSTRAINTS ct_allocation_share_total IMMEDIATE;
SET CONSTRAINTS ct_allocation_share_total DEFERRED;

-- T008: allocation over 100% must fail.
DO $$
DECLARE caught boolean := false;
BEGIN
    BEGIN
        INSERT INTO titan_core.allocation_share(allocation_rule_id,beneficiary_entity_id,allocation_share)
        VALUES ('ALLOC-PG02-TST001','PL-IN-KA-000006',0.10);
        SET CONSTRAINTS ct_allocation_share_total IMMEDIATE;
    EXCEPTION WHEN OTHERS THEN
        caught := true;
    END;
    SET CONSTRAINTS ct_allocation_share_total DEFERRED;
    IF NOT caught THEN RAISE EXCEPTION 'PG02-T008 allocation over 1.0 was not rejected'; END IF;
END;
$$;

-- T009: shared relationship can reference its own asset allocation rule.
INSERT INTO titan_core.shared_asset_relationship
(shared_asset_id,beneficiary_entity_id,shared_service_type_code,allocation_rule_id,valid_from,valid_to)
VALUES
('PW-IN-UP-TST001','PL-IN-UP-000018','POWER','ALLOC-PG02-TST001',DATE '2025-01-01',NULL),
('PW-IN-UP-TST001','PL-IN-RJ-000002','POWER','ALLOC-PG02-TST001',DATE '2025-01-01',NULL);

-- T010: mismatched allocation rule asset must fail.
INSERT INTO titan_core.entity_registry(entity_id,entity_type_code,canonical_name,country_geo_id)
VALUES ('PW-IN-RJ-TST002','POWER_ASSET','PG02 Other Solar','CTY-IN');

INSERT INTO titan_core.allocation_rule
(allocation_rule_id,shared_asset_id,allocation_method_code,allocation_metric_code,valid_from)
VALUES ('ALLOC-PG02-TST002','PW-IN-RJ-TST002','FIXED_SHARE','ELECTRICITY_MWH',DATE '2025-01-01');

DO $$
DECLARE caught boolean := false;
BEGIN
    BEGIN
        INSERT INTO titan_core.shared_asset_relationship
        (shared_asset_id,beneficiary_entity_id,shared_service_type_code,allocation_rule_id,valid_from)
        VALUES ('PW-IN-UP-TST001','PL-IN-KA-000006','POWER','ALLOC-PG02-TST002',DATE '2025-01-01');
    EXCEPTION WHEN OTHERS THEN
        caught := true;
    END;
    IF NOT caught THEN RAISE EXCEPTION 'PG02-T010 mismatched allocation rule was not rejected'; END IF;
END;
$$;

-- T011: boundary versions must not overlap.
INSERT INTO titan_core.boundary_version(boundary_id,version_no,valid_from,valid_to)
VALUES ('BND-IN-TST001',1,DATE '2020-01-01',DATE '2024-12-31');

INSERT INTO titan_core.boundary_version(boundary_id,version_no,valid_from,valid_to,supersedes_boundary_version_id)
SELECT 'BND-IN-TST001',2,DATE '2025-01-01',NULL,boundary_version_id
FROM titan_core.boundary_version
WHERE boundary_id='BND-IN-TST001' AND version_no=1;

DO $$
DECLARE caught boolean := false;
BEGIN
    BEGIN
        INSERT INTO titan_core.boundary_version(boundary_id,version_no,valid_from,valid_to)
        VALUES ('BND-IN-TST001',3,DATE '2024-06-01',DATE '2025-06-01');
    EXCEPTION WHEN exclusion_violation THEN
        caught := true;
    END;
    IF NOT caught THEN RAISE EXCEPTION 'PG02-T011 overlapping boundary version was not rejected'; END IF;
END;
$$;

-- T012: boundary can include multiple entities with explicit roles/shares.
INSERT INTO titan_core.boundary_member(boundary_version_id,member_entity_id,boundary_member_role_code,inclusion_share)
SELECT boundary_version_id,'PL-IN-UP-000018','INCLUDED',1.0
FROM titan_core.boundary_version WHERE boundary_id='BND-IN-TST001' AND version_no=2;

INSERT INTO titan_core.boundary_member(boundary_version_id,member_entity_id,boundary_member_role_code,inclusion_share)
SELECT boundary_version_id,'PW-IN-UP-TST001','PARTIAL',0.6
FROM titan_core.boundary_version WHERE boundary_id='BND-IN-TST001' AND version_no=2;

-- T013: operational statuses cannot overlap.
INSERT INTO titan_core.operational_status_history(entity_id,operational_status_code,valid_from,valid_to)
VALUES ('PL-IN-UP-000018','OPERATING',DATE '2025-01-01',NULL);

DO $$
DECLARE caught boolean := false;
BEGIN
    BEGIN
        INSERT INTO titan_core.operational_status_history(entity_id,operational_status_code,valid_from,valid_to)
        VALUES ('PL-IN-UP-000018','MOTHBALLED',DATE '2026-06-01',NULL);
    EXCEPTION WHEN exclusion_violation THEN
        caught := true;
    END;
    IF NOT caught THEN RAISE EXCEPTION 'PG02-T013 overlapping operational statuses were not rejected'; END IF;
END;
$$;

-- T014: asset event is separate from interval status and can coexist.
INSERT INTO titan_core.asset_event(asset_event_id,subject_entity_id,asset_event_type_code,event_date,event_notes)
VALUES ('EVT-PG02-TST001','PL-IN-UP-000018','RETROFIT',DATE '2026-03-15','Synthetic retrofit event; does not overwrite operating-status interval.');

-- Final count controls.
DO $$
DECLARE n_boundary_versions integer;
DECLARE n_shares integer;
BEGIN
    SELECT count(*) INTO n_boundary_versions FROM titan_core.boundary_version WHERE boundary_id='BND-IN-TST001';
    SELECT count(*) INTO n_shares FROM titan_core.allocation_share WHERE allocation_rule_id='ALLOC-PG02-TST001';

    IF n_boundary_versions <> 2 THEN RAISE EXCEPTION 'PG02-T015 expected 2 valid boundary versions'; END IF;
    IF n_shares <> 2 THEN RAISE EXCEPTION 'PG02-T016 failed allocation-overrun insert was not rolled back locally'; END IF;
END;
$$;

ROLLBACK;

\echo 'PG-02 temporal/relationship tests passed if execution reached this line.'
