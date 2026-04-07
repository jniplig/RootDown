# Batch 2 Validation Note

## Date
2026-04-07

## Scope
This note records the result of the first Batch 2 copy-first execution for app-managed and workflow-sensitive media folders.

## Batch 2 copy-first result
The following source folders were copied successfully into the canonical `C:\Data` structure:

- `C:\Users\jnipl\OneDrive\Documents\ATEM Autosave\2026-04-05` -> `C:\Data\50_SYSTEM\Config_Backups\Blackmagic_ATEM\ATEM_Autosave\2026-04-05`
- `C:\Users\jnipl\OneDrive\Documents\Resolume Arena\Preferences` -> `C:\Data\50_SYSTEM\Config_Backups\Resolume\Preferences`
- `C:\Users\jnipl\OneDrive\Documents\Resolume Arena\Presets` -> `C:\Data\50_SYSTEM\Config_Backups\Resolume\Presets`
- `C:\Users\jnipl\OneDrive\Documents\Resolume Arena\Fixture Library` -> `C:\Data\50_SYSTEM\Config_Backups\Resolume\Fixture_Library`
- `C:\Users\jnipl\OneDrive\Documents\Resolume Wire\Preferences` -> `C:\Data\50_SYSTEM\Config_Backups\Resolume_Wire\Preferences`
- `C:\Users\jnipl\OneDrive\Documents\Resolume Arena\Compositions` -> `C:\Data\10_PROJECTS\Studio\Resolume_Shows`

## Verification
Verified destinations after copy:
- `C:\Data\50_SYSTEM\Config_Backups\Blackmagic_ATEM\ATEM_Autosave`
- `C:\Data\50_SYSTEM\Config_Backups\Resolume`
- `C:\Data\50_SYSTEM\Config_Backups\Resolume_Wire`
- `C:\Data\10_PROJECTS\Studio\Resolume_Shows`

Verified composition files present in `C:\Data\10_PROJECTS\Studio\Resolume_Shows`:
- `Example.avc`
- `OSMO-OBS.avc`

## Current decision state
- Originals remain in place.
- No source folders were moved or deleted.
- This was a copy-first validation step only.

## Still to validate
- Open `OSMO-OBS.avc` from `C:\Data\10_PROJECTS\Studio\Resolume_Shows`
- Confirm Resolume opens the composition normally from the new location
- Confirm linked assets resolve correctly
- Decide later whether the original `Compositions` location should remain live or become legacy

## Do not do yet
- Do not delete the original source folders
- Do not move live app-managed Resolume or Blackmagic paths blindly
- Do not treat copied config snapshots as replacement live paths without application-level validation

## Related artifacts
- `docs/batch-2-assessment-and-plan.md`
- `scripts/batch-2-copy-first.ps1`
