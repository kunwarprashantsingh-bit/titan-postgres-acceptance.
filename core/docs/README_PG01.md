# Global Cement Sustainability Intelligence — PostgreSQL PG-01

## Status

**PG-01 Build Candidate 0.1 — Core Registry & Geography**

The frozen semantic architecture has been translated into PostgreSQL DDL for:

- controlled reference vocabularies;
- universal `entity_registry`;
- geography hierarchy;
- physical sites;
- site locations and addresses;
- plant master;
- aliases;
- genealogy;
- migration staging and the permanent-site issuance gate.

Existing TITAN plant IDs are staged unchanged.

### Deliberate acceptance hold

The 10 pilot plants are **not yet promoted to production tables** because permanent SITE IDs have not been minted. The next PG-01 sub-pass is the physical site duplicate/co-location screen. This is intentional and protects permanent identity.

## PostgreSQL version policy

Use a supported PostgreSQL major version on its current supported minor/security release. At package creation on 2026-08-28, PostgreSQL 18.6 is the current 18.x minor. Do not interpret this as permission to remain on 18.6 after a newer security/bug-fix minor is released.

## File order

1. `sql/V001__pg01_core_registry_geography.sql`
2. `sql/V002__pg01_reference_and_geography_seed.sql`
3. `sql/V003__pg01_migration_staging.sql`
4. `sql/V004__pg01_pilot_manifest.sql`
5. `sql/T001__pg01_constraint_tests.sql` — disposable test DB only

Run with `ON_ERROR_STOP` enabled.

Example:

```powershell
psql -U postgres -d titan_pg01_test -v ON_ERROR_STOP=1 -f .\sql\V001__pg01_core_registry_geography.sql
psql -U postgres -d titan_pg01_test -v ON_ERROR_STOP=1 -f .\sql\V002__pg01_reference_and_geography_seed.sql
psql -U postgres -d titan_pg01_test -v ON_ERROR_STOP=1 -f .\sql\V003__pg01_migration_staging.sql
psql -U postgres -d titan_pg01_test -v ON_ERROR_STOP=1 -f .\sql\V004__pg01_pilot_manifest.sql
psql -U postgres -d titan_pg01_test -v ON_ERROR_STOP=1 -f .\sql\T001__pg01_constraint_tests.sql
```

## Design decisions

1. **Reference tables instead of PostgreSQL ENUMs.** Categories remain constrained while allowing governed additions/migrations.
2. **No replacement of TITAN physical IDs.** `PL-*` remains the permanent plant identity.
3. **SITE ID issuance is gated.** One plant is not assumed to equal one physical site.
4. **Geography is first-class.** Country and subnational units are registered stable entities.
5. **Typed child tables are enforced by triggers.** A `SITE-*` registry object cannot masquerade as a plant row.
6. **IDs and entity types are immutable.** Corrections use aliases/genealogy or controlled successor records.
7. **Source FKs are deferred to PG-03.** PG-01 retains `source_id` fields but does not invent an evidence table before its dedicated tranche.
8. **No PostGIS dependency in PG-01.** Coordinates and a geometry reference are structurally supported; PostGIS is an implementation enhancement that can be added without changing semantic identity.

## Acceptance

PG-01 becomes **Accepted** only after:

- the DDL and T001 tests execute successfully on the chosen supported PostgreSQL build;
- the 10 pilot plant IDs remain unchanged;
- the site duplicate/co-location screen resolves each pilot plant to a permanent/reused SITE ID;
- the 10 pilot rows can then be promoted without orphan FKs or duplicate physical sites.

This package was statically checked in the ChatGPT execution environment, but that environment does not contain a PostgreSQL server. Therefore SQL execution is deliberately not claimed here.


## PG-01B extension — physical site resolution

The 10 pilot plants passed the evidence-based physical-site gate. Permanent SITE IDs are defined in `V005`; existing PL IDs are promoted unchanged in `V006`.

### Required live execution sequence

```powershell
psql -U postgres -d titan_pg01_test -v ON_ERROR_STOP=1 -f .\sql\V001__pg01_core_registry_geography.sql
psql -U postgres -d titan_pg01_test -v ON_ERROR_STOP=1 -f .\sql\V002__pg01_reference_and_geography_seed.sql
psql -U postgres -d titan_pg01_test -v ON_ERROR_STOP=1 -f .\sql\V003__pg01_migration_staging.sql
psql -U postgres -d titan_pg01_test -v ON_ERROR_STOP=1 -f .\sql\V004__pg01_pilot_manifest.sql
psql -U postgres -d titan_pg01_test -v ON_ERROR_STOP=1 -f .\sql\T001__pg01_constraint_tests.sql
psql -U postgres -d titan_pg01_test -v ON_ERROR_STOP=1 -f .\sql\V005__pg01b_site_resolution_seed.sql
psql -U postgres -d titan_pg01_test -v ON_ERROR_STOP=1 -f .\sql\V006__pg01b_promote_pilot_plants.sql
psql -U postgres -d titan_pg01_test -v ON_ERROR_STOP=1 -f .\sql\T002__pg01b_site_promotion_tests.sql
```

PG-01 is accepted only if **T001 and T002 both execute successfully without modification**.
