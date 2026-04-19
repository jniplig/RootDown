# RootDown File Organization Standard

## 1. Purpose

This standard defines the canonical file organization model for any target machine. Its purpose is to create a consistent, reviewable structure for active work, operational material, personal records, media, reference content, system assets, and archival storage.

The standard applies to the primary organized data root configured for the target machine.

This document defines:

- the required top-level folder layout
- the approved personal records structure
- the standard per-project subfolder model
- filename conventions
- tag guidance
- basic maintenance expectations

## 2. Canonical Root

The canonical managed root path is the data root configured for the target machine (e.g. `C:\Data` on Windows, `~/Data` on macOS/Linux).

All organized material governed by this standard should live within that root unless a specific operational exception is documented.

## 3. Required Top-Level Folders

The top-level folders under the data root must be exactly:

- `00_INBOX`
  Initial landing zone for unsorted or newly captured material awaiting review and placement.
- `10_PROJECTS`
  Active and completed project work organized using the standard project template.
- `20_OPERATIONS`
  Reusable business, administrative, process, and operational materials that are not project-specific.
- `25_PERSONAL`
  Personal records, household administration, and non-business structured personal information.
- `30_MEDIA`
  Photos, videos, audio, graphics, and other media-first assets.
- `40_REFERENCE`
  Manuals, guides, knowledge resources, research materials, and non-active reference content.
- `50_SYSTEM`
  Scripts, exports, drivers, inventories, configuration files, installers, and technical system support material.
- `90_ARCHIVE`
  Inactive or historical material retained for recordkeeping, traceability, or long-term storage.

## 4. Standard Personal Records Structure

The folder `25_PERSONAL` must contain these subfolders:

- `01_Family`
  Family records, household member information, school or dependent-related documents, and family coordination materials.
- `02_Finance`
  Banking, taxes, budgets, statements, insurance finance records, and other personal financial administration.
- `03_Property`
  Property ownership, leases, utilities, maintenance documentation, and asset-related records for homes or other property.
- `04_Travel`
  Bookings, itineraries, visa support material, travel confirmations, and trip planning records.
- `05_Health_Admin`
  Appointments, administrative health records, coverage records, and non-clinical medical administration.
- `06_Legal_and_ID`
  Identity documents, licenses, legal paperwork, government records, and formal personal documentation.
- `07_Personal_Admin`
  General life administration that does not fit a more specific personal category.
- `08_Warranties_and_Receipts`
  Purchase records, receipts, service confirmations, warranties, and proof-of-purchase material.
- `09_Personal_Projects`
  Personal initiatives and structured work that are not business projects but still benefit from deliberate organization.
- `99_Archive`
  Historical personal records kept for retention but no longer active.

## 5. Standard Per-Project Subfolder Model

Each project stored under `10_PROJECTS` should use the following standard subfolder structure:

- `01_ADMIN`
  Planning notes, contracts, schedules, approvals, and project administration.
- `02_SOURCE`
  Original source material, inputs, code, raw captures, or received assets.
- `03_WORKING`
  Drafts, work-in-progress files, intermediate analysis, and active development material.
- `04_OUTPUT`
  Deliverables, exports, presentations, published files, and handoff-ready outputs.
- `05_REFERENCE`
  Project-specific reference documents, requirements, manuals, and supporting research.
- `99_ARCHIVE`
  Historical iterations, retired material, superseded outputs, and no-longer-active project content.

## 6. Standard Filename Pattern

The approved filename pattern is:

`YYYY-MM-DD_Area_Item_Descriptor_v01.ext`

### 6.1 Approved Area Values

Approved `Area` values are:

- `Teaching`
- `InsightEdu`
- `Studio`
- `Systems`
- `Personal`

### 6.2 Naming Rules

- Use ISO date format: `YYYY-MM-DD`.
- Use hyphens inside multi-word segments.
- Do not use `final`, `latest`, `new`, or vague suffixes.
- Increment numeric versions explicitly, such as `v01`, `v02`, `v03`.
- Preserve meaningful, concise nouns in `Item` and `Descriptor`.
- Prefer stable business meaning over temporary workflow language.

### 6.3 Filename Examples by Area

- `2026-04-07_Teaching_Course-outline_Module-01_v01.docx`
- `2026-04-07_InsightEdu_Client-brief_Site-audit_v01.pdf`
- `2026-04-07_Studio_Podcast-episode_Rough-cut_v01.wav`
- `2026-04-07_Systems_Device-inventory_Target-machine_v01.xlsx`
- `2026-04-07_Personal_Insurance-policy_Renewal-summary_v01.pdf`

## 7. Tag Guidance

Tags are an overlay for visibility and workflow support. They do not replace the folder structure. Files should still live in the correct folder even when tags are used in task tools, note systems, filenames in supporting systems, or external indexes.

Approved tag guidance:

- `Now`
  Active attention required immediately.
- `Next`
  Ready for near-term action but not the current focus.
- `Waiting`
  Blocked pending a response, dependency, approval, or external event.
- `Archive`
  Retained for history or reference, not part of active work.
- `Critical`
  High-impact or time-sensitive material requiring heightened visibility.
- `Reference`
  Informational content intended to be consulted rather than actively edited.
- `Template`
  Reusable starting point intended for duplication or structured reuse.
- `Teaching`
  Content associated with the Teaching area.
- `InsightEdu`
  Content associated with the InsightEdu area.
- `Studio`
  Content associated with the Studio area.
- `Systems`
  Content associated with the Systems area.
- `Personal`
  Content associated with the Personal area.

## 8. Weekly Maintenance Checklist

Perform the following review at least weekly:

1. Empty or reduce `00_INBOX` by classifying and filing new material.
2. Confirm active projects under `10_PROJECTS` use the standard subfolder model.
3. Move superseded project files from active folders to `99_ARCHIVE` where appropriate.
4. Review rename proposals and normalize filenames for newly added material.
5. Check whether `25_PERSONAL` records have been filed to the correct subfolder.
6. Move durable manuals, guides, and knowledge resources into `40_REFERENCE`.
7. Move obsolete system exports, installers, and inventories into `50_SYSTEM` or `90_ARCHIVE` as appropriate.
8. Keep archival material out of active working folders.

## 9. Operating Notes

- Favor conservative classification over fast guessing.
- Use `00_INBOX` as a temporary intake location, not a permanent storage area.
- Use the project template consistently to reduce decision fatigue.
- Treat renaming and migration as reviewable operations with reports where possible.
