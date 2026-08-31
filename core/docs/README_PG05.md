# PG-05 — Policy & Compliance Layer

## Purpose
PG-05 implements the frozen regulatory chain:

`Scheme -> Policy Version -> Regulated Entity -> Compliance Unit -> TITAN Asset -> Obligation -> Verification -> Instrument Ledger -> Settlement -> Enforcement`

## Current verified regulatory replay

### India CCTS
- Principal Greenhouse Gases Emission Intensity Target Rules, 2025: G.S.R. 739(E), 8 Oct 2025.
- CCC issuance: `(target GEI - achieved GEI) × equivalent product` when achievement is better than target.
- CCC shortfall: `(achieved GEI - target GEI) × equivalent product` when achievement is worse than target.
- Issued/purchased CCC may be banked under the detailed procedure.
- Environmental compensation is retained as an enforcement object; it does not erase the CCC shortfall ledger.
- G.S.R. 25(E), 13 Jan 2026 is stored as a separate amendment relationship. It adds a Second Schedule/additional sectors; the five pilot cement obligations remain bound to the principal First Schedule unless a source specifically amends those registrations.

### China national ETS — cement
- Final 2024/2025 allocation plan issued Nov 2025.
- Cement allocation is calculated at clinker-production-line level.
- 2024 eligible allocation equals verified emissions.
- 2025 standard line: `A = E × (1 + alpha)`, `X=(B-I)/B`; alpha = `0.15X` for `-20%<X<20%`, +0.03 for `X>=20%`, -0.03 for `X<=-20%`.
- Certain specified 2025 special clinker lines receive verified-emissions allocation.
- Lines newly commissioned in the relevant year or closed before final allocation are excluded under the final plan.
- Direct emissions are covered; purchased electricity/heat indirect emissions are outside the current cement allocation scope.
- The 2026 allocation policy is stored as CONSULTATION -> APPROVED_IN_PRINCIPLE as of 24 Aug 2026. No production formula is attached until formal promulgation is verified.
- 2026 work notice stores the 26,000 tCO2e annual direct-emissions threshold context for the 2027 key-emitter list.

## Ledger integrity
`carbon_transaction` is append-only. Corrections require compensating transactions.
Account/lot balances are derived from the immutable ledger and may not become negative.
BANK is a retained state transition, not new credit creation.
Purchase/transfer and surrender are distinct events.
Settlement is versioned; a revised verification/settlement never erases the prior one.

## Acceptance
PG-05 is BUILD CANDIDATE until V010, V011 and T006 execute successfully on a live supported PostgreSQL instance after V001-V009.
