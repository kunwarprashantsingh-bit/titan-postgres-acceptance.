#!/usr/bin/env python3
from pathlib import Path
import json, re, sys, hashlib
try:
    import yaml
except Exception:
    yaml = None

root=Path(__file__).resolve().parent
errors=[]

def require(cond,msg):
    if not cond: errors.append(msg)

# Core chain
v=sorted((root/'core/sql').glob('V*.sql'))
t=sorted((root/'core/sql').glob('T*.sql'))
require(len(v)==20,f'expected 20 migrations, found {len(v)}')
require(len(t)==11,f'expected 11 test suites, found {len(t)}')
for i,p in enumerate(v,1): require(p.name.startswith(f'V{i:03d}__'),f'migration sequence mismatch at {p.name}')
for i,p in enumerate(t,1): require(p.name.startswith(f'T{i:03d}__'),f'test sequence mismatch at {p.name}')

# Migration wrappers and duplicate tables / ordering references.
created=set(); dup=[]; refs=[]
for p in v:
    s=p.read_text(encoding='utf-8')
    require('BEGIN;' in s and 'COMMIT;' in s,f'{p.name}: transaction wrapper missing')
    require(s.count('$$')%2==0,f'{p.name}: unbalanced $$')
    creates=[m.group(1).lower() for m in re.finditer(r'CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?([A-Za-z0-9_.]+)',s,re.I)]
    current=set(creates)
    for name in creates:
        if name in created: dup.append((p.name,name))
        created.add(name)
    for m in re.finditer(r'REFERENCES\s+([A-Za-z0-9_.]+)',s,re.I):
        ref=m.group(1).lower()
        if '.' in ref and ref not in created and ref not in current:
            refs.append((p.name,ref))
require(not dup,f'duplicate CREATE TABLE objects: {dup[:10]}')
require(not refs,f'reference-before-create objects: {refs[:10]}')

# Test contracts and assertion count.
assertion_sum=0
for p in t:
    s=p.read_text(encoding='utf-8')
    require('\\set ON_ERROR_STOP on' in s,f'{p.name}: ON_ERROR_STOP missing')
    require(s.count('$$')%2==0,f'{p.name}: unbalanced $$')
    assertion_sum += len(set(re.findall(r'(?:PG\d{2}-T\d{3}|T\d{3})',s)))
require(assertion_sum==229,f'expected 229 numbered assertion mentions by suite, found {assertion_sum}')

# Safety / runner contract.
full=(root/'core/acceptance/run_full_operational_acceptance.sh').read_text()
require('TITAN_ACCEPTANCE_ALLOW_DROP' in full,'destructive opt-in missing')
require('titan_acceptance_*' in full,'disposable database name guard missing')
require('V001-V020' in full and 'T001-T011' in full,'full runner scope missing')
require('--restrict-key=TITANFULLV1' in full,'deterministic acceptance schema key missing')

# Docker files.
compose_text=(root/'docker-compose.yml').read_text()
require('postgres:18.6-bookworm' in (root/'Dockerfile').read_text(),'Dockerfile not pinned to postgres:18.6-bookworm')
require('archive_mode=on' in compose_text,'WAL archiving not enabled in Docker lab')
require('pitr_data' in compose_text and 'wal_archive' in compose_text,'PITR/WAL volumes missing')
if yaml:
    obj=yaml.safe_load(compose_text)
    require(obj.get('name')=='titan-pg-live-acceptance','unexpected compose project name')
    require(set(obj.get('services',{}))=={'db','runner','pitr-prep','pitr-db','pitr-verify'},'compose services mismatch')

# Required files.
required=[
    'run_acceptance.sh','run_acceptance.ps1','run_pitr_lab.sh','run_pitr_lab.ps1','README.md','SOURCES.md',
    'docker/run_all.sh','docker/db_entrypoint.sh','docker/pitr_prepare.sh','docker/pitr_verify.sh',
    'core/acceptance/run_full_operational_acceptance.sh','core/acceptance/run_full_replay_twice.sh',
    'core/load/run_optimistic_concurrency.sh','core/load/run_pgbench_smoke.sh',
    'core/recovery/run_logical_restore_drill.sh','core/recovery/PITR_DRILL_CONTRACT.md'
]
for rel in required: require((root/rel).is_file(),f'missing required file: {rel}')

result={
    'package':'TITAN PostgreSQL 18.6 Live Acceptance Environment',
    'version':'1.0',
    'migrations':len(v),
    'test_suites':len(t),
    'assertion_count_by_suite_sum':assertion_sum,
    'unique_created_tables':len(created),
    'duplicate_create_tables':dup,
    'reference_before_create':refs,
    'docker_runtime_executed_in_build_environment':False,
    'static_validation':'PASS' if not errors else 'FAIL',
    'errors':errors,
}
print(json.dumps(result,indent=2))
if errors: sys.exit(1)
