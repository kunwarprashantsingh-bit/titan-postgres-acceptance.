# PG-03 — Evidence Layer

## Purpose
PG-03 makes evidence auditability an executable database property.

### Core chain
`SOURCE document identity -> endpoint history -> retained snapshot -> extraction -> translation/precision -> conflict/assurance`

## Design decisions

1. **Document identity is not URL identity.** `SRC-*` is the permanent document/content identity. URLs are endpoint records.
2. **Duplicate content is not independent corroboration.** When a canonical SHA-256 hash is known, it is unique in `source_document`.
3. **A URL can change content.** `endpoint_document_observation` records which `SRC-*` document was observed at an endpoint at a specific time.
4. **Snapshots are retained objects.** The database stores object URI + SHA-256 + capture metadata, not giant PDF/blob payloads.
5. **Extraction is atomic and located.** Every extraction has an exact locator and method; a snapshot must belong to the same source.
6. **Translation is lineage, not replacement.** Original extraction remains authoritative; translated text is linked to it.
7. **Precision is preserved.** `3.30` can remain distinct in reported precision from `3.3` even where numeric values are mathematically equal.
8. **Conflict is a first-class object.** Contradictory evidence is retained and grouped; no source is silently overwritten.
9. **Assurance is selective.** An assurance engagement has explicit scope items. The database does not support a blanket 'report assured' shortcut.
10. **Observation/claim foreign keys are deliberately deferred.** PG-04 will create those target tables and convert `future_target_type/future_target_id` into enforced relationships. PG-03 does not create fake target rows.

## PostgreSQL implementation sources
- pgcrypto / digest(): https://www.postgresql.org/docs/18/pgcrypto.html
- constraints and unique indexes: https://www.postgresql.org/docs/18/ddl-constraints.html

## Acceptance
PG-03 is BUILD CANDIDATE until `V008` and `T004` execute successfully on a live supported PostgreSQL instance after the earlier migrations.
