# Legacy Scripts

These are the original K6-specific Windows/PowerShell scripts created during the initial GMKTec K6 file organization migration (2024–2025). They are preserved here as reference only.

They are not part of the current RootDown architecture and should not be used for new deployments. The canonical deployer is `deploy.py` at the repo root.

## Scripts

| File | Purpose |
|------|---------|
| `create-k6-structure.ps1` | Creates the canonical `C:\Data` folder structure on Windows |
| `create-k6-structure.sh` | WSL mock version of the above for safe local testing |
| `rename-to-standard.ps1` | Proposes compliant filenames, dry-run by default |
| `audit-k6-tree.ps1` | Inventories files and suggests categories, read-only |
| `first-safe-migration-batch.ps1` | Batch 1 migration of safe directories and audio files |
| `batch-2-copy-first.ps1` | Batch 2 copy-first operations for ATEM and Resolume folders |
