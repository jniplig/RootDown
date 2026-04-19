"""
RootDown deployer — single entry point for all platforms.

Reads the canonical folder standard from standard/organization-standard.json,
detects the current platform (Windows, macOS, Linux/WSL), applies any matching
profile from profiles/, and creates the folder structure at the configured root.

Usage:
    python deploy.py [--profile <name>] [--root <path>] [--dry-run]
"""
