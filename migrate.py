"""
RootDown migrator — stage 1 scan + stage 2 interactive triage.

Stage 1: scan a source root, classify risk, suggest destinations.
Stage 2: interactive triage — decide move / skip / protect / defer per item.
         Decisions are written to triage-log.json for the stage 3 apply pass.

Usage:
    python migrate.py                                 # scan + triage
    python migrate.py --scan-root /home/user
    python migrate.py --dry-run                       # show UI, no writes
    python migrate.py --no-triage --report out.csv    # scan only
    python migrate.py --triage-log custom-log.json
"""

import argparse
import csv
import datetime
import json
import re
from collections import defaultdict
from pathlib import Path

from lib.classifier import classify_risk, suggest_destination
from lib.common import die, load_json, resolve_data_root, validate_data_root

STANDARD_PATH   = Path(__file__).parent / "standard" / "organization-standard.json"
PROTECTED_PATH  = Path(__file__).parent / "standard" / "protected-paths.json"
DEFAULT_PROFILE = Path(__file__).parent / "profiles" / "profile-template.json"
DEFAULT_TRIAGE  = Path(__file__).parent / "triage-log.json"

DIVIDER = "─" * 52


# ── Size / time utilities ───────────────────────────────────────────────────

def get_size(path: Path) -> int:
    try:
        if path.is_file() or path.is_symlink():
            return path.stat().st_size
        total, count = 0, 0
        for f in path.rglob("*"):
            if count >= 10_000:
                break
            try:
                if f.is_file():
                    total += f.stat().st_size
                    count += 1
            except OSError:
                pass
        return total
    except OSError:
        return 0


def format_size(n: int) -> str:
    for unit in ("B", "KB", "MB", "GB", "TB"):
        if n < 1024:
            return f"{n:.1f} {unit}"
        n /= 1024
    return f"{n:.1f} PB"


def format_mtime(path: Path) -> str:
    try:
        return datetime.datetime.fromtimestamp(
            path.stat().st_mtime).strftime("%Y-%m-%d")
    except OSError:
        return "unknown"


def shorten(path: Path) -> str:
    try:
        return "~/" + str(path.relative_to(Path.home()))
    except ValueError:
        return str(path)


# ── Session management ──────────────────────────────────────────────────────

def now_iso() -> str:
    return datetime.datetime.now().isoformat(timespec="seconds")


def init_session(scan_root: Path) -> dict:
    return {
        "session_started": now_iso(),
        "session_updated": now_iso(),
        "scan_root": str(scan_root),
        "items": {},
    }


def load_or_create_session(triage_log: Path, scan_root: Path) -> dict:
    if triage_log.exists():
        try:
            with open(triage_log) as f:
                session = json.load(f)
            print(f"[INFO]  Resuming session: {triage_log}")
            return session
        except (json.JSONDecodeError, KeyError):
            print("[INFO]  Triage log unreadable — starting fresh")
    return init_session(scan_root)


def save_session(session: dict, path: Path, dry_run: bool) -> None:
    if dry_run:
        return
    session["session_updated"] = now_iso()
    with open(path, "w") as f:
        json.dump(session, f, indent=2)


def merge_scan(session: dict, scan_results: list) -> None:
    existing = session.setdefault("items", {})
    for path, tier, risk_reason, suggested, conf, suggestion_reason in scan_results:
        key = str(path)
        if key not in existing:
            existing[key] = {
                "tier":              tier,
                "risk_reason":       risk_reason,
                "suggested":         suggested,
                "confidence":        conf,
                "suggestion_reason": suggestion_reason,
                "decision":          None,
                "decision_reason":   None,
                "timestamp":         None,
            }


def record(session: dict, path: Path, decision: str,
           reason: str, triage_log: Path, dry_run: bool) -> None:
    entry = session["items"].get(str(path))
    if entry:
        entry["decision"]        = decision
        entry["decision_reason"] = reason
        entry["timestamp"]       = now_iso()
    save_session(session, triage_log, dry_run)


def is_decided(entry: dict) -> bool:
    return entry.get("decision") in ("move", "skip", "protect")


def tally(session: dict) -> dict:
    counts = {"move": 0, "skip": 0, "protect": 0, "defer": 0, "undecided": 0}
    for e in session["items"].values():
        d = e.get("decision")
        counts[d if d in counts else "undecided"] += 1
    return counts


# ── Display ─────────────────────────────────────────────────────────────────

def print_divider() -> None:
    print(DIVIDER)


def print_tally(session: dict) -> None:
    t = tally(session)
    decided   = sum(t[k] for k in ("move", "skip", "protect", "defer"))
    remaining = t["undecided"] + t["defer"]
    print(
        f"[  Decided: {decided}  |  Remaining: {remaining}  |"
        f"  Move: {t['move']}  Skip: {t['skip']}"
        f"  Protect: {t['protect']}  Defer: {t['defer']}  ]"
    )


def display_item(path: Path, entry: dict) -> None:
    tier         = entry["tier"]
    risk_reason  = entry.get("risk_reason") or "—"
    suggested    = entry["suggested"]
    confidence   = entry["confidence"]
    tier_label   = tier.replace("_", " ")
    action_hint  = "PROTECT" if tier == "HIGH_RISK" else suggested

    print_divider()
    print(f"[{tier_label}] {shorten(path)}")
    print(f"  Reason    : {risk_reason}")
    print(f"  Size      : {format_size(get_size(path))}")
    print(f"  Modified  : {format_mtime(path)}")
    print(f"  Suggested : {action_hint}  (confidence: {confidence})")
    print()


def display_safe_batch(destination: str, paths: list) -> None:
    total = sum(get_size(Path(p)) for p in paths)
    exts  = sorted({Path(p).suffix.lower() for p in paths if Path(p).suffix})
    ext_str    = " ".join(exts[:8]) + (" …" if len(exts) > 8 else "")
    parents    = sorted({shorten(Path(p).parent) for p in paths})
    parent_str = ", ".join(parents[:3]) + (" …" if len(parents) > 3 else "")

    print_divider()
    print(f"SAFE items → {destination}  ({len(paths)} items, {format_size(total)})")
    if ext_str:
        print(f"  Types   : {ext_str}")
    print(f"  From    : {parent_str}")
    print()


def display_caution_batch_offer(parent: Path, count: int) -> None:
    print_divider()
    print(f"[INFO]  {count} CAUTION items share parent: {shorten(parent)}")
    print()


# ── Input ───────────────────────────────────────────────────────────────────

def prompt(options: str) -> str:
    """Display options string and read one of the (x) chars. Returns 'q' on EOF."""
    valid = set(re.findall(r'\((\w)\)', options))
    while True:
        try:
            raw = input(f"  {options} : ").strip().lower()
        except (EOFError, KeyboardInterrupt):
            print()
            return "q"
        if raw and raw[0] in valid:
            return raw[0]


# ── Protected paths append ──────────────────────────────────────────────────

def append_protected(path: Path, dry_run: bool) -> None:
    if dry_run:
        return
    protected = load_json(PROTECTED_PATH, "protected-paths file")
    pattern = f"**/{path.name}/**" if path.is_dir() else f"**/{path.name}"
    protected["protected_paths"].append({
        "path_pattern": pattern,
        "reason":       "User-protected during triage",
        "auto_protect": False,
    })
    with open(PROTECTED_PATH, "w") as f:
        json.dump(protected, f, indent=2)


# ── Triage loop ─────────────────────────────────────────────────────────────

DECISION_MAP = {"m": "move", "s": "skip", "p": "protect", "d": "defer"}


def triage_one(path_str: str, session: dict,
               triage_log: Path, dry_run: bool) -> str:
    path  = Path(path_str)
    entry = session["items"][path_str]
    display_item(path, entry)
    choice = prompt("(m)ove  (s)kip  (p)rotect  (d)efer  (q)uit")
    if choice == "q":
        return "q"
    decision = DECISION_MAP[choice]
    if decision == "protect":
        append_protected(path, dry_run)
    record(session, path, decision, "", triage_log, dry_run)
    print_tally(session)
    print()
    return decision


def triage_batch(paths: list, decision_label: str, session: dict,
                 triage_log: Path, dry_run: bool, reason: str = "") -> None:
    for p in paths:
        record(session, Path(p), decision_label, reason, triage_log, dry_run)
    print_tally(session)
    print()


def run_triage(session: dict, triage_log: Path, dry_run: bool) -> None:
    items = session["items"]

    def undecided_tier(tier: str) -> list:
        return [k for k, v in items.items()
                if v["tier"] == tier and not is_decided(v)
                and v.get("decision") != "defer"]

    def undecided_or_defer(tier: str) -> list:
        return [k for k, v in items.items()
                if v["tier"] == tier and not is_decided(v)]

    # ── HIGH_RISK — one by one ──────────────────────────────────────────────
    for p in undecided_or_defer("HIGH_RISK"):
        if triage_one(p, session, triage_log, dry_run) == "q":
            return

    # ── CAUTION — one by one, offer same-parent batch ───────────────────────
    processed: set = set()
    caution = undecided_or_defer("CAUTION")

    for p in caution:
        if p in processed or is_decided(items[p]):
            continue

        parent = Path(p).parent
        same_parent = [x for x in caution
                       if Path(x).parent == parent
                       and x not in processed
                       and not is_decided(items[x])]

        if len(same_parent) > 1:
            display_caution_batch_offer(parent, len(same_parent))
            choice = prompt("(b)atch  (i)ndividual  (q)uit")
            if choice == "q":
                return
            if choice == "b":
                display_safe_batch(items[p]["suggested"], same_parent)
                choice2 = prompt("(m)ove all  (s)kip all  (p)rotect all  (d)efer all  (q)uit")
                if choice2 == "q":
                    return
                if choice2 == "p":
                    for x in same_parent:
                        append_protected(Path(x), dry_run)
                decision = DECISION_MAP.get(choice2, "defer")
                triage_batch(same_parent, decision, session, triage_log,
                             dry_run, "batched from same folder")
                processed.update(same_parent)
                continue

        if triage_one(p, session, triage_log, dry_run) == "q":
            return
        processed.add(p)

    # ── SAFE — grouped by suggested destination ─────────────────────────────
    by_dest: dict = defaultdict(list)
    for p in undecided_or_defer("SAFE"):
        by_dest[items[p]["suggested"]].append(p)

    for dest, group in sorted(by_dest.items()):
        display_safe_batch(dest, group)
        choice = prompt("(m)ove all  (r)eview individually  (s)kip all  (d)efer all  (q)uit")
        if choice == "q":
            return
        if choice == "r":
            for p in group:
                if triage_one(p, session, triage_log, dry_run) == "q":
                    return
        else:
            triage_batch(group, DECISION_MAP.get(choice, "defer"),
                         session, triage_log, dry_run, "safe batch decision")


def print_summary(session: dict) -> None:
    t = tally(session)
    total = sum(t.values())
    print()
    print("=" * 52)
    print("Session Summary")
    print("=" * 52)
    print(f"  Total items   : {total}")
    print(f"  Move          : {t['move']}")
    print(f"  Skip          : {t['skip']}")
    print(f"  Protect       : {t['protect']}")
    print(f"  Defer         : {t['defer']}")
    print(f"  Undecided     : {t['undecided']}")
    if t["defer"] + t["undecided"] > 0:
        print()
        print("[INFO]  Deferred/undecided items will be re-presented next session.")
    print("[INFO]  Review triage-log.json before running --apply.")
    print()


# ── Scan helpers (unchanged from stage 1) ───────────────────────────────────

def collect_standard_roots(data_root: Path, folders: list) -> set[Path]:
    return {data_root / f["key"] for f in folders}


def scan(scan_root: Path, skip: set[Path]) -> list[Path]:
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
    return f"[{tier:<9}] {item}  →  {suggested}  ({confidence})"


# ── Main ─────────────────────────────────────────────────────────────────────

def main() -> None:
    parser = argparse.ArgumentParser(description="RootDown migrator")
    parser.add_argument("--profile",    type=Path, default=DEFAULT_PROFILE)
    parser.add_argument("--scan-root",  type=Path, default=Path.home(),
                        help="Directory to scan (default: home)")
    parser.add_argument("--triage-log", type=Path, default=DEFAULT_TRIAGE,
                        help="Triage session file (default: triage-log.json)")
    parser.add_argument("--report",     type=Path, default=None,
                        help="Optional CSV report path")
    parser.add_argument("--no-triage",  action="store_true",
                        help="Scan and classify only — skip interactive triage")
    parser.add_argument("--dry-run",    action="store_true",
                        help="Show triage UI but do not write any state")
    args = parser.parse_args()

    standard  = load_json(STANDARD_PATH,  "standard file")
    protected = load_json(PROTECTED_PATH, "protected-paths file")
    profile   = load_json(args.profile,   "profile")

    data_root      = resolve_data_root(profile)
    validate_data_root(data_root)
    protected_list = protected["protected_paths"]
    folders        = standard["folders"]
    skip           = collect_standard_roots(data_root, folders)
    skip.add(data_root)

    if not args.scan_root.exists():
        die(f"scan root does not exist: {args.scan_root}")

    mode = " [DRY RUN]" if args.dry_run else ""
    print(f"RootDown migrator{mode}")
    print(f"Scan root : {args.scan_root}")
    print(f"Data root : {data_root}")
    print()

    raw_items = scan(args.scan_root, skip)

    scan_results = []
    for item in raw_items:
        tier, risk_reason       = classify_risk(item, protected_list)
        suggested, conf, reason = suggest_destination(item, standard)
        print(format_line(item, tier, suggested, conf))
        scan_results.append((item, tier, risk_reason, suggested, conf, reason))

    counts: dict = {}
    for _, tier, *_ in scan_results:
        counts[tier] = counts.get(tier, 0) + 1

    print()
    print(f"Items scanned : {len(scan_results)}")
    for t in ("HIGH_RISK", "CAUTION", "SAFE"):
        if t in counts:
            print(f"  {t:<10}: {counts[t]}")

    if args.no_triage:
        if args.report:
            with open(args.report, "w", newline="") as f:
                writer = csv.DictWriter(f, fieldnames=[
                    "path", "tier", "reason", "suggested",
                    "confidence", "suggestion_reason", "decision",
                ])
                writer.writeheader()
                for item, tier, risk_reason, suggested, conf, reason in scan_results:
                    writer.writerow({
                        "path": str(item), "tier": tier, "reason": risk_reason,
                        "suggested": suggested, "confidence": conf,
                        "suggestion_reason": reason, "decision": "",
                    })
            print(f"\nReport written : {args.report}")
        return

    print()
    session = load_or_create_session(args.triage_log, args.scan_root)
    merge_scan(session, scan_results)
    save_session(session, args.triage_log, args.dry_run)

    t = tally(session)
    remaining = t["undecided"] + t["defer"]
    print(f"Items in session : {len(session['items'])}")
    print_tally(session)

    if remaining == 0:
        print("\n[INFO]  All items already decided.")
        print_summary(session)
        return

    print()
    print("Starting triage. Press (q) at any time to save and quit.")
    print()

    run_triage(session, args.triage_log, args.dry_run)
    print_summary(session)

    if args.report:
        with open(args.report, "w", newline="") as f:
            writer = csv.DictWriter(f, fieldnames=[
                "path", "tier", "decision", "suggested", "confidence", "timestamp",
            ])
            writer.writeheader()
            for path_str, entry in session["items"].items():
                writer.writerow({
                    "path":       path_str,
                    "tier":       entry["tier"],
                    "decision":   entry.get("decision") or "",
                    "suggested":  entry["suggested"],
                    "confidence": entry["confidence"],
                    "timestamp":  entry.get("timestamp") or "",
                })
        print(f"Report written : {args.report}")


if __name__ == "__main__":
    main()
