$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw "Docker Desktop / Docker CLI is required."
}
docker compose version | Out-Null

New-Item -ItemType Directory -Force -Path "artifacts" | Out-Null
$targets = @("artifacts/full_acceptance","artifacts/full_replay","artifacts/concurrency","artifacts/load","artifacts/restore","artifacts/ACCEPTANCE_SUMMARY.txt")
foreach ($t in $targets) { if (Test-Path $t) { Remove-Item -Recurse -Force $t } }

Write-Host "[1/5] Reset disposable Docker acceptance environment"
docker compose down -v --remove-orphans 2>$null | Out-Null

Write-Host "[2/5] Build pinned PostgreSQL 18.6 acceptance image"
docker compose build --pull
if ($LASTEXITCODE -ne 0) { throw "Docker build failed." }

Write-Host "[3/5] Start isolated PostgreSQL server"
docker compose up -d db
if ($LASTEXITCODE -ne 0) { throw "PostgreSQL container failed to start." }

try {
    $healthy = $false
    for ($i=0; $i -lt 90; $i++) {
        docker compose exec -T db pg_isready -U postgres -d postgres *> $null
        if ($LASTEXITCODE -eq 0) { $healthy = $true; break }
        Start-Sleep -Seconds 1
    }
    if (-not $healthy) { throw "PostgreSQL did not become healthy." }

    Write-Host "[4/5] Execute full acceptance + replay + concurrency + load + logical restore"
    docker compose run --rm runner
    if ($LASTEXITCODE -ne 0) { throw "TITAN acceptance runner failed. Review .\artifacts." }

    Write-Host "[5/5] Acceptance evidence written to .\artifacts"
    Get-Content ".\artifacts\ACCEPTANCE_SUMMARY.txt"
}
finally {
    if ($env:TITAN_KEEP_DOCKER -eq "YES") {
        Write-Host "TITAN_KEEP_DOCKER=YES: leaving Docker environment running for inspection."
    } else {
        docker compose down -v --remove-orphans 2>$null | Out-Null
    }
}
