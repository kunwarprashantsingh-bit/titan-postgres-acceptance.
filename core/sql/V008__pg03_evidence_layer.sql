-- Global Cement Sustainability Intelligence
-- PostgreSQL Implementation v1.0 — PG-03 Evidence Layer
-- Requires PG-01/PG-02 schema migrations.
-- Evidence document identity is independent of URL.
BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE titan_ref.evidence_grade (
    evidence_grade_code text PRIMARY KEY,
    rank_order smallint NOT NULL UNIQUE CHECK (rank_order >= 1),
    definition text NOT NULL
);

CREATE TABLE titan_ref.document_type (
    document_type_code text PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_ref.archival_status (
    archival_status_code text PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_ref.endpoint_access_status (
    endpoint_access_status_code text PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_ref.extraction_method (
    extraction_method_code text PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_ref.translation_method (
    translation_method_code text PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_ref.support_type (
    support_type_code text PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_ref.evidence_change_type (
    evidence_change_type_code text PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_ref.conflict_status (
    conflict_status_code text PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_ref.conflict_severity (
    conflict_severity_code text PRIMARY KEY,
    definition text NOT NULL
);

CREATE TABLE titan_ref.assurance_level (
    assurance_level_code text PRIMARY KEY,
    definition text NOT NULL
);

INSERT INTO titan_ref.evidence_grade VALUES
('P1',1,'Primary authoritative — government permits, legal filings, official statistics, regulator records'),
('P2',2,'Primary audited/disclosed — audited company filings, sustainability reports, verified EPDs'),
('P3',3,'Primary technical — official company/project technical pages, EPC/technology documentation'),
('P4',4,'Institutional — GCCA, national associations, IEA, UNIDO and comparable institutions'),
('S1',5,'Supplier/EPC — equipment suppliers, EPC contractors, project partners'),
('S2',6,'Specialist secondary — credible specialist/industry publications'),
('S3',7,'General secondary — mainstream/general media'),
('X',8,'Unverified — aggregator or unsourced claim; not confirmed');

INSERT INTO titan_ref.document_type VALUES
('REGULATORY_NOTICE','Regulator/government notice, decision, permit, approval or legal instrument'),
('PERMIT_EIA','Permit, environmental clearance, EIA/ESIA or compliance filing'),
('AUDITED_FILING','Audited financial/company filing'),
('SUSTAINABILITY_REPORT','Company sustainability/ESG/climate report'),
('TECHNICAL_REPORT','Technical/project report or engineering document'),
('EPD_PCR','EPD, PCR or product declaration documentation'),
('COMPANY_WEBPAGE','Official company webpage'),
('GOVERNMENT_WEBPAGE','Government/regulator webpage'),
('ASSURANCE_REPORT','Independent assurance/verification report'),
('DATASET','Official/institutional structured dataset'),
('SECONDARY_ARTICLE','Secondary publication/article'),
('OTHER','Other source document');

INSERT INTO titan_ref.archival_status VALUES
('LIVE_ONLY','Source available live but no retained snapshot yet'),
('SNAPSHOT_RETAINED','At least one retained snapshot/object exists'),
('ARCHIVED_EXTERNAL','Externally archived copy retained/referenced'),
('WITHDRAWN','Publisher withdrew source'),
('MISSING','Source/snapshot unavailable'),
('UNKNOWN','Archival state not verified');

INSERT INTO titan_ref.endpoint_access_status VALUES
('ACTIVE','Endpoint currently accessible'),
('REDIRECT','Endpoint redirects'),
('AUTH_REQUIRED','Endpoint exists but requires authentication/access'),
('DEAD','Endpoint no longer resolves/serves source'),
('BLOCKED','Endpoint blocks automated/public access'),
('UNKNOWN','Access state not verified');

INSERT INTO titan_ref.extraction_method VALUES
('MANUAL','Human extraction from source'),
('PARSER','Structured/programmatic parser'),
('OCR','Optical character recognition'),
('TRANSCRIPTION','Manual transcription from image/scan/audio'),
('API_FIELD','Value directly retrieved from structured API field');

INSERT INTO titan_ref.translation_method VALUES
('HUMAN','Human translation'),
('MACHINE_ASSISTED','Machine-assisted translation reviewed by analyst'),
('MACHINE_UNREVIEWED','Machine translation not human reviewed'),
('PUBLISHER_OFFICIAL','Official publisher-provided translation'),
('NONE_SAME_LANGUAGE','No translation required');

INSERT INTO titan_ref.support_type VALUES
('SUPPORTS','Evidence supports downstream assertion/fact'),
('CONTRADICTS','Evidence contradicts downstream assertion/fact'),
('QUALIFIES','Evidence narrows/qualifies assertion'),
('SUPERSEDES','Evidence supersedes prior evidence/assertion'),
('CONTEXT','Evidence provides context only');

INSERT INTO titan_ref.evidence_change_type VALUES
('CORRECTED','Publisher/source corrected prior document/content'),
('SUPERSEDED','New source supersedes prior source'),
('REPLACED_AT_ENDPOINT','Same endpoint served materially different document/content'),
('MOVED','Document moved to different endpoint'),
('WITHDRAWN','Source withdrawn'),
('ERRATUM','Formal erratum/correction notice'),
('REPUBLICATION','Republished version'),
('TRANSLATION','Translated edition/representation');

INSERT INTO titan_ref.conflict_status VALUES
('OPEN','Conflict unresolved'),
('HOLD','Conflict intentionally held pending stronger evidence'),
('RESOLVED','Conflict resolved with retained lineage'),
('SUPERSEDED','Conflict superseded by later reconciliation');

INSERT INTO titan_ref.conflict_severity VALUES
('LOW','Low analytical consequence'),
('MEDIUM','Material but bounded analytical consequence'),
('HIGH','High analytical consequence'),
('CRITICAL','Could materially corrupt physical identity, compliance, capacity or performance');

INSERT INTO titan_ref.assurance_level VALUES
('LIMITED','Limited assurance'),
('REASONABLE','Reasonable assurance'),
('VERIFICATION','Verification engagement / verified metric'),
('AGREED_UPON','Agreed-upon procedures or similarly scoped factual testing'),
('OTHER','Other explicitly described assurance level'),
('UNKNOWN','Assurance level not specified');

CREATE OR REPLACE FUNCTION titan_core.sha256_hex(data bytea)
RETURNS text
LANGUAGE sql
IMMUTABLE
STRICT
AS $$
    SELECT encode(digest(data,'sha256'),'hex')
$$;

CREATE TABLE titan_core.source_document (
    source_id text PRIMARY KEY
        REFERENCES titan_core.entity_registry(entity_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    publisher_name text NOT NULL,
    document_title text NOT NULL,
    document_type_code text NOT NULL REFERENCES titan_ref.document_type(document_type_code),
    evidence_grade_code text NOT NULL REFERENCES titan_ref.evidence_grade(evidence_grade_code),
    publication_date date NULL,
    language_code text NOT NULL,
    mime_type text NULL,
    file_size_bytes bigint NULL CHECK (file_size_bytes IS NULL OR file_size_bytes >= 0),
    canonical_sha256 text NULL,
    archival_status_code text NOT NULL REFERENCES titan_ref.archival_status(archival_status_code),
    authoritative_status text NULL,
    source_notes text NULL,
    created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    retired_at timestamptz NULL,
    row_version bigint NOT NULL DEFAULT 1 CHECK (row_version >= 1),
    CONSTRAINT ck_source_publisher_nonblank CHECK (btrim(publisher_name) <> ''),
    CONSTRAINT ck_source_title_nonblank CHECK (btrim(document_title) <> ''),
    CONSTRAINT ck_source_language_nonblank CHECK (btrim(language_code) <> ''),
    CONSTRAINT ck_source_sha256 CHECK (canonical_sha256 IS NULL OR canonical_sha256 ~ '^[0-9a-f]{64}$'),
    CONSTRAINT ck_source_retired CHECK (retired_at IS NULL OR retired_at >= created_at)
);

CREATE TRIGGER trg_source_document_type
BEFORE INSERT OR UPDATE ON titan_core.source_document
FOR EACH ROW EXECUTE FUNCTION titan_core.validate_child_entity_type('source_id','SOURCE');

CREATE UNIQUE INDEX uq_source_document_content_hash
ON titan_core.source_document(canonical_sha256)
WHERE canonical_sha256 IS NOT NULL;

CREATE TABLE titan_core.source_endpoint (
    endpoint_id text PRIMARY KEY,
    endpoint_url text NOT NULL UNIQUE,
    first_seen_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_checked_at timestamptz NULL,
    endpoint_access_status_code text NOT NULL REFERENCES titan_ref.endpoint_access_status(endpoint_access_status_code),
    endpoint_notes text NULL,
    row_version bigint NOT NULL DEFAULT 1 CHECK (row_version >= 1),
    CONSTRAINT ck_endpoint_id CHECK (endpoint_id ~ '^ENDP-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_endpoint_url_nonblank CHECK (btrim(endpoint_url) <> ''),
    CONSTRAINT ck_endpoint_check_time CHECK (last_checked_at IS NULL OR last_checked_at >= first_seen_at)
);

CREATE TABLE titan_core.endpoint_document_observation (
    endpoint_document_observation_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    endpoint_id text NOT NULL REFERENCES titan_core.source_endpoint(endpoint_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    observed_at timestamptz NOT NULL,
    http_status integer NULL CHECK (http_status IS NULL OR http_status BETWEEN 100 AND 599),
    observed_sha256 text NULL,
    observation_notes text NULL,
    CONSTRAINT ck_endpoint_obs_sha256 CHECK (observed_sha256 IS NULL OR observed_sha256 ~ '^[0-9a-f]{64}$'),
    CONSTRAINT uq_endpoint_observed_at UNIQUE(endpoint_id, observed_at)
);

CREATE INDEX ix_endpoint_document_source
ON titan_core.endpoint_document_observation(source_id);

CREATE TABLE titan_core.source_snapshot (
    snapshot_id text PRIMARY KEY,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    endpoint_id text NULL REFERENCES titan_core.source_endpoint(endpoint_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    captured_at timestamptz NOT NULL,
    storage_uri text NOT NULL,
    content_sha256 text NOT NULL,
    file_size_bytes bigint NULL CHECK (file_size_bytes IS NULL OR file_size_bytes >= 0),
    mime_type text NULL,
    capture_method text NOT NULL,
    snapshot_notes text NULL,
    CONSTRAINT ck_snapshot_id CHECK (snapshot_id ~ '^SNAP-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_snapshot_uri_nonblank CHECK (btrim(storage_uri) <> ''),
    CONSTRAINT ck_snapshot_sha256 CHECK (content_sha256 ~ '^[0-9a-f]{64}$'),
    CONSTRAINT ck_snapshot_capture_method CHECK (btrim(capture_method) <> ''),
    CONSTRAINT uq_source_snapshot UNIQUE(source_id, content_sha256, storage_uri)
);

CREATE TABLE titan_core.research_session (
    research_session_id text PRIMARY KEY,
    analyst_ref text NOT NULL,
    started_at timestamptz NOT NULL,
    ended_at timestamptz NULL,
    session_purpose text NOT NULL,
    recorded_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_research_session_id CHECK (research_session_id ~ '^RSCH-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_research_session_analyst CHECK (btrim(analyst_ref) <> ''),
    CONSTRAINT ck_research_session_purpose CHECK (btrim(session_purpose) <> ''),
    CONSTRAINT ck_research_session_times CHECK (ended_at IS NULL OR ended_at >= started_at)
);

CREATE TABLE titan_core.extraction_record (
    extraction_id text PRIMARY KEY,
    source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    snapshot_id text NULL REFERENCES titan_core.source_snapshot(snapshot_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    research_session_id text NULL REFERENCES titan_core.research_session(research_session_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    location_ref text NOT NULL,
    page_number integer NULL CHECK (page_number IS NULL OR page_number >= 1),
    extracted_text text NULL,
    extracted_numeric_value numeric NULL,
    extracted_unit_text text NULL,
    extraction_method_code text NOT NULL REFERENCES titan_ref.extraction_method(extraction_method_code),
    reviewer_ref text NULL,
    extraction_confidence numeric(5,4) NULL CHECK (extraction_confidence IS NULL OR extraction_confidence BETWEEN 0 AND 1),
    extracted_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    extraction_notes text NULL,
    CONSTRAINT ck_extraction_id CHECK (extraction_id ~ '^EXT-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_extraction_location CHECK (btrim(location_ref) <> ''),
    CONSTRAINT ck_extraction_has_content CHECK (
        extracted_text IS NOT NULL OR extracted_numeric_value IS NOT NULL
    )
);

CREATE OR REPLACE FUNCTION titan_core.validate_extraction_snapshot_source()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE snapshot_source text;
BEGIN
    IF NEW.snapshot_id IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT source_id INTO snapshot_source
    FROM titan_core.source_snapshot
    WHERE snapshot_id=NEW.snapshot_id;

    IF snapshot_source IS DISTINCT FROM NEW.source_id THEN
        RAISE EXCEPTION 'Snapshot % belongs to source %, not extraction source %',
            NEW.snapshot_id, snapshot_source, NEW.source_id;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_extraction_snapshot_source
BEFORE INSERT OR UPDATE ON titan_core.extraction_record
FOR EACH ROW EXECUTE FUNCTION titan_core.validate_extraction_snapshot_source();

CREATE TABLE titan_core.translation_record (
    translation_id text PRIMARY KEY,
    extraction_id text NOT NULL REFERENCES titan_core.extraction_record(extraction_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    source_language_code text NOT NULL,
    target_language_code text NOT NULL,
    translated_text text NOT NULL,
    translation_method_code text NOT NULL REFERENCES titan_ref.translation_method(translation_method_code),
    reviewer_ref text NULL,
    translated_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    translation_notes text NULL,
    CONSTRAINT ck_translation_id CHECK (translation_id ~ '^TRN-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_translation_languages CHECK (
        btrim(source_language_code) <> '' AND btrim(target_language_code) <> ''
    ),
    CONSTRAINT ck_translation_text CHECK (btrim(translated_text) <> ''),
    CONSTRAINT ck_translation_language_change CHECK (
        (translation_method_code='NONE_SAME_LANGUAGE' AND source_language_code = target_language_code)
        OR
        (translation_method_code<>'NONE_SAME_LANGUAGE' AND source_language_code <> target_language_code)
    )
);

CREATE TABLE titan_core.numeric_precision (
    precision_id text PRIMARY KEY,
    extraction_id text NOT NULL UNIQUE REFERENCES titan_core.extraction_record(extraction_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    reported_text text NOT NULL,
    decimal_places smallint NULL CHECK (decimal_places IS NULL OR decimal_places >= 0),
    significant_figures smallint NULL CHECK (significant_figures IS NULL OR significant_figures >= 1),
    rounding_increment numeric NULL CHECK (rounding_increment IS NULL OR rounding_increment > 0),
    lower_bound numeric NULL,
    upper_bound numeric NULL,
    precision_notes text NULL,
    CONSTRAINT ck_precision_id CHECK (precision_id ~ '^PREC-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_precision_reported_text CHECK (btrim(reported_text) <> ''),
    CONSTRAINT ck_precision_bounds CHECK (lower_bound IS NULL OR upper_bound IS NULL OR upper_bound >= lower_bound)
);

CREATE TABLE titan_core.source_revision_relationship (
    source_revision_relationship_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    from_source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    to_source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    evidence_change_type_code text NOT NULL REFERENCES titan_ref.evidence_change_type(evidence_change_type_code),
    effective_at timestamptz NULL,
    evidence_notes text NULL,
    CONSTRAINT ck_source_revision_not_self CHECK (from_source_id <> to_source_id),
    CONSTRAINT uq_source_revision_relation UNIQUE(from_source_id,to_source_id,evidence_change_type_code)
);

CREATE TABLE titan_core.evidence_change_event (
    evidence_change_event_id text PRIMARY KEY,
    evidence_change_type_code text NOT NULL REFERENCES titan_ref.evidence_change_type(evidence_change_type_code),
    endpoint_id text NULL REFERENCES titan_core.source_endpoint(endpoint_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    from_source_id text NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    to_source_id text NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    detected_at timestamptz NOT NULL,
    source_event_date date NULL,
    event_notes text NOT NULL,
    CONSTRAINT ck_evidence_change_id CHECK (evidence_change_event_id ~ '^EVC-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_evidence_change_notes CHECK (btrim(event_notes) <> ''),
    CONSTRAINT ck_evidence_change_has_subject CHECK (
        endpoint_id IS NOT NULL OR from_source_id IS NOT NULL OR to_source_id IS NOT NULL
    )
);

CREATE TABLE titan_core.evidence_conflict (
    conflict_id text PRIMARY KEY
        REFERENCES titan_core.entity_registry(entity_id)
        ON UPDATE RESTRICT ON DELETE RESTRICT,
    conflict_status_code text NOT NULL REFERENCES titan_ref.conflict_status(conflict_status_code),
    conflict_severity_code text NOT NULL REFERENCES titan_ref.conflict_severity(conflict_severity_code),
    issue_summary text NOT NULL,
    controlled_treatment text NOT NULL,
    resolution_summary text NULL,
    opened_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    resolved_at timestamptz NULL,
    CONSTRAINT ck_conflict_issue CHECK (btrim(issue_summary) <> ''),
    CONSTRAINT ck_conflict_treatment CHECK (btrim(controlled_treatment) <> ''),
    CONSTRAINT ck_conflict_resolution_time CHECK (resolved_at IS NULL OR resolved_at >= opened_at)
);

CREATE TRIGGER trg_evidence_conflict_type
BEFORE INSERT OR UPDATE ON titan_core.evidence_conflict
FOR EACH ROW EXECUTE FUNCTION titan_core.validate_child_entity_type('conflict_id','CONFLICT');

CREATE TABLE titan_core.conflict_member (
    conflict_member_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    conflict_id text NOT NULL REFERENCES titan_core.evidence_conflict(conflict_id) ON UPDATE RESTRICT ON DELETE CASCADE,
    extraction_id text NOT NULL REFERENCES titan_core.extraction_record(extraction_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    support_type_code text NOT NULL REFERENCES titan_ref.support_type(support_type_code),
    member_notes text NULL,
    CONSTRAINT uq_conflict_member UNIQUE(conflict_id, extraction_id)
);

CREATE TABLE titan_core.assurance_engagement (
    assurance_id text PRIMARY KEY,
    assurance_source_id text NOT NULL REFERENCES titan_core.source_document(source_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    practitioner_name text NOT NULL,
    assurance_standard text NOT NULL,
    assurance_level_code text NOT NULL REFERENCES titan_ref.assurance_level(assurance_level_code),
    period_start date NULL,
    period_end date NULL,
    opinion_summary text NULL,
    recorded_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_assurance_id CHECK (assurance_id ~ '^ASSUR-[A-Za-z0-9][A-Za-z0-9._-]*$'),
    CONSTRAINT ck_assurance_practitioner CHECK (btrim(practitioner_name) <> ''),
    CONSTRAINT ck_assurance_standard CHECK (btrim(assurance_standard) <> ''),
    CONSTRAINT ck_assurance_period CHECK (period_end IS NULL OR period_start IS NULL OR period_end >= period_start)
);

CREATE TABLE titan_core.assurance_scope_item (
    assurance_scope_item_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    assurance_id text NOT NULL REFERENCES titan_core.assurance_engagement(assurance_id) ON UPDATE RESTRICT ON DELETE CASCADE,
    declared_scope_text text NOT NULL,
    source_location_ref text NOT NULL,
    future_target_type text NULL,
    future_target_id text NULL,
    scope_notes text NULL,
    CONSTRAINT ck_assurance_scope_text CHECK (btrim(declared_scope_text) <> ''),
    CONSTRAINT ck_assurance_scope_location CHECK (btrim(source_location_ref) <> '')
);

COMMIT;
