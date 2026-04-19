"""Shared utilities for RootDown deployer and auditor."""

import json
import platform
import sys
from pathlib import Path


def die(message: str) -> None:
    print(f"[ERROR] {message}", file=sys.stderr)
    sys.exit(1)


def load_json(path: Path, label: str) -> dict:
    try:
        with open(path) as f:
            return json.load(f)
    except FileNotFoundError:
        die(f"{label} not found: {path}")
    except json.JSONDecodeError as e:
        die(f"{label} is not valid JSON: {path}\n        {e}")


def validate_data_root(path: Path) -> None:
    if path.exists() and not path.is_dir():
        die(f"data root path exists but is a file, not a directory: {path}")


def resolve_data_root(profile: dict) -> Path:
    if profile.get("data_root"):
        return Path(profile["data_root"])
    if platform.system() == "Windows":
        return Path(r"C:\Data")
    return Path.home() / "Data"
