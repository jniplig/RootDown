import shutil
from pathlib import Path

# ── CONFIG ──────────────────────────────────────────────
BASE    = Path(r"C:\Data\30_MEDIA")
DRY_RUN = False  # ← set False when ready
# ────────────────────────────────────────────────────────

MOVES = [
    # (source,                          destination)
    ("00_FLAT",          "10_DJ"),
    ("HUMBLE BUNDLE AUDIO", "20_PRODUCTION/21_SAMPLES/Humble-Bundle"),
    ("Loopcloud",        "20_PRODUCTION/21_SAMPLES/Loopcloud"),
    ("RESOLUME CLIPS",   "30_VIDEO/31_VJ_CLIPS"),
    ("OSMO",             "30_VIDEO/32_FOOTAGE/OSMO"),
    ("Video Archive",    "30_VIDEO/32_FOOTAGE/Video-Archive"),
    ("MIXPRE BACKUP",    "40_FIELD_REC"),
    ("111025-BOAT",      "90_ARCHIVE/111025-BOAT"),
    ("media",            "_handbrake-watch"),
]

CREATE_EMPTY = [
    "00_INBOX",
    "20_PRODUCTION/22_MIDI",
    "20_PRODUCTION/23_PRESETS",
    "20_PRODUCTION/24_PROJECTS",
    "20_PRODUCTION/25_ASSETS",
]

def main():
    print(f"DRY_RUN={DRY_RUN}\n")

    for src_rel, dst_rel in MOVES:
        src = BASE / src_rel
        dst = BASE / dst_rel
        if not src.exists():
            print(f"SKIP (not found) : {src_rel}")
            continue
        print(f"{'WOULD MOVE' if DRY_RUN else 'MOVING'}: {src_rel} → {dst_rel}")
        if not DRY_RUN:
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.move(str(src), str(dst))

    for folder_rel in CREATE_EMPTY:
        folder = BASE / folder_rel
        print(f"{'WOULD CREATE' if DRY_RUN else 'CREATING'}: {folder_rel}")
        if not DRY_RUN:
            folder.mkdir(parents=True, exist_ok=True)

if __name__ == "__main__":
    main()