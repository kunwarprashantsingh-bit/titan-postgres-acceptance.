$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { throw "Docker required." }

docker compose exec -T db pg_isready -U postgres -d postgres *> $null
if ($LASTEXITCODE -ne 0) {
    throw "Source db is not running. First run: `$env:TITAN_KEEP_DOCKER='YES'; .\run_acceptance.ps1"
}
if (Test-Path "artifacts/pitr") { Remove-Item -Recurse -Force "artifacts/pitr" }
New-Item -ItemType Directory -Force -Path "artifacts/pitr" | Out-Null

docker compose --profile pitr rm -sf pitr-db pitr-prep pitr-verify 2>$null | Out-Null

Write-Host "[1/5] Reset PITR backup volume and take physical base backup locally"
docker compose exec -T db bash -lc "rm -rf /pitr/* && mkdir -p /pitr/18/docker && chown -R postgres:postgres /pitr && gosu postgres pg_basebackup -D /pitr/18/docker -Fp -Xs -P"
if ($LASTEXITCODE -ne 0) { throw "Physical base backup failed." }

Write-Host "[2/5] Create recovery markers, archive WAL and configure recovery target"
docker compose --profile pitr run --rm pitr-prep
if ($LASTEXITCODE -ne 0) { throw "PITR preparation failed." }

Write-Host "[3/5] Start recovered PostgreSQL cluster"
docker compose --profile pitr up -d pitr-db
if ($LASTEXITCODE -ne 0) { throw "PITR database failed to start." }

$healthy=$false
for ($i=0; $i -lt 120; $i++) {
    docker compose --profile pitr exec -T pitr-db pg_isready -U postgres -d postgres *> $null
    if ($LASTEXITCODE -eq 0) { $healthy=$true; break }
    Start-Sleep -Seconds 1
}
if (-not $healthy) { throw "PITR database did not become ready." }

Write-Host "[4/5] Verify target-time semantics and TITAN gates"
docker compose --profile pitr run --rm pitr-verify
if ($LASTEXITCODE -ne 0) { throw "PITR verification failed." }

Write-Host "[5/5] PITR lab evidence"
Get-Content "artifacts/pitr/PITR_SUMMARY.txt"
Write-Host "NOTE: disposable lab evidence only; production RPO/RTO still needs deployment PITR certification."
