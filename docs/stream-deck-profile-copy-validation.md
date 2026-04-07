# Stream Deck Profile Copy-First Validation

## Date
2026-04-07

## Scope
This note records the validated result of the Stream Deck profile copy-first operation.

## Validated outcome
Downloaded Stream Deck profile files from:
`C:\STREAM DECK`

were copied successfully to the canonical backup location:
`C:\Data\50_SYSTEM\Config_Backups\Stream_Deck\Profiles`

## Verified copied files
- `Epic Sounds-1.streamDeckProfile`
- `FPS Sounds-1.streamDeckProfile`
- `Popular Sounds-1.1.streamDeckProfile`
- `Prankster Soundboard by Voicemod-1.streamDeckProfile`
- `Reactions Soundboard by Voicemod-1.streamDeckProfile`

## Current decision state
- The canonical backup location for downloaded Stream Deck profile files is now validated.
- The original `C:\STREAM DECK` folder remains in place for now as a legacy source location.
- No files were moved or deleted as part of this step.

## Do not do yet
- Do not delete `C:\STREAM DECK` immediately without a short review period.
- Do not broaden this step into a full Stream Deck app-path migration without explicit validation.

## Related artifacts
- `scripts/stream-deck-profile-copy-first.ps1`
- `docs/c-drive-root-normalization-validation.md`
