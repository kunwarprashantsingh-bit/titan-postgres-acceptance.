# Runtime source verification — 30 August 2026

This disposable acceptance environment uses current upstream/public runtime information rather than a floating assumption.

- PostgreSQL 18.6 release notes — released 13 August 2026:
  https://www.postgresql.org/docs/release/18.6/
- Docker Official Image `postgres` — supported `18.6` / `18.6-bookworm` tags:
  https://hub.docker.com/_/postgres
  https://hub.docker.com/_/postgres/tags
- PostgreSQL 18 Debian package file set includes `pgbench` and supplied extensions including `btree_gist`:
  https://packages.debian.org/sid/amd64/postgresql-18/filelist
- PostgreSQL backup / PITR documentation:
  https://www.postgresql.org/docs/18/backup.html
  https://www.postgresql.org/docs/current/continuous-archiving.html

The Dockerfile additionally fails its build if `pgbench`, `btree_gist.control`, or `pgcrypto.control` is missing, so package assumptions fail closed at image-build time.
