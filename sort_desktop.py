from pathlib import Path
import shutil
import sys

# ── CONFIG ──────────────────────────────────────────────
DESKTOP  = Path.home() / "Desktop"
DATA     = Path(r"C:\Data")
DRY_RUN  = False
# ────────────────────────────────────────────────────────

MOVES = {
    # 50_SYSTEM
    "ASUS-K6-Reference-Audit":                  DATA / "50_SYSTEM",
    "asus-known-good-configuration.md":          DATA / "50_SYSTEM",
    "E_K6_MIGRATION_PLAN.md":                   DATA / "50_SYSTEM",
    "k6-reset-summary.md":                      DATA / "50_SYSTEM",
    "AUDIO_REINSTALL_PLAN.md":                  DATA / "50_SYSTEM",
    "chromaprint-fpcalc-1.6.0-windows-x86_64": DATA / "50_SYSTEM/tools",
    "yt-derpit.bat":                            DATA / "50_SYSTEM/scripts",
    # 30_MEDIA
    "120218-AmaliaFiredUp.m4v":                 DATA / "30_MEDIA/30_VIDEO/32_FOOTAGE",
    "120218-AmaliaFiredUp.mp4":                 DATA / "30_MEDIA/30_VIDEO/32_FOOTAGE",
    "I-AM-NOT-A-ROBOT-whatsapp.mp4":            DATA / "30_MEDIA/30_VIDEO/32_FOOTAGE",
    "DJ-ENGINE-History.csv":                    DATA / "30_MEDIA/10_DJ",
    "Set_1.txt":                                DATA / "30_MEDIA/10_DJ",
    # 40_REFERENCE
    "Resolume Manual.pdf":                      DATA / "40_REFERENCE",
    "lang-ab-initio-2018-en.pdf":               DATA / "40_REFERENCE",
    "sb_ab_initio_en.pdf":                      DATA / "40_REFERENCE",
    "Working scientifically- Bias (Student).pdf": DATA / "40_REFERENCE",
    # 25_PERSONAL
    "Kitchen Upgrade":                          DATA / "25_PERSONAL",
    "WhatsApp Chat - Agnese":                   DATA / "25_PERSONAL",
    "WhatsApp Chat - Agnese.zip":               DATA / "25_PERSONAL",
    "whatsapp-origin-conversation-2026-04-17.txt": DATA / "25_PERSONAL",
    "invoice.pdf":                              DATA / "25_PERSONAL/02_Finance",
    "invoice (1).pdf":                          DATA / "25_PERSONAL/02_Finance",
    "OD-05-26-18281-1115419993 - Invoice.pdf":  DATA / "25_PERSONAL/02_Finance",
    "WhatsApp Image 2026-03-27 at 1.22.06 PM.jpeg": DATA / "25_PERSONAL",
    "WhatsApp Image 2026-03-27 at 1.23.56 PM.jpeg": DATA / "25_PERSONAL",
    "WhatsApp Image 2026-05-08 at 5.37.25 PM.jpeg": DATA / "25_PERSONAL",
    "WhatsApp Image 2026-05-08 at 5.37.48 PM.jpeg": DATA / "25_PERSONAL",
    "WhatsApp Image 2026-05-08 at 5.38.03 PM.jpeg": DATA / "25_PERSONAL",
}

DELETE = [
    # Shortcuts
    "Chrome Remote Desktop-SuperDuperOllie.lnk",
    "Chrome Remote Desktop.lnk",
    "Docker Desktop.lnk",
    "Dropbox.lnk",
    "Elgato Studio.lnk",
    "Manus.lnk",
    "Native Access.lnk",
    "Profile 1 - Edge.lnk",
    "Signal.lnk",
    "Spotify.lnk",
    "SumatraPDF.lnk",
    "Zoom Workplace.lnk",
    "Shortcut to Desktop (OneDrive - Personal).lnk",
    # Logs + temp
    "WindowsUpdate.log",
    "battery-report.html",
    "Removed Apps.html",
    "Screenshot 2026-04-17 150945.png",
    "ASUS-Audit-to-Share.log",
    "FullName.txt",
    "others.txt",
    # Unknowns cleared for deletion
    "43092639_1.pdf",
    "0409_E15995_GX550LXS_LWS_B (1).pdf",
    "5336429.jpg",
]

def main():
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

    for name, dest in MOVES.items():
        src = DESKTOP / name
        if not src.exists():
            print(f"SKIP (not found): {name}")
            continue
        target = dest / name
        print(f"{'WOULD MOVE' if DRY_RUN else 'MOVE'}: {name} -> {dest.relative_to(DATA)}")
        if not DRY_RUN:
            dest.mkdir(parents=True, exist_ok=True)
            shutil.move(str(src), str(target))

    for name in DELETE:
        src = DESKTOP / name
        if not src.exists():
            print(f"SKIP (not found): {name}")
            continue
        print(f"{'WOULD DELETE' if DRY_RUN else 'DELETE'}: {name}")
        if not DRY_RUN:
            if src.is_dir():
                shutil.rmtree(str(src))
            else:
                src.unlink()

if __name__ == "__main__":
    main()