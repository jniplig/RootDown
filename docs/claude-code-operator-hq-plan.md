# Claude Code Operator HQ Path Change Plan

## Date
2026-04-07

## Scope
This note records the handling decision for the `C:\OPERATOR HQ` folder.

## Current decision
`C:\OPERATOR HQ` is excluded from generic C drive root normalization.

Reason:
- it is used by Claude Code
- the path should be updated manually inside Claude Code
- there are additional Claude-related settings that should be updated together before any migration is finalized

## Planned target location
`C:\Data\10_PROJECTS\Claude_Code\Operator_HQ`

## Migration posture
- copy-first
- repoint in application
- validate all relevant Claude Code settings together
- move or retire the old location only after successful validation

## Validation checklist
- create the target folder
- copy `C:\OPERATOR HQ` to the target location
- update Claude Code settings manually
- verify Claude Code reads and writes normally from the new location
- confirm no important setting still points to the old path
- keep the old location in place until validation is complete

## Do not do yet
- do not move `C:\OPERATOR HQ` directly
- do not delete the original folder
- do not treat the new location as canonical until Claude Code validation is complete
