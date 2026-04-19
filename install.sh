#!/usr/bin/env bash
# RootDown bootstrap — macOS / Linux / WSL
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_MIN_MAJOR=3
PYTHON_MIN_MINOR=8

echo "RootDown Bootstrap"
echo "=================="
echo ""

# ── Helpers ────────────────────────────────────────────────────────────────

ok()    { echo "[OK]    $*"; }
info()  { echo "[INFO]  $*"; }
error() { echo "[ERROR] $*" >&2; }

python_version_ok() {
    local cmd="$1"
    if ! command -v "$cmd" &>/dev/null; then
        return 1
    fi
    local version
    version="$("$cmd" --version 2>&1 | grep -oE '[0-9]+\.[0-9]+'| head -1)"
    local major minor
    major="${version%%.*}"
    minor="${version##*.}"
    [[ "$major" -gt "$PYTHON_MIN_MAJOR" ]] && return 0
    [[ "$major" -eq "$PYTHON_MIN_MAJOR" && "$minor" -ge "$PYTHON_MIN_MINOR" ]] && return 0
    return 1
}

find_python() {
    for cmd in python3 python; do
        if python_version_ok "$cmd"; then
            echo "$cmd"
            return 0
        fi
    done
    return 1
}

# ── Python check ───────────────────────────────────────────────────────────

PYTHON=""
if PYTHON="$(find_python)"; then
    version="$("$PYTHON" --version 2>&1)"
    ok "Python confirmed: $version"
else
    info "Python $PYTHON_MIN_MAJOR.$PYTHON_MIN_MINOR+ not found. Attempting install..."

    OS_ID=""
    if [[ "$(uname)" == "Darwin" ]]; then
        OS_ID="macos"
    elif [[ -f /etc/os-release ]]; then
        OS_ID="$(. /etc/os-release && echo "$ID")"
    fi

    case "$OS_ID" in
        macos)
            if command -v brew &>/dev/null; then
                info "Installing Python via Homebrew..."
                brew install python3
            else
                error "Homebrew not found. Install Python manually: https://www.python.org/downloads/"
                exit 1
            fi
            ;;
        ubuntu|debian)
            info "Installing Python via apt..."
            sudo apt-get update -qq
            sudo apt-get install -y python3
            ;;
        *)
            error "Unsupported OS. Install Python $PYTHON_MIN_MAJOR.$PYTHON_MIN_MINOR+ manually: https://www.python.org/downloads/"
            exit 1
            ;;
    esac

    if PYTHON="$(find_python)"; then
        version="$("$PYTHON" --version 2>&1)"
        ok "Python confirmed after install: $version"
    else
        error "Python $PYTHON_MIN_MAJOR.$PYTHON_MIN_MINOR+ still not found after install attempt."
        error "Install manually: https://www.python.org/downloads/"
        exit 1
    fi
fi

# ── Run deployer ───────────────────────────────────────────────────────────

echo ""
info "Running RootDown deployer..."
echo ""
exec "$PYTHON" "$SCRIPT_DIR/deploy.py" "$@"
