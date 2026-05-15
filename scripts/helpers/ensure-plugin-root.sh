#!/usr/bin/env bash
# Claude Octopus — Ensure ~/.claude-octopus/plugin symlink exists
# Lightweight preflight for command files. Idempotent and safe to call
# from LLM Bash tool context where ${CLAUDE_PLUGIN_ROOT} is NOT available.
#
# After marketplace install the SessionStart hook normally creates this
# symlink, but if the hook hasn't fired yet (first command invoked before
# session start) or silently errored, this script self-heals.
#
# Exit code: 0 on success, 1 if plugin root cannot be resolved.
# See: https://github.com/nyldn/claude-octopus/issues/377

set -eo pipefail

STABLE_ROOT="${HOME}/.claude-octopus/plugin"

# Fast path — already exists and points to a valid directory
if [[ -d "$STABLE_ROOT" && -x "$STABLE_ROOT/scripts/orchestrate.sh" ]]; then
    exit 0
fi

# --- Resolve plugin root ---
PLUGIN_ROOT=""

# Strategy 1: CLAUDE_PLUGIN_ROOT env var (set by CC in hook context)
if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" && -d "${CLAUDE_PLUGIN_ROOT}" ]]; then
    PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT}"
fi

# Strategy 2: Relative to this script (works when script is inside the plugin tree)
if [[ -z "$PLUGIN_ROOT" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
    candidate="$(dirname "$(dirname "$SCRIPT_DIR")")"
    if [[ -f "$candidate/scripts/orchestrate.sh" ]]; then
        PLUGIN_ROOT="$candidate"
    fi
fi

# Strategy 3: CC marketplace cache — find the latest installed version
if [[ -z "$PLUGIN_ROOT" ]]; then
    cache_base="${HOME}/.claude/plugins/cache/nyldn-plugins/octo"
    if [[ -d "$cache_base" ]]; then
        latest="$(ls -1d "$cache_base"/*/ 2>/dev/null | sort -V | tail -1)"
        if [[ -n "$latest" && -f "${latest}scripts/orchestrate.sh" ]]; then
            PLUGIN_ROOT="${latest%/}"
        fi
    fi
fi

# Strategy 4: Cowork / desktop-app plugin cache
if [[ -z "$PLUGIN_ROOT" ]]; then
    for search_root in \
        "${HOME}/Library/Application Support/Claude" \
        "${LOCALAPPDATA:-/dev/null}/Claude" \
        "${XDG_DATA_HOME:-${HOME}/.local/share}/Claude"; do
        if [[ -d "$search_root" ]]; then
            found="$(find "$search_root" -maxdepth 8 -path "*/nyldn-plugins/octo/*/scripts/orchestrate.sh" -print -quit 2>/dev/null)"
            if [[ -n "$found" ]]; then
                PLUGIN_ROOT="$(cd "$(dirname "$(dirname "$found")")" && pwd -P)"
                break
            fi
        fi
    done
fi

if [[ -z "$PLUGIN_ROOT" ]]; then
    echo "error: could not locate Octopus plugin root. Run /octo:setup or reinstall." >&2
    exit 1
fi

# Canonicalize to physical path to avoid self-referential symlinks (#371)
PLUGIN_ROOT="$(cd "$PLUGIN_ROOT" && pwd -P)"

# Source the full self-heal helper if available (handles Windows shims etc.)
if [[ -f "$PLUGIN_ROOT/scripts/lib/plugin-root.sh" ]]; then
    source "$PLUGIN_ROOT/scripts/lib/plugin-root.sh"
    if declare -f octo_ensure_stable_plugin_root >/dev/null 2>&1; then
        octo_ensure_stable_plugin_root "$PLUGIN_ROOT" >/dev/null 2>&1
        if [[ -d "$STABLE_ROOT" && -x "$STABLE_ROOT/scripts/orchestrate.sh" ]]; then
            exit 0
        fi
    fi
fi

# Simple fallback: create symlink directly
mkdir -p "${HOME}/.claude-octopus"

# Remove stale symlink/file if present
if [[ -L "$STABLE_ROOT" || -e "$STABLE_ROOT" ]]; then
    rm -f "$STABLE_ROOT" 2>/dev/null || true
fi

ln -sfn "$PLUGIN_ROOT" "$STABLE_ROOT" 2>/dev/null || true

# Verify
if [[ -d "$STABLE_ROOT" && -x "$STABLE_ROOT/scripts/orchestrate.sh" ]]; then
    exit 0
else
    echo "error: failed to create stable plugin root at $STABLE_ROOT" >&2
    exit 1
fi
