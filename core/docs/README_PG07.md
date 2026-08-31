# PG-07 — Water, Nature & Corporate Transition Governance

PG-07 implements the frozen FT-07 and FT-11 semantics on top of the common PG-04 observation backbone.

## Water
- withdrawal, discharge, consumption, dewatering, recycling and storage are distinct;
- water balance reconciles opening storage + withdrawals + inflows - discharges - closing storage;
- basin context is separate from operational efficiency;
- SBTN Freshwater V2 is retained as PILOT at the 30 Aug 2026 cut-off, not as final production methodology.

## Nature/quarries
- site/quarry polygon and sensitivity context are location/version specific;
- impact, mitigation action and ecosystem outcome are separate;
- mitigation hierarchy action type is explicit;
- offsite offset is explicitly linked to residual impact and never becomes onsite rehabilitation;
- historical restored area cannot be divided by current disturbed area without compatible period/boundary.

## Corporate targets
- target identity and target version are separate;
- scope, boundary, baseline year, target year, gross/net type, framework/version and validation status stay attached to each version;
- recalculation evaluations preserve trigger, significance threshold and result;
- SBTi V2 5% threshold is framework-specific and V2 is not treated as retroactive validation for 2026 targets;
- corporate targets never auto-propagate to plants;
- gross targets remain separate from net targets and credit reliance;
- transition capex excludes maintenance unless evidence supports transition attribution.

## Assurance
- assurance engagement stores practitioner, standard, level and exact period;
- only explicit scope members inherit assurance;
- ISSA 5000 general effective date is 15 Dec 2026 with early application permitted.

## Acceptance
PG-07 remains BUILD CANDIDATE until V015-V016 and T008 execute successfully on a live PostgreSQL instance.
