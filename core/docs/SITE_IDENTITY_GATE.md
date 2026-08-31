# PG-01 Physical Site Identity Gate

## Why the gate exists

The frozen architecture distinguishes a **physical site** from a **plant operating asset**. A plant ID cannot automatically be converted into a new SITE ID because:

- two operating assets can occupy one physical industrial site;
- a historical administrative split/merge can create more than one plant record for one land envelope;
- terminals, grinding units, kilns, quarries and utilities may be adjacent but not part of the same site boundary;
- a "permanent" site identifier is costly to repair after global scale-up.

Therefore PG-01 stages the existing TITAN `PL-*` identities unchanged but does **not** create permanent SITE IDs until the site screen passes.

## Required site-resolution states

- `NOT_SCREENED` — no permanent site decision.
- `UNIQUE_SITE_CONFIRMED` — evidence supports a distinct physical site; issue/reuse SITE ID.
- `COLOCATED_EXISTING_SITE` — plant belongs to an already-issued SITE ID.
- `POTENTIAL_DUPLICATE` — conflicting/co-location evidence; block promotion.
- `BLOCKED_EVIDENCE` — evidence insufficient; block promotion.

## Minimum acceptance evidence for a permanent SITE ID

At least two independent identity anchors should agree where available:

1. retained TITAN plant location / coordinates / address;
2. regulatory permit/EIA/CTO site address or geospatial description;
3. official company plant location;
4. quarry/rail/port/site plan relationship;
5. satellite/GIS or cadastral boundary when required for a difficult complex.

A single commercial name is not sufficient where co-location ambiguity exists.

## Promotion rule

A plant may enter `titan_core.plant_master` only when:

- existing `PL-*` ID is preserved exactly;
- site gate is `UNIQUE_SITE_CONFIRMED` or `COLOCATED_EXISTING_SITE`;
- `resolved_site_id` is non-null and registered as `PHYSICAL_SITE`;
- `plant_type_code` is reconciled;
- country/admin geography is valid.

The pilot manifest intentionally remains `NOT_SCREENED` in PG-01 Build Candidate 0.1.
