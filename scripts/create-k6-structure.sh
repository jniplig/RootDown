#!/usr/bin/env bash
#
# Usage:
#   ./scripts/create-k6-structure.sh
#
# Example:
#   ./scripts/create-k6-structure.sh
#
# This helper is intentionally safe for WSL and Linux testing. It does not
# attempt to create C:\Data directly. Instead, it builds a mock tree under:
#   ./mock/C/Data
# and prints the intended Windows target tree for reference.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
MOCK_ROOT="${REPO_ROOT}/mock/C/Data"
WINDOWS_ROOT='C:\Data'

TOP_LEVEL_FOLDERS=(
  "00_INBOX"
  "10_PROJECTS"
  "20_OPERATIONS"
  "25_PERSONAL"
  "30_MEDIA"
  "40_REFERENCE"
  "50_SYSTEM"
  "90_ARCHIVE"
)

PERSONAL_SUBFOLDERS=(
  "01_Family"
  "02_Finance"
  "03_Property"
  "04_Travel"
  "05_Health_Admin"
  "06_Legal_and_ID"
  "07_Personal_Admin"
  "08_Warranties_and_Receipts"
  "09_Personal_Projects"
  "99_Archive"
)

# Keep output formatting centralized so repeated runs stay easy to compare.
log() {
  printf '%s\n' "$1"
}

# Idempotent directory creation helper. It never deletes or replaces content.
create_dir_if_missing() {
  local target="$1"

  if [[ -d "$target" ]]; then
    log "[exists ] $target"
  else
    mkdir -p "$target"
    log "[created] $target"
  fi
}

# Print the intended Windows layout so WSL users can verify the design without
# writing to the real Windows root.
print_target_tree() {
  log "Intended Windows target tree:"
  log "  ${WINDOWS_ROOT}"

  local folder
  for folder in "${TOP_LEVEL_FOLDERS[@]}"; do
    log "  ${WINDOWS_ROOT}\\${folder}"
  done

  for folder in "${PERSONAL_SUBFOLDERS[@]}"; do
    log "  ${WINDOWS_ROOT}\\25_PERSONAL\\${folder}"
  done
}

main() {
  log "Repository root: ${REPO_ROOT}"
  log "Mock root: ${MOCK_ROOT}"
  log ""

  print_target_tree
  log ""
  log "Creating mock tree under ./mock/C/Data ..."

  # Build the mock root first, then expand the approved standard tree under it.
  create_dir_if_missing "${MOCK_ROOT}"

  local folder
  for folder in "${TOP_LEVEL_FOLDERS[@]}"; do
    create_dir_if_missing "${MOCK_ROOT}/${folder}"
  done

  # Personal records have an explicit approved sub-structure in the standard.
  for folder in "${PERSONAL_SUBFOLDERS[@]}"; do
    create_dir_if_missing "${MOCK_ROOT}/25_PERSONAL/${folder}"
  done

  log ""
  log "Mock tree creation complete."
  log "No files or folders were deleted."
}

main "$@"
