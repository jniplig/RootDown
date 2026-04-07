# Batch 2 Assessment and Plan

## A. Objective

Batch 2 covers app-managed or workflow-sensitive folders that require cautious assessment before standardization.

The goal is to reduce path sprawl without breaking application behavior. The default posture for Batch 2 is cautious validation before movement.

Resolve paths are already validated and are treated as established. Batch 1 is treated as complete.

## B. In-Scope Items

### Blackmagic Design

- Why it is in Batch 2:
  It likely contains workflow-sensitive Blackmagic or ATEM-related material that should be reviewed before standardization.
- Why it is more sensitive than Batch 1:
  It may contain app-managed folders, support data, autosaves, or configuration material used by installed tools.
- Default action:
  Inspect first, copy-first where needed, and move only after validation.

### ATEM Autosave

- Why it is in Batch 2:
  It is directly associated with autosave and recovery behavior.
- Why it is more sensitive than Batch 1:
  Autosave material may be application-generated and may depend on expected location or workflow habits.
- Default action:
  Inspect first, prefer copy-first, and move only after validation.

### Resolume Arena

- Why it is in Batch 2:
  It may contain a mix of show files, reusable assets, and application-sensitive folders.
- Why it is more sensitive than Batch 1:
  Active show workflows may depend on configured paths, linked media, or project-relative structures.
- Default action:
  Repoint in app first where applicable, then copy-first, then move only after validation.

### Resolume Wire

- Why it is in Batch 2:
  It may contain active creative project files or workflow-specific support data.
- Why it is more sensitive than Batch 1:
  Wire projects may be part of ongoing work and may not be safe to relocate without confirming workflow expectations.
- Default action:
  Inspect first, repoint in app first where applicable, and move only after validation.

## C. Risk Classification

- Safe to inspect
  Blackmagic Design: inspection is low risk and needed to identify backups, exports, or app-managed content.
  ATEM Autosave: inspection is low risk and needed to distinguish retained autosaves from active workflow data.
  Resolume Arena: inspection is low risk and needed to distinguish show files, assets, and app-sensitive folders.
  Resolume Wire: inspection is low risk and needed to determine whether content is active project work or backup material.

- Copy-first recommended
  Blackmagic Design: copy-first is preferred because the folder may contain workflow-sensitive app data.
  ATEM Autosave: copy-first is preferred because autosaves are recovery assets and should be preserved during validation.
  Resolume Arena: copy-first is preferred for uncertain assets or show-related content until workflows are verified.
  Resolume Wire: copy-first is preferred for active project material until the application workflow is confirmed.

- Repoint in app first
  Resolume Arena: verify in app whether compositions, assets, or export paths can be repointed before relocation.
  Resolume Wire: verify in app whether active project paths or export paths are configurable before relocation.
  Blackmagic Design: verify in app where relevant before relocating configured or generated output paths.

- Do not move until verified
  Blackmagic Design: do not move until the folder contents are classified as backups, exports, or app-managed data.
  ATEM Autosave: do not move until it is clear what is retained backup material versus active workflow-sensitive data.
  Resolume Arena: do not move until show files, assets, and app-managed material are clearly separated.
  Resolume Wire: do not move until active project dependencies and expected application behavior are confirmed.

## D. Proposed Canonical Destinations

These are target standards pending validation.

### Blackmagic Design

- Backups, exported config, or retained autosaves:
  `C:\Data\50_SYSTEM\Config_Backups\Blackmagic_ATEM`
- Media outputs if applicable:
  `C:\Data\30_MEDIA\Video\Blackmagic`

### ATEM Autosave

- Retained autosaves or exported backups:
  `C:\Data\50_SYSTEM\Config_Backups\Blackmagic_ATEM\ATEM_Autosave`

### Resolume Arena

- Show files and compositions:
  `C:\Data\10_PROJECTS\Studio\Resolume_Shows`
- Reusable assets:
  `C:\Data\30_MEDIA\Resolume\Assets`
- Config snapshots or exported backups:
  `C:\Data\50_SYSTEM\Config_Backups\Resolume`

### Resolume Wire

- Project files that are part of active creative work:
  `C:\Data\10_PROJECTS\Studio\Resolume_Wire`
- Backup or export snapshots if appropriate:
  `C:\Data\50_SYSTEM\Config_Backups\Resolume_Wire`

## E. Batch 2 Validation Workflow

### Batch 2 Validation Workflow

1. Inspect current folder contents.
2. Determine whether the folder is app-managed, export-oriented, or project-oriented.
3. If the path is manually set inside the app, repoint it in the application first.
4. Verify read/write behavior in the app.
5. Prefer copy-first for anything uncertain.
6. Move only after verification.
7. Archive or remove old locations only after successful validation.

## F. Folder-Specific Checklists

### Blackmagic / ATEM

- Confirm whether the folder contains active working data, exports, caches, autosaves, or backups.
- Confirm whether the application expects the folder at a fixed path.
- Identify what should remain app-managed.
- Identify what can be standardized under `C:\Data`.
- Prefer exported backups over raw relocation when available.

### Resolume Arena

- Confirm whether the folder contains active show files, reusable assets, caches, or exports.
- Confirm whether Resolume paths are configurable in the application. Verify in app.
- Identify what should remain app-managed.
- Identify what belongs under `C:\Data\10_PROJECTS\Studio\Resolume_Shows`.
- Identify what belongs under `C:\Data\30_MEDIA\Resolume\Assets`.

### Resolume Wire

- Confirm whether the folder contains active project files, exports, caches, or snapshots.
- Confirm whether the application expects a fixed working location. Verify in app.
- Identify what should remain app-managed.
- Identify what belongs under `C:\Data\10_PROJECTS\Studio\Resolume_Wire`.
- Prefer exported backups or snapshots over direct relocation when available.

## G. What Batch 2 Does Not Do

Batch 2 does not:

- blindly move app-managed folders
- rename files as part of migration
- reorganize caches without application-level validation
- assume all discovered folders are safe to relocate
- override in-app path settings from the file system side

## H. Deliverables for Completion

Batch 2 is complete when these outcomes exist:

- validated destination decisions for each in-scope item
- app-level path confirmation where relevant
- copy or move decisions documented
- any remaining exceptions explicitly recorded

## I. Final Operating Principle

App-managed and workflow-sensitive paths must be validated through the application workflow before they are standardized in the file system.
