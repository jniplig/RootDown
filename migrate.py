"""
RootDown migrator — stage 1: scan and classify only.

Scans a source root for items outside the RootDown standard, assesses
migration risk, and suggests a destination folder. Writes a CSV report
with a blank decision column for use in the interactive stage 2 pass.

Usage:
    python migrate.py
    python migrate.py --scan-root /home/user
    python migrate.py --profile profiles/profile-personal.json
    python migrate.py --scan-root /home/user --report migrate.csv
"""

import argparse
import csv
from pathlib import Path

from lib.classifier import classify_risk, suggest_destination
from lib.common import die, load_json, resolve_data_root, validate_data_root

STANDARD_PATH    = Path(__file__).parent / "standard" / "organization-standard.json"
PROTECTED_PATH   = Path(__file__).parent / "standard" / "protected-paths.json"
DEFAULT_PROFILE  = Path(__file__).parent / "profiles" / "profile-template.json"

TIER_ORDER = {'HIGH_RISK': 0, 'CAUTION': 1, 'SAFE': 2}


def collect_standard_roots(data_root: Path, folders: list) -> set[Path]:
    """Return the set of top-level standard folder paths to skip during scan."""
    return {data_root / f['key'] for f in folders}


def scan(scan_root: Path, skip: set[Path]) -> list[Path]:
    """Yield top-level items under scan_root that are not in skip."""
    items = []
    try:
        for item in sorted(scan_root.iterdir()):
            if item in skip or any(item == s or item.is_relative_to(s) for s in skip):
                continue
            items.append(item)
    except PermissionError:
        die(f"permission denied reading scan root: {scan_root}")
    return items


def format_line(item: Path, tier: str, suggested: str, confidence: str) -> str:
    arrow = '\u2192'
    return f"[{tier:<9}] {item}  {arrow}  {suggested}  ({confidence})"


def main() -> None:
    parser = argparse.ArgumentParser(description="RootDown migrator — stage 1")
    parser.add_argument("--profile", type=Path, default=DEFAULT_PROFILE,
                        help="Path to a profile JSON")
    parser.add_argument("--scan-root", type=Path, default=Path.home(),
                        help="Directory to scan (default: home directory)")
    parser.add_argument("--report", type=Path, default=None,
                        help="Optional path to write a CSV report")
    args = parser.parse_args()

    standard  = load_json(STANDARD_PATH, "standard file")
    protected = load_json(PROTECTED_PATH, "protected-paths file")
    profile   = load_json(args.profile,   "profile")

    data_root = resolve_data_root(profile)
    validate_data_root(data_root)

    protected_list = protected["protected_paths"]
    folders        = standard["folders"]
    skip           = collect_standard_roots(data_root, folders)
    skip.add(data_root)

    if not args.scan_root.exists():
        die(f"scan root does not exist: {args.scan_root}")

    print(f"RootDown migrator — stage 1 (scan only)")
    print(f"Scan root : {args.scan_root}")
    print(f"Data root : {data_root}")
    print(f"Profile   : {args.profile}")
    print()

    items = scan(args.scan_root, skip)

    rows = []
    for item in items:
        tier, risk_reason       = classify_risk(item, protected_list)
        suggested, conf, reason = suggest_destination(item, standard)
        print(format_line(item, tier, suggested, conf))
        rows.append({
            "path":             str(item),
            "tier":             tier,
            "reason":           risk_reason,
            "suggested":        suggested,
            "confidence":       conf,
            "suggestion_reason": reason,
            "decision":         "",
        })

    print()
    print(f"Items scanned : {len(rows)}")
    for tier in ('HIGH_RISK', 'CAUTION', 'SAFE'):
        count = sum(1 for r in rows if r['tier'] == tier)
        if count:
            print(f"  {tier:<10}: {count}")

    if args.report:
        with open(args.report, "w", newline="") as f:
            writer = csv.DictWriter(f, fieldnames=[
                "path", "tier", "reason", "suggested",
                "confidence", "suggestion_reason", "decision",
            ])
            writer.writeheader()
            writer.writerows(rows)
        print(f"\nReport written : {args.report}")


if __name__ == "__main__":
    main()
