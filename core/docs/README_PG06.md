# PG-06 — CCUS & Trade / CBAM Integration

PG-06 links physical carbon, product attributes and border-carbon exposure without collapsing them into one accounting object.

## PG-06A: CCUS
Core chain:
`capture project -> capture stream -> CO2 batch -> custody events -> chain state -> storage/injection/certificate -> permanence -> accounting class`

Important controls:
- design capture capacity is not actual capture;
- transferred CO2 is not permanently stored CO2;
- transferred-minus-stored residual is `IN_CHAIN_UNRECONCILED` until evidence identifies its fate;
- biogenic origin is separate from mineral/fossil origin and does not automatically become a removal;
- storage certificates are not invented from aggregate annual reporting;
- product/EAC attributes are a separate immutable ledger;
- generated attributes cannot exceed certified stored quantity;
- allocated/retired attributes cannot exceed account balance.

Brevik current verification:
- operational in current Heidelberg Materials material;
- design capacity about 400,000 tCO2/y;
- 2025 transferred to Northern Lights: 58,408 t CO2;
- permanently stored at reporting cut-off: 37,500 t CO2;
- residual: 20,908 t, kept in-chain/unreconciled rather than labelled loss;
- about 4,125 t biogenic origin, provisional pending final confirmation;
- lifecycle emissions: 1,236 tCO2e.

## PG-06B: Trade / CBAM
Core chain:
`shipment -> goods line -> physical route -> production installation -> precursor provenance -> embedded-emissions declaration -> threshold -> price -> exposure -> foreign carbon price evidence -> relief -> settlement`

Current CBAM verification:
- definitive regime active from 1 Jan 2026;
- annual threshold is >50 t, not >=50 t;
- Q1 2026 certificate price EUR 75.36; Q2 EUR 75.28;
- no Q3 price is seeded before its scheduled publication;
- corrected default-value regime uses 10% mark-up in 2026;
- actual values require verification;
- complex cement goods preserve precursor/source-installation lineage;
- transshipment does not rewrite producing installation or customs origin;
- Article 9 carbon-price-paid principle is in force, but the detailed conversion/evidence implementing act remains draft/consultation in current official sources, so `PENDING_RULE` is the production-safe state.

## Acceptance
PG-06 remains BUILD CANDIDATE until V012-V014 and T007 execute successfully on a live supported PostgreSQL instance after prior migrations.
