"""RootDown classifier — risk assessment and destination suggestion engine."""

import fnmatch
from pathlib import Path

HIGH_RISK_KEYWORDS = {
    'Cache', 'AppData', 'Database', 'Registry', '.config',
    'Roaming', 'Local', 'Temp', 'temp', '.git', 'node_modules',
    '__pycache__', '.venv', 'site-packages',
}

EXT_DESTINATIONS = {
    '.jpg': '30_MEDIA', '.jpeg': '30_MEDIA', '.png': '30_MEDIA',
    '.gif': '30_MEDIA', '.raw': '30_MEDIA', '.cr2': '30_MEDIA', '.nef': '30_MEDIA',
    '.mp4': '30_MEDIA', '.mov': '30_MEDIA', '.avi': '30_MEDIA',
    '.mkv': '30_MEDIA', '.m4v': '30_MEDIA',
    '.mp3': '30_MEDIA', '.flac': '30_MEDIA', '.wav': '30_MEDIA',
    '.aiff': '30_MEDIA', '.m4a': '30_MEDIA',
    '.pdf': '40_REFERENCE', '.doc': '40_REFERENCE', '.docx': '40_REFERENCE',
    '.txt': '40_REFERENCE', '.md': '40_REFERENCE',
    '.xls': '20_OPERATIONS', '.xlsx': '20_OPERATIONS', '.csv': '20_OPERATIONS',
    '.ps1': '50_SYSTEM', '.sh': '50_SYSTEM', '.py': '50_SYSTEM',
    '.js': '50_SYSTEM', '.ts': '50_SYSTEM',
    '.zip': '90_ARCHIVE', '.tar': '90_ARCHIVE', '.gz': '90_ARCHIVE', '.7z': '90_ARCHIVE',
    '.exe': '50_SYSTEM', '.msi': '50_SYSTEM', '.dmg': '50_SYSTEM', '.pkg': '50_SYSTEM',
}

PARENT_DESTINATIONS = {
    'downloads': '00_INBOX', 'desktop': '00_INBOX', 'inbox': '00_INBOX',
    'documents': '40_REFERENCE', 'docs': '40_REFERENCE',
    'pictures': '30_MEDIA', 'photos': '30_MEDIA', 'camera': '30_MEDIA',
    'music': '30_MEDIA', 'audio': '30_MEDIA',
    'videos': '30_MEDIA', 'movies': '30_MEDIA',
    'work': '10_PROJECTS', 'projects': '10_PROJECTS', 'dev': '10_PROJECTS',
    'finance': '25_PERSONAL/02_Finance', 'tax': '25_PERSONAL/02_Finance',
    'invoice': '25_PERSONAL/02_Finance',
    'personal': '25_PERSONAL',
}

FILENAME_PATTERNS = [
    ({'invoice', 'receipt', 'tax'},     '25_PERSONAL/02_Finance'),
    ({'resume', 'cv'},                  '25_PERSONAL/06_Legal_and_ID'),
    ({'manual', 'guide', 'readme'},     '40_REFERENCE'),
]


def _pattern_segment(pattern: str) -> str:
    """Extract the glob segment from a pattern like **/AppData/** or **/.*rc."""
    return pattern.replace('**/', '').replace('/**', '').replace('**', '').strip('/')


def _matches_protected(path: Path, protected: list) -> tuple[bool, str]:
    parts = path.parts
    parts_set = set(parts)
    path_str = str(path)
    for entry in protected:
        segment = _pattern_segment(entry['path_pattern'])
        if not segment:
            continue
        has_wildcard = any(c in segment for c in ('*', '?', '['))
        if has_wildcard:
            # Match against the filename or any path component
            if fnmatch.fnmatch(path.name, segment):
                return True, entry['reason']
            if any(fnmatch.fnmatch(part, segment) for part in parts):
                return True, entry['reason']
        else:
            # Literal match — segment must appear as a path component or substring
            if segment in parts_set or f'/{segment}/' in path_str:
                return True, entry['reason']
    return False, ''


def classify_risk(path: Path, protected: list | None = None) -> tuple[str, str]:
    """Return (tier, reason) — HIGH_RISK, CAUTION, or SAFE."""
    if protected:
        matched, reason = _matches_protected(path, protected)
        if matched:
            return 'HIGH_RISK', reason

    for part in path.parts:
        if part in HIGH_RISK_KEYWORDS:
            return 'HIGH_RISK', f"contains high-risk path component: {part}"

    ext = path.suffix.lower()
    safe_extensions = {
        '.jpg', '.jpeg', '.png', '.gif', '.mp4', '.mov', '.mp3',
        '.flac', '.wav', '.pdf', '.docx', '.doc', '.txt', '.md',
    }
    if ext in safe_extensions:
        return 'SAFE', f"clear user content file type ({ext})"

    return 'CAUTION', "no strong risk or safety signal"


# Note: top-level folder names (e.g. "projects", "media") will not trigger parent
# signals because they ARE the item being classified — path.parent.name points to
# the scan root, not the folder itself. Parent signals activate in deeper recursion
# passes when scanning the contents of these folders.
def suggest_destination(path: Path, standard: dict) -> tuple[str, str, str]:
    """Return (folder_key, confidence, reason)."""
    signals = []
    reasons = []

    ext = path.suffix.lower()
    name = path.name.lower()
    parent = path.parent.name.lower()

    if ext in EXT_DESTINATIONS:
        dest = EXT_DESTINATIONS[ext]
        signals.append(dest)
        reasons.append(f"extension {ext}")

    if parent in PARENT_DESTINATIONS:
        dest = PARENT_DESTINATIONS[parent]
        signals.append(dest)
        reasons.append(f"parent folder '{path.parent.name}'")

    for keywords, dest in FILENAME_PATTERNS:
        if any(kw in name for kw in keywords):
            signals.append(dest)
            reasons.append(f"filename pattern ({', '.join(k for k in keywords if k in name)})")

    if not signals:
        return '00_INBOX', 'LOW', 'no classification signal — defaulting to inbox'

    if len(signals) == 1:
        return signals[0], 'MEDIUM', reasons[0]

    if len(set(signals)) == 1:
        return signals[0], 'HIGH', f"multiple signals agree: {'; '.join(reasons)}"

    return signals[0], 'LOW', f"conflicting signals: {'; '.join(reasons)}"
