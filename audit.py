"""
RootDown auditor — non-destructive drift detection.

Compares a deployed folder structure against the canonical standard in
standard/organization-standard.json and reports missing folders, unexpected
folders, and naming deviations. Never moves, renames, or deletes anything.

Usage:
    python audit.py [--profile <name>] [--root <path>] [--report <path>]
"""
