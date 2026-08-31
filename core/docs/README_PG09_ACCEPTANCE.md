# PG-09 — Cumulative PostgreSQL Acceptance & Operational Hardening

This package is the first cumulative acceptance package rather than another semantic layer.

## What changed
Cumulative static analysis exposed one real clean-migration blocker: `titan_ref.assurance_level` was created/seeded in both V008 and V015. V015 has been patched to reuse the V008 object. No semantic rule changed.

## Static cumulative gate completed in this environment
- V001–V018 present and ordered.
- T001–T009 present.
- 239 unique tables, 4 views and 40 SQL/PLpgSQL functions detected across migrations.
- No unresolved FK reference-before-create issue after PATCH-001.
- No duplicate literal reference seeds detected after PATCH-001.
- All 18 migrations contain transaction wrappers and balanced dollar quoting.
- T001 and T003–T009 are rollback fixtures; T002 is a read-only post-promotion test and intentionally does not rollback.
- 206 numbered acceptance assertions are represented across T001–T009.

## Live execution state
The current ChatGPT execution container has no PostgreSQL binaries and cannot reach package repositories/download hosts. Therefore no live database PASS is claimed here.

## Live target
Run against PostgreSQL >=18.6 and <19.0 with `btree_gist` and `pgcrypto` available.

```bash
cd <package-root>
export TITAN_ACCEPTANCE_ALLOW_DROP=YES
./acceptance/run_cumulative_acceptance.sh
```

For deterministic clean replay:

```bash
export TITAN_ACCEPTANCE_ALLOW_DROP=YES
./acceptance/run_clean_replay_twice.sh
```

The harness recreates only databases named `titan_acceptance_*`, executes V001–V018, runs structural gates, executes T001–T009, verifies no synthetic test residue, and captures a schema-only hash. The two-run replay compares hashes.

## Promotion gate
Do not call the PostgreSQL implementation accepted until the clean live run and clean replay both pass. Only then proceed to operational/security/load/backup-recovery acceptance and broader India/China migration.
