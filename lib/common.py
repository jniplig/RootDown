"""Shared utilities for RootDown deployer and auditor."""

import json
import platform
from pathlib import Path


def load_json(path: Path) -> dict:
    with open(path) as f:
        return json.load(f)


def resolve_data_root(profile: dict) -> Path:
    if profile.get("data_root"):
        return Path(profile["data_root"])
    if platform.system() == "Windows":
        return Path(r"C:\Data")
    return Path.home() / "Data"
