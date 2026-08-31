-- PG-08 current PostgreSQL implementation-reference seed
-- Verification cut-off: 2026-08-30.
BEGIN;

INSERT INTO titan_core.entity_registry(entity_id,entity_type_code,canonical_name,country_geo_id) VALUES
('SRC-PG08-PG-VERSION','SOURCE','PostgreSQL Versioning Policy / Current Minor',NULL),
('SRC-PG08-PG-186','SOURCE','PostgreSQL 18.6 Release Notes',NULL),
('SRC-PG08-PG-CONSTRAINTS','SOURCE','PostgreSQL 18 Constraints Documentation',NULL),
('SRC-PG08-PG-TXN','SOURCE','PostgreSQL 18 Transaction Isolation Documentation',NULL);

INSERT INTO titan_core.source_document
(source_id,publisher_name,document_title,document_type_code,evidence_grade_code,publication_date,language_code,mime_type,archival_status_code,authoritative_status,source_notes)
VALUES
('SRC-PG08-PG-VERSION','PostgreSQL Global Development Group','PostgreSQL Versioning Policy','TECHNICAL_REPORT','P1',NULL,'en','text/html','LIVE_ONLY','CURRENT','Current supported minor for major 18 is 18.6 at the PG-08 verification cut-off; current minor releases are recommended.'),
('SRC-PG08-PG-186','PostgreSQL Global Development Group','PostgreSQL 18.6 Release Notes','TECHNICAL_REPORT','P1',DATE '2026-08-13','en','text/html','LIVE_ONLY','CURRENT','Current PostgreSQL 18 minor release at cut-off; fixes security and correctness issues.'),
('SRC-PG08-PG-CONSTRAINTS','PostgreSQL Global Development Group','PostgreSQL 18 — Constraints','TECHNICAL_REPORT','P1',NULL,'en','text/html','LIVE_ONLY','CURRENT','Primary/foreign/unique/check/exclusion constraints fail closed on invalid rows.'),
('SRC-PG08-PG-TXN','PostgreSQL Global Development Group','PostgreSQL 18 — Transaction Isolation','TECHNICAL_REPORT','P1',NULL,'en','text/html','LIVE_ONLY','CURRENT','Serializable and read-only deferrable transaction behavior supports controlled reproducible snapshot operations where appropriate.');

INSERT INTO titan_core.source_endpoint(endpoint_id,endpoint_url,endpoint_access_status_code) VALUES
('ENDP-PG08-PG-VERSION','https://www.postgresql.org/support/versioning/','ACTIVE'),
('ENDP-PG08-PG-186','https://www.postgresql.org/docs/release/18.6/','ACTIVE'),
('ENDP-PG08-PG-CONSTRAINTS','https://www.postgresql.org/docs/18/ddl-constraints.html','ACTIVE'),
('ENDP-PG08-PG-TXN','https://www.postgresql.org/docs/18/transaction-iso.html','ACTIVE');

COMMIT;
