# k6-organization

This repository defines and supports a standardized file organization model for a GMKTec K6 system. It contains the canonical folder standard, a safe WSL test helper, a Windows structure creation script, a conservative rename assistant, and an audit-only inventory script for classifying existing files before any migration work.

The canonical root in the operating standard is `C:\Data`. Under that root, the approved top-level structure is:

- `00_INBOX`
- `10_PROJECTS`
- `20_OPERATIONS`
- `25_PERSONAL`
- `30_MEDIA`
- `40_REFERENCE`
- `50_SYSTEM`
- `90_ARCHIVE`

The scripts in this repository are designed to support that model without taking destructive actions by default.

## Repository Contents

### Documentation

- `README.md`
  Brief project overview, file inventory, and recommended usage sequence.
- `docs/k6-organization-standard.md`
  Formal operating standard for the `C:\Data` folder model, including naming rules, tags, project structure, and maintenance expectations.

### Scripts

- `scripts/create-k6-structure.sh`
  Safe Bash helper for WSL testing. It creates a mock Windows-style tree under `./mock/C/Data` and prints the intended `C:\Data` target tree for reference.
- `scripts/create-k6-structure.ps1`
  PowerShell script that creates the real canonical folder structure under `C:\Data` by default, with optional root override.
- `scripts/rename-to-standard.ps1`
  Conservative file renaming assistant that proposes compliant filenames using the standard naming pattern and defaults to dry-run behavior.
- `scripts/audit-k6-tree.ps1`
  Audit-only PowerShell helper that inventories files and folders and suggests likely categories in the new model based on simple heuristics.

## Recommended Usage Sequence

1. Read the standard in `docs/k6-organization-standard.md`.
2. Create the folder structure.
3. Audit the existing file tree.
4. Dry-run the renaming helper.
5. Apply renames intentionally after review.

In practice that usually looks like this:

```text
1. Review the standard
2. Create the target structure
3. Generate an audit report
4. Generate a rename proposal report
5. Re-run with -Apply only after manual review
```

## Safety Notes

These tools should be reviewed before use on real data. The repository is intentionally opinionated, but the scripts default to safe, non-destructive behavior wherever practical:

- the Bash helper never writes to `C:\Data`
- the renaming helper defaults to dry-run
- the audit helper does not move, rename, or delete anything
- the structure creation helpers do not delete existing content

## Quick Start

### WSL mock structure test

```bash
cd ~/projects/k6-organization
./scripts/create-k6-structure.sh
```

### Real Windows structure creation

```powershell
.\scripts\create-k6-structure.ps1
```

### Audit existing user folders

```powershell
.\scripts\audit-k6-tree.ps1 -ReportPath .\audit-report.csv
```

### Dry-run standardized rename proposals

```powershell
.\scripts\rename-to-standard.ps1 -Path C:\Data\00_INBOX -Recurse -ReportPath .\rename-report.csv
```
