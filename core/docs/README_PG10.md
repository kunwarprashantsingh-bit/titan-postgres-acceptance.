# PG-10 — Security, Recovery, Load & Operational Acceptance

PG-10 is operational hardening, not a semantic redesign.

## Security
- runtime roles are NOLOGIN group roles with NOSUPERUSER/NOBYPASSRLS/NOCREATEROLE/NOCREATEDB/NOREPLICATION;
- runtime editorial roles have read access to curated core but no direct curated DML;
- the migration role is isolated and is not granted to runtime roles;
- `public` schema CREATE is revoked;
- workflow rows use RLS + FORCE RLS;
- state transitions are role-specific;
- researchers cannot self-approve, reviewers cannot publish, publishers cannot mutate curated core;
- workflow events are append-only;
- the one SECURITY DEFINER audit function uses a fixed `pg_catalog,titan_ops` search path.

## Concurrency
- work items have `row_version`;
- `try_transition_work_item()` uses expected-version optimistic locking;
- the concurrent two-writer harness requires exactly one winner.

## Load
- `pgbench` insert smoke records throughput and latency without inventing an SLA;
- acceptance gates on zero failed transactions and zero new deadlocks;
- TPS/latency become SLO-gated only after deployment requirements are defined.

## Recovery
- logical custom-format dump/restore drill compares every TITAN table row count and a deterministic test-only schema fingerprint;
- cluster globals are captured separately;
- production backup design must also use WAL/PITR and regular restore drills;
- PITR contract tests target-time correctness using recovery markers;
- numerical RPO/RTO thresholds remain deployment SLOs and are measured, not guessed.

## PATCH-002
PG-09's replay hash is corrected to use PostgreSQL `pg_dump --restrict-key` in the **test-only** deterministic schema dump. Real backup archives do not use a fixed restrict key.

## Live status
This package has static QA only in the current ChatGPT execution environment because no PostgreSQL server/client binaries are available here.
