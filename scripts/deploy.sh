#!/usr/bin/env bash
#
# Deploy the qFioofa opencode configuration.
#
# Default mode is a symlink: ~/.config/opencode -> <repo>/src, so edits in the
# repo are picked up immediately. Use --copy on systems where symlinked config
# directories are not supported, or when opencode must write into the config
# directory (e.g. `opencode plugin -g`).
#
# Works on Linux and macOS with any opencode version >= 1.0. The Windows
# equivalent is scripts/deploy.bat.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC_DIR="$REPO_DIR/src"

TARGET="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
MODE="link"          # link | copy
DO_BACKUP=0
DO_REMOVE=0
DO_DEPS=0
DO_DRY_RUN=0

usage() {
    cat <<EOF
Deploy the opencode configuration.

Usage: $0 [options]

Options:
  -t, --target DIR   Target config directory (default: $TARGET)
  -c, --copy         Copy files instead of symlinking (default: symlink)
  -l, --link         Symlink src into the target (default)
  -b, --backup       Move an existing target to <target>.backup.<timestamp>
  -r, --remove       Remove an existing target before installing
  -d, --deps         Run \`npm install --omit=dev\` in the target when package.json exists
  -n, --dry-run      Print what would happen, change nothing
  -h, --help         Show this help

Examples:
  $0 -b
  $0 -b -d
  $0 --copy -b -t "\$HOME/.config/opencode"

The script refuses to overwrite an existing target unless -b or -r is given.
EOF
}

log() { printf '  %s\n' "$*"; }

resolve_path() {
    python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$1" 2>/dev/null \
        || readlink -f "$1" 2>/dev/null \
        || printf '%s\n' "$1"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -t|--target)
            [[ $# -ge 2 ]] || { echo "Missing value for $1" >&2; exit 2; }
            TARGET="$2"; shift 2 ;;
        -c|--copy) MODE="copy"; shift ;;
        -l|--link) MODE="link"; shift ;;
        -b|--backup) DO_BACKUP=1; shift ;;
        -r|--remove) DO_REMOVE=1; shift ;;
        -d|--deps) DO_DEPS=1; shift ;;
        -n|--dry-run) DO_DRY_RUN=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    esac
done

[[ -d "$SRC_DIR" ]] || { echo "Source directory not found: $SRC_DIR" >&2; exit 1; }

run() {
    if [[ $DO_DRY_RUN -eq 1 ]]; then
        printf '  [dry-run] %s\n' "$*"
    else
        "$@"
    fi
}

backup_target() {
    if [[ -e "$TARGET" || -L "$TARGET" ]]; then
        local ts backup
        ts="$(date +%Y%m%d-%H%M%S)"
        backup="${TARGET}.backup.${ts}"
        log "Backing up $TARGET -> $backup"
        run mv "$TARGET" "$backup"
    fi
}

if [[ -e "$TARGET" || -L "$TARGET" ]]; then
    if [[ "$MODE" == "link" && -L "$TARGET" && "$(resolve_path "$TARGET")" == "$(resolve_path "$SRC_DIR")" ]]; then
        log "Already linked: $TARGET -> $SRC_DIR"
        echo
        if command -v opencode >/dev/null 2>&1; then
            log "opencode $(opencode --version 2>/dev/null | head -1)"
        fi
        log "Restart opencode for changes to take effect."
        exit 0
    elif [[ $DO_REMOVE -eq 1 ]]; then
        log "Removing $TARGET"
        run rm -rf "$TARGET"
    elif [[ $DO_BACKUP -eq 1 ]]; then
        backup_target
    else
        echo "Target already exists: $TARGET" >&2
        echo "Pass -b (backup) or -r (remove) to continue." >&2
        exit 1
    fi
fi

run mkdir -p "$(dirname "$TARGET")"

case "$MODE" in
    link)
        log "Linking $SRC_DIR -> $TARGET"
        run ln -s "$SRC_DIR" "$TARGET"
        ;;
    copy)
        log "Copying $SRC_DIR/ -> $TARGET/"
        run mkdir -p "$TARGET"
        if command -v rsync >/dev/null 2>&1; then
            run rsync -a --exclude node_modules --exclude .git "$SRC_DIR/" "$TARGET/"
        else
            ( cd "$SRC_DIR" && tar --exclude=node_modules --exclude=.git -cf - . ) \
                | ( cd "$TARGET" && tar -xf - )
        fi
        ;;
    *)
        echo "Unknown mode: $MODE" >&2; exit 2 ;;
esac

if [[ $DO_DEPS -eq 1 && -f "$TARGET/package.json" ]]; then
    if command -v npm >/dev/null 2>&1; then
        log "Installing optional dependencies in $TARGET"
        run bash -lc "cd '$TARGET' && npm install --omit=dev"
    else
        log "npm not found; skipping dependency install"
    fi
fi

echo
if command -v opencode >/dev/null 2>&1; then
    log "opencode $(opencode --version 2>/dev/null | head -1)"
else
    log "opencode is not in PATH; install it before starting a session"
fi
log "Config: $TARGET"
log "Restart opencode for changes to take effect."
log "Verify: opencode debug config && opencode debug skill && opencode mcp list"
