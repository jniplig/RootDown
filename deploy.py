"""
RootDown deployer — creates the standard folder structure on any platform.

Usage:
    python deploy.py                          # dry run, default profile
    python deploy.py --profile profiles/profile-personal.json
    python deploy.py --no-dry-run             # live write, default profile
    python deploy.py --profile profiles/profile-personal.json --no-dry-run
"""

import argparse
from pathlib import Path

from lib.common import die, load_json, resolve_data_root, validate_data_root

STANDARD_PATH = Path(__file__).parent / "standard" / "organization-standard.json"
DEFAULT_PROFILE = Path(__file__).parent / "profiles" / "profile-template.json"


def apply_folder_additions(folders: list, additions: list) -> None:
    for addition in additions:
        _insert(folders, addition["parent"], addition)


def _insert(folders: list, parent_key: str, addition: dict) -> bool:
    for folder in folders:
        if folder["key"] == parent_key:
            folder.setdefault("subfolders", []).append({
                "key": addition["key"],
                "display_name": addition["display_name"],
                "purpose": addition["purpose"],
                "subfolders": [],
            })
            return True
        if _insert(folder.get("subfolders", []), parent_key, addition):
            return True
    return False


def sort_subfolders(folders: list) -> None:
    for folder in folders:
        if folder.get("subfolders"):
            folder["subfolders"].sort(key=lambda f: f["key"])
            sort_subfolders(folder["subfolders"])


def deploy(root: Path, folders: list, dry_run: bool) -> None:
    for folder in folders:
        path = root / folder["key"]
        if dry_run:
            print(f"[DRY RUN] {path}")
        elif path.exists():
            print(f"[EXISTS]  {path}")
        else:
            try:
                path.mkdir(parents=True, exist_ok=True)
            except PermissionError:
                die(f"permission denied creating folder: {path}")
            print(f"[CREATED] {path}")
        if folder.get("subfolders"):
            deploy(path, folder["subfolders"], dry_run)


def main() -> None:
    parser = argparse.ArgumentParser(description="RootDown deployer")
    parser.add_argument("--profile", type=Path, default=DEFAULT_PROFILE,
                        help="Path to a profile JSON (default: profile-template.json)")
    parser.add_argument("--dry-run", action=argparse.BooleanOptionalAction, default=True,
                        help="Preview without writing (default: on). Use --no-dry-run to write.")
    args = parser.parse_args()

    standard = load_json(STANDARD_PATH, "standard file")
    profile = load_json(args.profile, "profile")

    data_root = resolve_data_root(profile)
    validate_data_root(data_root)
    folders = standard["folders"]

    if profile.get("folder_additions"):
        apply_folder_additions(folders, profile["folder_additions"])

    sort_subfolders(folders)

    print(f"RootDown deployer — {'DRY RUN' if args.dry_run else 'LIVE'}")
    print(f"Data root : {data_root}")
    print(f"Profile   : {args.profile}")
    print()

    deploy(data_root, folders, args.dry_run)


if __name__ == "__main__":
    main()
