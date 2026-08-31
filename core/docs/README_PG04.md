# PG-04 — Observation & Accounting Layer

## Purpose
PG-04 is the factual engine. It implements the frozen rule that a value is meaningful only with its subject, period, boundary, methodology, data class, unit, denominator and evidence/provenance.

### Universal observation
An `OBS-*` record carries:
- subject entity;
- metric code;
- quantity kind;
- explicit value state;
- R/D/M/P data class when a numeric/text value exists;
- numeric/text payload;
- numerator unit;
- denominator definition for intensities;
- exact boundary version;
- exact methodology version;
- measurement method/basis;
- period;
- supersession lineage.

### R / D / M / P provenance
- `R`: supporting extraction evidence required.
- `D`: formula + at least one input observation required.
- `M`: model/version/assumption provenance required.
- `P`: proxy source observation + rationale required.
- Non-value states such as `NOT_PUBLICLY_VERIFIED` remain valid without a fabricated number.

### Cement-specific accounting
PG-04 also implements:
- methodology master/version;
- denominator definitions;
- measurement basis/data quality;
- versioned inventory + components;
- Scope 2 LB/MB separation;
- gross/net/removal/offset/avoided roles;
- materials and physical-flow status;
- product/formulation/composition/manufacturing;
- EPD identity/membership/results;
- comparability rules, normalizations and recorded comparison results.

## Key integrity choices
1. A regulator intensity, corporate KPI and EPD result are not interchangeable because units look similar.
2. An `INTENSITY` requires an explicit denominator ID.
3. `ZERO` must be zero; unknown states carry no numeric payload.
4. Tender/contract flow remains non-actual until a realized-flow state is evidenced.
5. Original and restated inventories coexist.
6. Scope 2 location-based and market-based components are separate valid records.
7. Product composition numeric shares cannot exceed 100%.
8. Conditional comparison requires an explicit normalization method.
9. Product/EPD claims remain outside PG-04; claim implementation follows its own frozen domain rather than contaminating physical inventory.

## PostgreSQL implementation sources
- constraints: https://www.postgresql.org/docs/18/ddl-constraints.html
- generated columns: https://www.postgresql.org/docs/18/ddl-generated-columns.html
- CREATE TABLE / constraint triggers: https://www.postgresql.org/docs/18/sql-createtable.html

## Acceptance
PG-04 is BUILD CANDIDATE until `V009` and `T005` execute successfully on a live supported PostgreSQL instance after prior migrations.
