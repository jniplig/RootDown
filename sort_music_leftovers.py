from pathlib import Path
import shutil
import sys

# ── CONFIG ──────────────────────────────────────────────
SOURCE   = Path.home() / "Music"
PROD     = Path(r"C:\Data\30_MEDIA\20_PRODUCTION")
DJ       = Path(r"C:\Data\30_MEDIA\10_DJ")
VIDEO    = Path(r"C:\Data\30_MEDIA\30_VIDEO\32_FOOTAGE")
SYSTEM   = Path(r"C:\Data\50_SYSTEM")
DRY_RUN  = False
# ────────────────────────────────────────────────────────

ROUTE = {
    # Audio production
    ".mid":        PROD / "22_MIDI",
    ".midi":       PROD / "22_MIDI",
    ".rx2":        PROD / "21_SAMPLES",
    # VST presets
    ".fxp":        PROD / "23_PRESETS",
    ".h2p":        PROD / "23_PRESETS",
    ".spf":        PROD / "23_PRESETS",
    ".nmsv":       PROD / "23_PRESETS",
    ".opxpreset":  PROD / "23_PRESETS",
    ".dx7x":       PROD / "23_PRESETS",
    # Artwork
    ".jpg":        PROD / "25_ASSETS/artwork",
    ".jpeg":       PROD / "25_ASSETS/artwork",
    ".png":        PROD / "25_ASSETS/artwork",
    ".rgb":        PROD / "25_ASSETS/artwork",
    ".tiff":       PROD / "25_ASSETS/artwork",
    # Docs
    ".pdf":        PROD / "25_ASSETS/docs",
    ".epub":       PROD / "25_ASSETS/docs",
    ".md":         PROD / "25_ASSETS/docs",
    ".rtf":        PROD / "25_ASSETS/docs",
    ".txt":        PROD / "25_ASSETS/docs",
    # Archives
    ".zip":        PROD / "25_ASSETS/archives",
    # DJ stems
    ".stems":      DJ,
    # Video
    ".m4v":        VIDEO,
    ".mov":        VIDEO,
    # Scripts
    ".py":         SYSTEM,
}

JUNK = {
    ".ds_store", ".db", ".mse", ".tmp", ".log",
    ".sfv", ".itdb", ".dll", ".pyc", ".ps1", ".bat",
    ".bin", ".dat", ".xml", ".nib", ".rsrc", ".winmd",
    ".scn", ".led", ".ssfile", ".avgr", ".csv", ".yaml",
    ".json", ".xlsx", ".iso", ".vst3",
    ".ipa", ".exe", ".ini", ".npk", ".msi",
    ".m3u8", ".m3u", ".thorn",
    ".nfo", ".url", ".plist", ".db-journal", ".itl",
    ".cue", '.none',
}

def safe_dest(dest_dir: Path, filename: str) -> Path:
    target = dest_dir / filename
    if not target.exists():
        return target
    stem, suffix = Path(filename).stem, Path(filename).suffix
    counter = 1
    while True:
        candidate = dest_dir / f"{stem}_{counter}{suffix}"
        if not candidate.exists():
            return candidate
        counter += 1

def main():
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    counts = {"move": 0, "delete": 0, "skip": 0}
    skipped_exts = {}

    for f in SOURCE.rglob("*"):
        if not f.is_file():
            continue
        ext = f.suffix.lower()
        no_ext = ext == "" or ext == f.name.lower()

        if ext in JUNK or f.name.startswith("._") or no_ext:
            print(f"{'WOULD DELETE' if DRY_RUN else 'DELETE'}: {f.name}")
            counts["delete"] += 1
            if not DRY_RUN:
                f.unlink()

        elif ext in ROUTE:
            dest = safe_dest(ROUTE[ext], f.name)
            print(f"{'WOULD MOVE' if DRY_RUN else 'MOVE'}: {f.name} -> {dest.parent.name}")
            counts["move"] += 1
            if not DRY_RUN:
                dest.parent.mkdir(parents=True, exist_ok=True)
                shutil.move(str(f), str(dest))

        else:
            counts["skip"] += 1
            skipped_exts[ext] = skipped_exts.get(ext, 0) + 1

    print(f"\n{'[DRY RUN] ' if DRY_RUN else ''}Move: {counts['move']} | Delete: {counts['delete']} | Unhandled: {counts['skip']}")
    if skipped_exts:
        print("Unhandled extensions:")
        for ext, n in sorted(skipped_exts.items(), key=lambda x: -x[1]):
            print(f"  {ext or '(no ext)':20} {n}")

if __name__ == "__main__":
    main()