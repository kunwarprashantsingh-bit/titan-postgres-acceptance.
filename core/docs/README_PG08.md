# PG-08 — Temporal, Scenario, Model & Publication Governance

PG-08 implements the frozen FT-13 analytical-governance layer.

## Core contract

`Reporting calendar -> Reporting period -> period mapping -> currency/price basis -> scenario -> assumption set -> override set -> sealed dataset snapshot -> model version -> model run -> model output -> publication snapshot`

## Controls

- fiscal/calendar labels never replace actual start/end dates;
- cross-calendar mappings can be REFERENCE_ONLY without fabricating monthly allocation;
- nominal/real price basis and FX method/date/period are explicit;
- scenario versions and assumption sets are immutable analytical inputs;
- overrides are pre-run immutable sets with user/reason/value lineage;
- model runs require SEALED dataset snapshots and matching cut-off dates;
- model outputs and abatement allocations can be assembled only while a run is DRAFT;
- completing a run seals its output fingerprint and blocks late outputs/allocations;
- one physical abatement action may be split across analytical wedges, but total allocation cannot exceed physical max claimable abatement;
- project probability changes are time-versioned and affect future runs only;
- publication snapshots are assembled in DRAFT and then frozen;
- published artifacts/model-run membership cannot be changed; corrections require successor publication snapshots;
- old publications retain their original dataset snapshot, model run and output hash after current data/models change.

## Current PostgreSQL runtime reference

As of 30 Aug 2026:
- PostgreSQL 18 is supported;
- current minor is 18.6, released 13 Aug 2026;
- PostgreSQL recommends staying on the current minor release;
- PG-08 relies on ordinary fail-closed constraints/triggers and transaction discipline rather than application-only controls.

## Acceptance

PG-08 remains BUILD CANDIDATE until V017-V018 and T009 execute successfully on a live supported PostgreSQL instance.
