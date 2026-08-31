# PG-02 — Temporal & Relationship Core

## Purpose
PG-02 implements the frozen relationship/time contract without changing physical identity.

Implemented:
- time-versioned ownership interests;
- operating control separated from ownership;
- site/asset relationships;
- shared assets and evidence-backed allocation rules;
- first-class versioned boundaries and boundary members;
- dated asset events;
- non-overlapping operational-status history.

## PostgreSQL implementation choice
PG-02 uses `daterange` plus GiST exclusion constraints. PostgreSQL range types and exclusion constraints are designed for non-overlap rules. `btree_gist` supplies GiST equality behavior for text IDs so a relationship key and a time range can be constrained together.

Official references:
- https://www.postgresql.org/docs/18/ddl-constraints.html
- https://www.postgresql.org/docs/18/rangetypes.html
- https://www.postgresql.org/docs/18/btree-gist.html

## Important semantic rules
1. Ownership is not operating control.
2. Multiple owners may coexist; one primary operator cannot overlap itself in time.
3. Unknown/disclosed ownership shares are allowed; the database does not force shares to sum to 100%.
4. An allocation rule cannot allocate more than 100%, but can deliberately remain below 100% where a residual/unallocated share exists.
5. Shared infrastructure is one physical asset with beneficiary relationships—not duplicated once per plant.
6. Boundary versions cannot overlap for the same boundary identity.
7. Operational status is an interval; asset events are dated events and do not overwrite status history.
8. `source_id` remains textual until the PG-03 evidence layer creates formal source FKs.

## Acceptance
PG-02 is BUILD CANDIDATE until V007 and T003 execute successfully on a supported PostgreSQL instance after PG-01 has passed live execution.
