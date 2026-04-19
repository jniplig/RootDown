# RootDown

RootDown is a platform-agnostic file organization standard with a Python deployer and auditor. It defines a canonical folder structure, reads it from a JSON manifest, and creates it on any machine — Windows, macOS, or Linux/WSL — with a single command. A profile system allows per-machine and per-user overrides without modifying the standard itself.

---

## The Standard

The canonical data root is `C:\Data` on Windows and `~/Data` on macOS and Linux. All organized material lives under this root.

| Folder | Purpose |
|--------|---------|
| `00_INBOX` | Landing zone for unsorted or newly captured material awaiting review and placement |
| `10_PROJECTS` | Active and completed project work, organized using the standard project template |
| `20_OPERATIONS` | Reusable business, administrative, and operational materials that are not project-specific |
| `25_PERSONAL` | Personal records, household administration, and structured personal information |
| `30_MEDIA` | Photos, videos, audio, graphics, and other media-first assets |
| `40_REFERENCE` | Manuals, guides, knowledge resources, and non-active reference content |
| `50_SYSTEM` | Scripts, exports, drivers, installers, configuration files, and system support material |
| `90_ARCHIVE` | Inactive or historical material retained for recordkeeping and long-term storage |

The full standard including subfolders, lifecycle policies, and naming conventions is defined in `standard/organization-standard.json`.

---

## Quick Start

**Windows:**
```powershell
git clone https://github.com/jniplig/rootdown.git
cd rootdown
.\install.ps1
```

**macOS / Linux / WSL:**
```bash
git clone https://github.com/jniplig/rootdown.git
cd rootdown
./install.sh
```

**With a profile:**
```powershell
.\install.ps1 --profile profiles/profile-personal.json
```
```bash
./install.sh --profile profiles/profile-personal.json
```

**Live deploy (writes to disk):**
```powershell
.\install.ps1 --no-dry-run
```
```bash
./install.sh --no-dry-run
```

---

## Profiles

A profile is a JSON file that customizes a deployment without changing the standard. Use a profile to:

- Override the data root path for a specific machine
- Add folders that are not in the universal standard (e.g. `09_Personal_Projects` under `25_PERSONAL`)
- Adjust lifecycle policies per folder

Start from the template:

```bash
cp profiles/profile-template.json profiles/profile-mymachine.json
```

Edit `profile_name`, `machine`, `owner`, and any overrides, then pass it to the deployer:

```bash
python deploy.py --profile profiles/profile-mymachine.json
```

---

## Audit

`audit.py` checks an existing deployment against the standard and reports drift. It never modifies anything on disk.

```bash
# Summary to console
python audit.py

# Verbose — print every finding
python audit.py --verbose

# Write a CSV report
python audit.py --report audit.csv

# Audit with a specific profile
python audit.py --profile profiles/profile-personal.json --report audit.csv
```

Findings are classified as:

| Classification | Meaning |
|---------------|---------|
| `OK` | Folder exists and is accounted for in the standard or profile |
| `MISSING` | A required standard folder does not exist on disk |
| `UNKNOWN` | A folder exists on disk but is not in the standard or profile |
| `INBOX_AGE` | A file in `00_INBOX` exceeds the lifecycle review age |

---

## Migration

`migrate.py` moves existing files and folders from an unorganized source root into the RootDown standard. It runs in three explicit stages: scan, triage, and apply. Nothing is moved until `--apply` is explicitly passed — the scan and triage stages are entirely read-only, and the apply stage uses a copy-first strategy that verifies each copy before deleting the source.

### Stage 1 — Scan

```bash
python migrate.py --report migrate.csv
```

The scanner reads every item at the top level of the source root (default: home directory), classifies each as `HIGH_RISK`, `CAUTION`, or `SAFE`, and suggests a destination folder. Results are written to `triage-log.json` and optionally to a CSV for review.

### Stage 2 — Interactive Triage

```bash
python migrate.py --profile profiles/profile-personal.json
```

Each item is presented for a decision: `(m)ove`, `(s)kip`, `(p)rotect`, or `(d)efer`. Items are grouped by risk tier and presented in order:

| Tier | Meaning |
|------|---------|
| `HIGH_RISK` | Matches a protected path pattern (AppData, .git, .venv, etc.) — reviewed individually, never batched |
| `CAUTION` | No strong risk or safety signal — reviewed individually or in same-parent batches |
| `SAFE` | Clear user content (photo, document, audio) — reviewed as destination-grouped batches |

Triage sessions persist between runs. Quitting mid-session saves all decisions so far; the next run resumes where it left off and re-presents only undecided and deferred items. `defer` means "ask me again next session"; `skip` means "leave it where it is permanently".

### Stage 3 — Apply

```bash
python migrate.py --apply
```

The apply pass reads `triage-log.json` and processes every item with `decision: "move"`. Before anything moves, it prints a summary and requires you to type `CONFIRM`:

```
Type CONFIRM to proceed, or anything else to abort:
  >
```

Each item is copied first (`shutil.copy2` for files, `copytree` for directories), verified, and only then deleted from the source. If a filename already exists at the destination, the copy is written as `name_1.ext`, `name_2.ext`, and so on — the original is never overwritten. Every outcome is logged back to `triage-log.json` (`apply_status: moved | failed | delete_failed`), which serves as a permanent audit trail. Use `--report apply.csv` to export results.

### Safety Notes

- `HIGH_RISK` items are always reviewed individually — they are never included in a batch decision.
- Every `(p)rotect` decision appends the item's path pattern to `protected-paths.json`, so it is automatically guarded in all future scans.
- A copy is fully verified before the source is deleted. If verification fails, the partial copy is removed and the source is left untouched.
- Failed copies are recorded in `triage-log.json` with `apply_status: failed`. The source file is never deleted on a failed or unverified copy.

---

## Repository Structure

```
RootDown/
├── deploy.py                          # Deployer — creates folder structure on any platform
├── audit.py                           # Auditor — drift detection and reporting
├── standard/
│   └── organization-standard.json    # Canonical folder manifest (source of truth)
├── profiles/
│   ├── profile-template.json         # Blank starting point for new profiles
│   └── profile-personal.json         # Single-user profile with personal project folder
├── lib/
│   └── common.py                     # Shared utilities (load_json, resolve_data_root)
├── docs/                             # Extended documentation and migration records
└── legacy/                           # Original machine-specific scripts (reference only)
```

---

## Design Principles

- **Safe by default.** The deployer runs in dry-run mode unless `--no-dry-run` is explicitly passed. The auditor never writes, moves, or deletes anything.
- **Manifest-driven.** The folder standard lives in a single JSON file. The deployer and auditor read from it — there is no logic that hardcodes folder names.
- **Platform-agnostic.** Platform detection is automatic. The data root resolves to `C:\Data` on Windows and `~/Data` elsewhere, or to whatever the profile specifies.
- **Profile-scoped customization.** Machine-specific or user-specific variations belong in profiles, not in the standard. The standard stays universal.
- **Non-destructive.** The deployer skips folders that already exist. The auditor reports findings without taking action. No existing content is ever modified.
