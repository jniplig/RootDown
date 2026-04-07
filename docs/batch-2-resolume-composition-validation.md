# Batch 2 Resolume Composition Validation

## Date
2026-04-07

## Validation target
`C:\Data\10_PROJECTS\Studio\Resolume_Shows\OSMO-OBS.avc`

## Result
Validated successfully.

## Outcome
- `OSMO-OBS.avc` opened successfully from the canonical project-space location.
- `C:\Data\10_PROJECTS\Studio\Resolume_Shows` is now validated as the canonical Resolume composition location.
- This validates the copied composition path for active use.

## Important boundary
This validation confirms the composition file opens correctly from the new location.
It does not, by itself, guarantee that every related asset path, render path, or preference path has been fully standardized.

## Current decision
- Treat `C:\Data\10_PROJECTS\Studio\Resolume_Shows` as the canonical live location for Resolume composition files.
- Keep original source material in place until there is a deliberate cleanup step.
- Continue treating Resolume preferences, presets, and other config-sensitive folders as copy-first backup material unless separately validated.

## Related artifacts
- `docs/batch-2-assessment-and-plan.md`
- `docs/batch-2-validation-note.md`
- `scripts/batch-2-copy-first.ps1`
