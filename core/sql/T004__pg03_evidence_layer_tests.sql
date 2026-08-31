-- PG-03 Evidence Layer acceptance tests
-- Run in disposable database after V001-V008.
\set ON_ERROR_STOP on

BEGIN;

-- Synthetic source identities.
INSERT INTO titan_core.entity_registry(entity_id,entity_type_code,canonical_name,country_geo_id) VALUES
('SRC-TST-0001','SOURCE','PG03 Source Document A','CTY-IN'),
('SRC-TST-0002','SOURCE','PG03 Source Document B','CTY-IN'),
('SRC-TST-0003','SOURCE','PG03 Source Corrected Edition','CTY-IN'),
('CNF-TST-0001','CONFLICT','PG03 Synthetic Conflict','CTY-IN');

INSERT INTO titan_core.source_document
(source_id,publisher_name,document_title,document_type_code,evidence_grade_code,publication_date,language_code,mime_type,file_size_bytes,canonical_sha256,archival_status_code)
VALUES
('SRC-TST-0001','Test Regulator','Permit A','PERMIT_EIA','P1',DATE '2026-01-01','en','application/pdf',1000,repeat('a',64),'SNAPSHOT_RETAINED'),
('SRC-TST-0002','Test Company','Report B','SUSTAINABILITY_REPORT','P2',DATE '2026-02-01','en','application/pdf',2000,repeat('b',64),'LIVE_ONLY'),
('SRC-TST-0003','Test Regulator','Permit A — corrected','PERMIT_EIA','P1',DATE '2026-03-01','en','application/pdf',1100,repeat('c',64),'SNAPSHOT_RETAINED');

-- T001: duplicate document hash must fail.
DO $$
DECLARE caught boolean := false;
BEGIN
    INSERT INTO titan_core.entity_registry(entity_id,entity_type_code,canonical_name,country_geo_id)
    VALUES ('SRC-TST-0099','SOURCE','Duplicate Hash Source','CTY-IN');

    BEGIN
        INSERT INTO titan_core.source_document
        (source_id,publisher_name,document_title,document_type_code,evidence_grade_code,language_code,canonical_sha256,archival_status_code)
        VALUES ('SRC-TST-0099','Mirror Host','Same PDF','PERMIT_EIA','P1','en',repeat('a',64),'LIVE_ONLY');
    EXCEPTION WHEN unique_violation THEN
        caught := true;
    END;

    IF NOT caught THEN RAISE EXCEPTION 'PG03-T001 duplicate content hash was not rejected'; END IF;
END;
$$;

-- T002: multiple endpoint URLs may point to same document.
INSERT INTO titan_core.source_endpoint(endpoint_id,endpoint_url,endpoint_access_status_code)
VALUES
('ENDP-TST-0001','https://example.test/regulator/permit-a.pdf','ACTIVE'),
('ENDP-TST-0002','https://mirror.example.test/permit-a.pdf','ACTIVE');

INSERT INTO titan_core.endpoint_document_observation(endpoint_id,source_id,observed_at,http_status,observed_sha256)
VALUES
('ENDP-TST-0001','SRC-TST-0001',TIMESTAMPTZ '2026-01-10 00:00:00+00',200,repeat('a',64)),
('ENDP-TST-0002','SRC-TST-0001',TIMESTAMPTZ '2026-01-11 00:00:00+00',200,repeat('a',64));

-- T003: same URL can later serve corrected content without changing endpoint identity.
INSERT INTO titan_core.endpoint_document_observation(endpoint_id,source_id,observed_at,http_status,observed_sha256)
VALUES ('ENDP-TST-0001','SRC-TST-0003',TIMESTAMPTZ '2026-03-02 00:00:00+00',200,repeat('c',64));

INSERT INTO titan_core.evidence_change_event
(evidence_change_event_id,evidence_change_type_code,endpoint_id,from_source_id,to_source_id,detected_at,event_notes)
VALUES
('EVC-TST-0001','REPLACED_AT_ENDPOINT','ENDP-TST-0001','SRC-TST-0001','SRC-TST-0003',TIMESTAMPTZ '2026-03-02 00:10:00+00','Same endpoint now serves corrected source content.');

INSERT INTO titan_core.source_revision_relationship
(from_source_id,to_source_id,evidence_change_type_code,effective_at,evidence_notes)
VALUES ('SRC-TST-0001','SRC-TST-0003','CORRECTED',TIMESTAMPTZ '2026-03-01 00:00:00+00','Corrected edition preserves old source identity.');

-- T004: snapshot belongs to one source.
INSERT INTO titan_core.source_snapshot
(snapshot_id,source_id,endpoint_id,captured_at,storage_uri,content_sha256,file_size_bytes,mime_type,capture_method)
VALUES
('SNAP-TST-0001','SRC-TST-0001','ENDP-TST-0002',TIMESTAMPTZ '2026-01-11 00:05:00+00','s3://titan-test/src-tst-0001.pdf',repeat('a',64),1000,'application/pdf','DOWNLOAD');

INSERT INTO titan_core.research_session
(research_session_id,analyst_ref,started_at,session_purpose)
VALUES ('RSCH-TST-0001','analyst-test',TIMESTAMPTZ '2026-04-01 09:00:00+00','PG03 evidence replay');

INSERT INTO titan_core.extraction_record
(extraction_id,source_id,snapshot_id,research_session_id,location_ref,page_number,extracted_text,extracted_numeric_value,extracted_unit_text,extraction_method_code,reviewer_ref,extraction_confidence)
VALUES
('EXT-TST-0001','SRC-TST-0001','SNAP-TST-0001','RSCH-TST-0001','p.12, Table 3, row Capacity',12,'Capacity 3.30 Mtpa',3.30,'Mtpa','MANUAL','reviewer-test',0.99);

-- T005: extraction may not attach another source's snapshot.
INSERT INTO titan_core.source_snapshot
(snapshot_id,source_id,endpoint_id,captured_at,storage_uri,content_sha256,file_size_bytes,mime_type,capture_method)
VALUES
('SNAP-TST-0002','SRC-TST-0002',NULL,TIMESTAMPTZ '2026-02-02 00:00:00+00','s3://titan-test/src-tst-0002.pdf',repeat('b',64),2000,'application/pdf','DOWNLOAD');

DO $$
DECLARE caught boolean := false;
BEGIN
    BEGIN
        INSERT INTO titan_core.extraction_record
        (extraction_id,source_id,snapshot_id,location_ref,extracted_text,extraction_method_code)
        VALUES ('EXT-TST-0099','SRC-TST-0001','SNAP-TST-0002','p.1','Wrong snapshot','MANUAL');
    EXCEPTION WHEN OTHERS THEN
        caught := true;
    END;
    IF NOT caught THEN RAISE EXCEPTION 'PG03-T005 cross-source snapshot extraction was not rejected'; END IF;
END;
$$;

-- T006: exact numeric precision is retained separately.
INSERT INTO titan_core.numeric_precision
(precision_id,extraction_id,reported_text,decimal_places,significant_figures,rounding_increment,precision_notes)
VALUES ('PREC-TST-0001','EXT-TST-0001','3.30',2,3,0.01,'Preserve reported two decimal places; do not silently normalize to 3.3.');

-- T007: human-reviewed translation is linked to exact extraction.
INSERT INTO titan_core.translation_record
(translation_id,extraction_id,source_language_code,target_language_code,translated_text,translation_method_code,reviewer_ref)
VALUES ('TRN-TST-0001','EXT-TST-0001','en','hi','परीक्षण अनुवाद','MACHINE_ASSISTED','reviewer-test');

-- T008: same-language translation requires NONE_SAME_LANGUAGE.
DO $$
DECLARE caught boolean := false;
BEGIN
    BEGIN
        INSERT INTO titan_core.translation_record
        (translation_id,extraction_id,source_language_code,target_language_code,translated_text,translation_method_code)
        VALUES ('TRN-TST-0099','EXT-TST-0001','en','en','Bad same-language method','HUMAN');
    EXCEPTION WHEN check_violation THEN
        caught := true;
    END;
    IF NOT caught THEN RAISE EXCEPTION 'PG03-T008 invalid same-language translation method was not rejected'; END IF;
END;
$$;

-- T008B: NONE_SAME_LANGUAGE cannot be used for a real language change.
DO $$
DECLARE caught boolean := false;
BEGIN
    BEGIN
        INSERT INTO titan_core.translation_record
        (translation_id,extraction_id,source_language_code,target_language_code,translated_text,translation_method_code)
        VALUES ('TRN-TST-0098','EXT-TST-0001','en','fr','Bad no-translation method','NONE_SAME_LANGUAGE');
    EXCEPTION WHEN check_violation THEN
        caught := true;
    END;
    IF NOT caught THEN RAISE EXCEPTION 'PG03-T008B NONE_SAME_LANGUAGE with different languages was not rejected'; END IF;
END;
$$;

-- T009: conflict preserves contradictory extractions instead of overwriting.
INSERT INTO titan_core.extraction_record
(extraction_id,source_id,location_ref,extracted_text,extracted_numeric_value,extracted_unit_text,extraction_method_code)
VALUES ('EXT-TST-0002','SRC-TST-0002','p.20 Capacity table','Capacity 3.20 Mtpa',3.20,'Mtpa','MANUAL');

INSERT INTO titan_core.evidence_conflict
(conflict_id,conflict_status_code,conflict_severity_code,issue_summary,controlled_treatment)
VALUES ('CNF-TST-0001','OPEN','HIGH','Plant capacity differs between regulator and company disclosure','Retain 3.30 and 3.20 as separate sourced values until scope/date reconciliation.');

INSERT INTO titan_core.conflict_member(conflict_id,extraction_id,support_type_code,member_notes) VALUES
('CNF-TST-0001','EXT-TST-0001','CONTRADICTS','Regulator figure'),
('CNF-TST-0001','EXT-TST-0002','CONTRADICTS','Company figure');

-- T010: assurance is selective, not a blanket source flag.
INSERT INTO titan_core.entity_registry(entity_id,entity_type_code,canonical_name,country_geo_id)
VALUES ('SRC-TST-0004','SOURCE','PG03 Assurance Report','CTY-IN');

INSERT INTO titan_core.source_document
(source_id,publisher_name,document_title,document_type_code,evidence_grade_code,publication_date,language_code,archival_status_code)
VALUES ('SRC-TST-0004','Independent Assurer','Selected KPI Assurance','ASSURANCE_REPORT','P2',DATE '2026-04-01','en','LIVE_ONLY');

INSERT INTO titan_core.assurance_engagement
(assurance_id,assurance_source_id,practitioner_name,assurance_standard,assurance_level_code,period_start,period_end)
VALUES ('ASSUR-TST-0001','SRC-TST-0004','Independent Assurer','ISSA 5000','LIMITED',DATE '2025-04-01',DATE '2026-03-31');

INSERT INTO titan_core.assurance_scope_item
(assurance_id,declared_scope_text,source_location_ref,future_target_type,future_target_id)
VALUES
('ASSUR-TST-0001','Scope 1 and Scope 2 emissions only','p.4 Assurance scope','OBSERVATION','OBS-FUTURE-001');

-- T011: self revision must fail.
DO $$
DECLARE caught boolean := false;
BEGIN
    BEGIN
        INSERT INTO titan_core.source_revision_relationship
        (from_source_id,to_source_id,evidence_change_type_code)
        VALUES ('SRC-TST-0001','SRC-TST-0001','SUPERSEDED');
    EXCEPTION WHEN check_violation THEN
        caught := true;
    END;
    IF NOT caught THEN RAISE EXCEPTION 'PG03-T011 source self-revision was not rejected'; END IF;
END;
$$;

-- T012: URL uniqueness prevents duplicate endpoint identities.
DO $$
DECLARE caught boolean := false;
BEGIN
    BEGIN
        INSERT INTO titan_core.source_endpoint(endpoint_id,endpoint_url,endpoint_access_status_code)
        VALUES ('ENDP-TST-0099','https://example.test/regulator/permit-a.pdf','ACTIVE');
    EXCEPTION WHEN unique_violation THEN
        caught := true;
    END;
    IF NOT caught THEN RAISE EXCEPTION 'PG03-T012 duplicate endpoint URL was not rejected'; END IF;
END;
$$;

-- T013: hash helper returns canonical 64-character lowercase SHA-256.
DO $$
DECLARE h text;
BEGIN
    SELECT titan_core.sha256_hex(convert_to('TITAN','UTF8')) INTO h;
    IF length(h) <> 64 OR h !~ '^[0-9a-f]{64}$' THEN
        RAISE EXCEPTION 'PG03-T013 SHA256 helper returned invalid hash %', h;
    END IF;
END;
$$;

-- Final control counts.
DO $$
DECLARE endpoint_versions integer;
DECLARE conflict_members integer;
DECLARE assurance_items integer;
BEGIN
    SELECT count(*) INTO endpoint_versions
    FROM titan_core.endpoint_document_observation
    WHERE endpoint_id='ENDP-TST-0001';

    SELECT count(*) INTO conflict_members
    FROM titan_core.conflict_member
    WHERE conflict_id='CNF-TST-0001';

    SELECT count(*) INTO assurance_items
    FROM titan_core.assurance_scope_item
    WHERE assurance_id='ASSUR-TST-0001';

    IF endpoint_versions <> 2 THEN RAISE EXCEPTION 'PG03-T014 endpoint history expected 2 versions'; END IF;
    IF conflict_members <> 2 THEN RAISE EXCEPTION 'PG03-T015 conflict expected 2 retained evidence members'; END IF;
    IF assurance_items <> 1 THEN RAISE EXCEPTION 'PG03-T016 assurance expected 1 explicit scope item'; END IF;
END;
$$;

ROLLBACK;

\echo 'PG-03 evidence-layer tests passed if execution reached this line.'
