"""
RootDown auditor — non-destructive drift detection and governance reporting.

Compares the deployed folder structure on disk against the canonical standard
and active profile. Never moves, renames, or deletes anything.

Usage:
    python audit.py                                        # summary only
    python audit.py --profile profiles/profile-personal.json
    python audit.py --verbose                              # print all findings
    python audit.py --report audit.csv                     # write CSV report
    python audit.py --profile profiles/profile-personal.json --report audit.csv --verbose
"""

import argparse
import csv
import datetime
from pathlib import Path

from lib.common import load_json, resolve_data_root, validate_data_root

STANDARD_PATH = Path(__file__).parent / "standard" / "organization-standard.json"
DEFAULT_PROFILE = Path(__file__).parent / "profiles" / "profile-template.json"


def collect_standard_paths(root: Path, folders: list, known: set) -> None:
    """Recursively populate known with all expected absolute paths."""
    for folder in folders:
        path = root / folder["key"]
        known.add(path)
        if folder.get("subfolders"):
            collect_standard_paths(path, folder["subfolders"], known)


def apply_folder_additions(folders: list, additions: list) -> None:
    for addition in additions:
        _insert(folders, addition["parent"], addition)


def _insert(folders: list, parent_key: str, addition: dict) -> bool:
    for folder in folders:
        if folder["key"] == parent_key:
            folder.setdefault("subfolders", []).append({
                "key": addition["key"],
                "display_name": addition.get("display_name", addition["key"]),
                "purpose": addition.get("purpose", ""),
                "subfolders": [],
            })
            return True
        if _insert(folder.get("subfolders", []), parent_key, addition):
            return True
    return False


def build_symlink_map(data_root: Path, profile: dict) -> dict:
    """Map absolute path -> declared target for profile-declared symlinks."""
    result = {}
    for entry in profile.get("symlinked_folders", []):
        path = data_root / entry["key"]
        result[path] = entry.get("target")
    return result


def symlink_detail(path: Path, declared_target: str | None) -> str:
    if path.is_symlink():
        target = path.resolve()
        return f"symlink -> {target}" if path.exists() else f"symlink -> {target} (broken)"
    if declared_target:
        return f"symlink -> {declared_target} (broken)"
    return "symlink (broken, target unknown)"


def get_inbox_max_age(folders: list, inbox_key: str = "00_INBOX") -> int | None:
    for folder in folders:
        if folder["key"] == inbox_key:
            return folder.get("lifecycle", {}).get("review_after_days")
    return None


def check_inbox_age(inbox_path: Path, max_age_days: int, findings: list) -> None:
    if not inbox_path.exists():
        return
    cutoff = datetime.datetime.now() - datetime.timedelta(days=max_age_days)
    for item in inbox_path.rglob("*"):
        if item.is_file():
            mtime = datetime.datetime.fromtimestamp(item.stat().st_mtime)
            if mtime < cutoff:
                age = (datetime.datetime.now() - mtime).days
                findings.append((item, "INBOX_AGE", f"age {age}d exceeds {max_age_days}d policy"))


def audit(data_root: Path, folders: list, standard: dict, symlink_map: dict) -> list:
    """Return list of (path, classification, detail) tuples."""
    findings = []
    known = set()
    collect_standard_paths(data_root, folders, known)

    # Check standard folders — classify symlinks before missing/ok
    for path in sorted(known):
        if path in symlink_map or path.is_symlink():
            findings.append((path, "SYMLINK", symlink_detail(path, symlink_map.get(path))))
        elif path.exists():
            findings.append((path, "OK", ""))
        else:
            findings.append((path, "MISSING", "required folder not found on disk"))

    # Check for UNKNOWN folders on disk (drift)
    if data_root.exists():
        for item in sorted(data_root.rglob("*")):
            if item.is_dir() and item not in known:
                findings.append((item, "UNKNOWN", "not in standard or profile"))

    # Check INBOX_AGE
    max_age = get_inbox_max_age(standard["folders"])
    if max_age is not None:
        check_inbox_age(data_root / "00_INBOX", max_age, findings)

    return findings


def write_report(path: Path, findings: list) -> None:
    with open(path, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["path", "classification", "detail"])
        for folder_path, classification, detail in findings:
            writer.writerow([folder_path, classification, detail])


def main() -> None:
    parser = argparse.ArgumentParser(description="RootDown auditor")
    parser.add_argument("--profile", type=Path, default=DEFAULT_PROFILE,
                        help="Path to a profile JSON (default: profile-template.json)")
    parser.add_argument("--report", type=Path, default=None,
                        help="Optional path to write a CSV report")
    parser.add_argument("--verbose", action="store_true",
                        help="Print all findings to console")
    args = parser.parse_args()

    standard = load_json(STANDARD_PATH, "standard file")
    profile = load_json(args.profile, "profile")

    data_root = resolve_data_root(profile)
    validate_data_root(data_root)
    folders = standard["folders"]

    if profile.get("folder_additions"):
        apply_folder_additions(folders, profile["folder_additions"])

    print(f"RootDown auditor")
    print(f"Data root : {data_root}")
    print(f"Profile   : {args.profile}")
    print()

    symlink_map = build_symlink_map(data_root, profile)
    findings = audit(data_root, folders, standard, symlink_map)

    counts = {}
    for _, classification, _ in findings:
        counts[classification] = counts.get(classification, 0) + 1

    if args.verbose:
        for path, classification, detail in findings:
            line = f"[{classification}] {path}"
            if detail:
                line += f"  — {detail}"
            print(line)
        print()

    total = len(findings)
    print(f"Folders checked : {total}")
    for label in ("OK", "SYMLINK", "MISSING", "UNKNOWN", "INBOX_AGE"):
        if label in counts:
            print(f"  {label:<12}: {counts[label]}")

    if args.report:
        write_report(args.report, findings)
        print(f"\nReport written : {args.report}")


if __name__ == "__main__":
    main()
