# RootDown

A platform-agnostic, single-script deployable file organization standard. Works on Windows, macOS, Linux, and WSL. Supports single-user and multi-user/multi-machine deployments via a profile system.

## Architecture

| Layer | File | Purpose |
|-------|------|---------|
| Standard | `standard/organization-standard.json` | Canonical folder structure — no platform assumptions |
| Deployer | `deploy.py` | Single entry point; detects platform, reads standard, creates structure |
| Profiles | `profiles/*.json` | Per-user or per-machine overrides (root path, exclusions, extras) |
| Auditor | `audit.py` | Drift detection; compares deployed structure against standard, reports only |

## Folder Standard

The canonical data root contains the following top-level structure:

```
<root>/
├── 00_INBOX
├── 10_PROJECTS
├── 20_OPERATIONS
├── 25_PERSONAL
├── 30_MEDIA
├── 40_REFERENCE
├── 50_SYSTEM
└── 90_ARCHIVE
```

The default root is platform-detected (`C:\Data` on Windows, `~/Data` on macOS/Linux). Profiles can override this per machine.

## Usage

```bash
# Deploy the standard folder structure
python deploy.py

# Deploy with a specific profile
python deploy.py --profile workstation

# Preview without writing anything
python deploy.py --dry-run

# Audit an existing deployment for drift
python audit.py

# Audit and write a report
python audit.py --report audit-report.csv
```

## Profiles

Place profile JSON files in `profiles/`. A profile is selected by name (`--profile <name>`) or by hostname auto-detection. Profiles can override the root path, add machine-specific folders, or exclude standard folders not relevant to that machine.

## Safety

- `deploy.py` never deletes or overwrites existing content
- `audit.py` is strictly read-only — it never moves, renames, or deletes anything
- All operations default to reporting intent before writing; use `--dry-run` to preview

## Legacy

The original K6-specific Windows/PowerShell migration scripts are preserved in `scripts/legacy/` for reference. They are not part of the current architecture.
