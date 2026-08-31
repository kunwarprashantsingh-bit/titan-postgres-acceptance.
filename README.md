# TITAN PostgreSQL 18.6 Live Acceptance Environment v1.0

This package turns the PG-01 through PG-10 build candidates into a **disposable executable PostgreSQL acceptance lab**.

## What is pinned
- Docker Official Image: `postgres:18.6-bookworm`
- PostgreSQL acceptance range enforced by SQL: `>=18.6` and `<19`
- Required extensions: `btree_gist`, `pgcrypto`
- Database is internal to the Docker network by default; no host PostgreSQL port is published.

## Prerequisite
Install Docker Desktop (Windows/macOS) or Docker Engine + Compose plugin (Linux).

## Windows — one command
Open PowerShell in this folder and run:

```powershell
.\run_acceptance.ps1
```

## macOS / Linux — one command

```bash
chmod +x run_acceptance.sh run_pitr_lab.sh
./run_acceptance.sh
```

The script will:
1. destroy any previous **disposable** TITAN Docker acceptance volumes;
2. build the PostgreSQL 18.6 image with required contrib extensions;
3. run V001–V020;
4. run structural + security gates;
5. run T001–T011;
6. run two clean builds and compare deterministic schema fingerprints;
7. run the two-writer optimistic concurrency test;
8. run the pgbench smoke test;
9. run the logical dump/restore drill;
10. write the evidence bundle under `artifacts/`.

A successful run ends with:

```text
=== CORE LIVE ACCEPTANCE PASS ===
```

and creates `artifacts/ACCEPTANCE_SUMMARY.txt`.

## Inspect the database after a successful run
By default the environment is destroyed after acceptance. To keep it running:

### PowerShell
```powershell
$env:TITAN_KEEP_DOCKER="YES"
.\run_acceptance.ps1
```

### Bash
```bash
TITAN_KEEP_DOCKER=YES ./run_acceptance.sh
```

Then inspect it without exposing a host port:

```bash
docker compose exec db psql -U postgres -d titan_acceptance_full_docker
```

Clean it afterward:

```bash
docker compose down -v --remove-orphans
```

## Optional disposable PITR lab
First keep the accepted source database running, then:

### PowerShell
```powershell
$env:TITAN_KEEP_DOCKER="YES"
.\run_acceptance.ps1
.\run_pitr_lab.ps1
```

### Bash
```bash
TITAN_KEEP_DOCKER=YES ./run_acceptance.sh
./run_pitr_lab.sh
```

The PITR lab takes a physical base backup before two recovery markers, archives WAL, restores an isolated PostgreSQL cluster to the timestamp between the markers, and requires:
- PRE_TARGET marker = present;
- POST_TARGET marker = absent;
- TITAN base structural gate = PASS;
- TITAN security/RLS gate = PASS.

This is **lab evidence**, not a substitute for production backup topology, production RPO/RTO or the deployment PITR contract in `core/recovery/PITR_DRILL_CONTRACT.md`.

## Evidence folders
- `artifacts/full_acceptance/`
- `artifacts/full_replay/`
- `artifacts/concurrency/`
- `artifacts/load/`
- `artifacts/restore/`
- `artifacts/pitr/` (optional)

## Safety
The core acceptance harness refuses destructive database recreation unless the database name begins with `titan_acceptance_`. Docker volumes created by this lab are disposable. Do not mount production PostgreSQL data into this environment.

## Promotion rule
A Docker lab pass is strong **live test-system acceptance evidence**, but production promotion still requires deployment-specific security review, capacity/SLO approval and production-style WAL/PITR recovery evidence with approved RPO/RTO thresholds.
