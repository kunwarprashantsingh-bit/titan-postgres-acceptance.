# PG-09 cumulative acceptance patch ledger

## PATCH-001 — V015 duplicate assurance reference object

- Detected during cumulative V001→V018 dependency/object audit.
- Original V015 SHA-256: `2cb8bd64d26c4437b4ecc6bb21b6e38989ed333e4de74e9e223f544facfa0d3e`
- Patched V015 SHA-256: `1410f759914b7fec5bd9fa5556fe5c8e9c378504504759fb36ac4e3d988c21d1`
- Failure mode: V008 already creates and seeds `titan_ref.assurance_level`; V015 attempted to create the same table and insert overlapping keys (`LIMITED`, `REASONABLE`, `OTHER`) again. A clean cumulative migration would fail at V015.
- Resolution: V015 now reuses the V008 reference table and seed. `sustainability_assurance_engagement.assurance_level_code` continues to reference the single authoritative lookup.
- Semantic change: none. This is a migration-integrity correction before live acceptance.


## PATCH-002 — Deterministic schema fingerprint
**File:** `acceptance/run_cumulative_acceptance.sh`

**Problem:** PostgreSQL 17+ plain-text `pg_dump` output uses a randomly generated `\restrict` key by default. PG-09's two-clean-run replay hashed the raw schema dump, so two identical schemas could produce different hashes solely because of the random restrict key.

**Correction:** acceptance-only schema dumps now use `--restrict-key=TITANREPLAYV1`, which PostgreSQL documents as intended for testing/repeatable output. This fixed key is **not** used for production backup archives.

**Semantic impact:** none. Acceptance-harness determinism correction only.
