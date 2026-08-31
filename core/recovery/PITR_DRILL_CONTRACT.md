# PG-10 Point-in-Time Recovery Drill Contract

This is a deployment acceptance contract, not a cloud-topology prescription.

## Required production capability
1. Continuous WAL archiving enabled and monitored.
2. Periodic base backups stored independently of the primary database host.
3. Restore credentials and archive access separated from editorial/application roles.
4. Recovery target is an isolated cluster/database; never test PITR against production.
5. PostgreSQL server/client minor versions remain on the current supported maintenance release.

## Drill sequence
1. Confirm the most recent base backup is restorable and WAL archiving has no unresolved failures.
2. Insert a unique row into `titan_ops.recovery_probe` with marker `PRE_TARGET_<run-id>` and record the commit timestamp.
3. Force/observe WAL archival progression (`pg_switch_wal()` may be used in a controlled drill).
4. Record a target timestamp after the PRE_TARGET commit.
5. Insert `POST_TARGET_<run-id>` after that target timestamp and confirm its WAL is archived.
6. Restore the base backup to a new isolated cluster and configure the archive restore mechanism.
7. Recover to the recorded target timestamp/timeline.
8. Verify:
   - `PRE_TARGET_<run-id>` exists.
   - `POST_TARGET_<run-id>` does not exist.
   - PG-09 structural/pilot gates pass.
   - PG-10 security/RLS gate passes.
   - dataset/publication snapshot hashes referenced by production records remain valid.
9. Record actual recovery start, database-open time and integrity-verification completion time.
10. Record actual data-loss window relative to the requested target.

## Acceptance
- Recovery reaches the intended point in time, not merely “latest available”.
- No post-target marker survives.
- Pre-target marker and governed TITAN state survive.
- No role/RLS relaxation is introduced to make restore succeed.
- Any archive gap, restore warning, checksum failure or missing evidence object is a FAIL.
- RPO and RTO are measured during the drill. Numerical SLO thresholds must be defined by deployment/business requirements before production go-live; PG-10 does not invent them.

## Evidence to retain
- base-backup identifier/hash
- WAL archive/timeline identifiers
- target timestamp/timeline
- PostgreSQL version
- restore configuration reference
- start/open/verified timestamps
- A002/A011 outputs
- restored schema fingerprint
- failure/exception log
