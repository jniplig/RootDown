# First Migration Batch

## Purpose

This document defines the first safe migration batch for the RootDown rollout based on the latest audit results.

The audit is now good enough to support guided manual migration. It is not yet suitable for blind automated moves.

## First Safe Migration Order

Move content in this order:

1. `50_SYSTEM`
2. `25_PERSONAL`
3. `30_MEDIA`
4. `10_PROJECTS`
5. Leave `00_INBOX` for later review

This order prioritizes content that is usually easier to identify confidently and less likely to depend on unresolved classification decisions.

## Recommended First Batch

Start with clearly named technical and app-support folders that the audit now classifies reliably into `50_SYSTEM`, then move obvious personal folders, then media, then clearly project-like material.

Do not try to clear the entire source tree in one pass. Migrate only folders and files that have an obvious destination and can be verified quickly.

## Example Destination Paths

Use paths like these under `the data root`:

- `PowerShell` -> `the data root\50_SYSTEM\PowerShell`
- `WindowsPowerShell` -> `the data root\50_SYSTEM\WindowsPowerShell`
- `Blackmagic Design` -> `the data root\50_SYSTEM\Blackmagic-Design`
- `ATEM Autosave` -> `the data root\50_SYSTEM\ATEM\Autosave`
- `WinBox_Windows` -> `the data root\50_SYSTEM\WinBox\Windows`
- Music files from `Downloads` -> `the data root\30_MEDIA\Audio`

Adjust the final destination slightly if the contents justify a more specific subfolder, but keep the top-level category consistent with the standard.

## Do Not Move Automatically Yet

Do not automate moves yet for:

- ambiguous zip files
- app-managed folders unless contents are verified
- items currently classified into `00_INBOX`

These still require a manual check because the risk of misclassification or breaking an application workflow is higher than the benefit of full automation.

## Folder Verification Checklist

Before moving any folder:

1. Confirm contents.
2. Confirm destination.
3. Avoid breaking app dependencies.
4. Prefer copy-then-verify for risky folders.

## Working Rule

If a folder is clearly identifiable and low-risk, migrate it manually into the correct `the data root` destination. If it is ambiguous, application-managed, compressed, or currently routed to `00_INBOX`, leave it for a later review batch.
