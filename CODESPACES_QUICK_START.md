# TITAN PostgreSQL 18.6 — Browser-only GitHub Codespaces Quick Start

This version is for a locked-down Windows office laptop. **Nothing is installed on the laptop.** GitHub Codespaces provides the remote Linux machine, and the repository's Dev Container configuration installs a Docker-in-Docker daemon inside that remote environment.

## What you need
- A personal GitHub account.
- Access to `github.com` from your office browser.
- This folder uploaded to a **private personal GitHub repository**.

GitHub personal accounts currently include a monthly Codespaces quota. Organization/enterprise policies may differ.

## Step 1 — Create a private GitHub repository
1. Open GitHub in your browser.
2. Click **New repository**.
3. Name it, for example: `titan-postgres-acceptance`.
4. Select **Private**.
5. Create the repository.

## Step 2 — Upload these files
Use **Add file → Upload files** and upload the contents of this extracted folder, including the hidden `.devcontainer` folder.

If your browser upload does not preserve the hidden `.devcontainer` folder, create `.devcontainer/devcontainer.json` using GitHub's **Add file → Create new file** and paste the file supplied in this package. The Docker-in-Docker feature is essential.

## Step 3 — Create the Codespace
1. In the repository, click **Code**.
2. Open the **Codespaces** tab.
3. Click **Create codespace on main**.
4. GitHub will build the remote environment. This can take several minutes on first creation because the Docker-in-Docker feature is installed remotely.

When VS Code opens in the browser, the laptop is only acting as a browser client.

## Step 4 — Run the complete acceptance
Open **Terminal → New Terminal** in the browser and run:

```bash
./run_codespaces_acceptance.sh
```

The script waits for the remote Docker daemon, then runs the existing PostgreSQL 18.6 acceptance package unchanged.

A genuine successful run must end with:

```text
=== CORE LIVE ACCEPTANCE PASS ===
```

Evidence is written under `artifacts/` in the Codespace.

## Step 5 — Preserve the evidence
After the run, use the VS Code Explorer in the browser to download the `artifacts` folder/files you want to retain, or commit the acceptance evidence to the private repository if appropriate for your information-security policy.

## Optional PITR lab
If the main acceptance passes and you want to run the isolated PITR lab:

```bash
export TITAN_KEEP_DOCKER=YES
./run_codespaces_acceptance.sh
./run_pitr_lab.sh
```

## Security / office-policy note
This avoids installing software locally, but it still uses an external cloud service. Do not upload employer-confidential material unless your employer permits it. The current package contains TITAN implementation/test assets; use a private personal repository and follow your organization's information-security rules.
