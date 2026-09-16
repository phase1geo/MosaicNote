#!/bin/bash
# Wrapper for launching mosaic-mcp with a working desktop session environment.
#
# Claude Desktop spawns MCP servers as its own subprocess, so if Claude Desktop
# itself didn't inherit DISPLAY/WAYLAND_DISPLAY/DBUS_SESSION_BUS_ADDRESS at
# startup (common with autostart entries, .desktop launchers, or sandboxed
# builds), neither will mosaic-mcp — even while you're logged into a normal
# GUI session. This script finds those variables at run time and exports them
# before handing off to the real mosaic-mcp binary, so `open_note` (which
# shells out to `gio open mosaicnote://...`) has somewhere to send the request.

set -euo pipefail

TARGET_USER="trevorw"
REAL_BIN="/home/trevorw/projects/MosaicNote/tools/mosaic-mcp/venv/bin/mosaic-mcp"

# 1) Try the systemd user manager's imported environment. Modern GNOME/KDE
#    sessions run `systemctl --user import-environment DISPLAY WAYLAND_DISPLAY
#    ...` (or use dbus-update-activation-environment) near login, so this is
#    often already populated correctly.
if command -v systemctl >/dev/null 2>&1; then
    while IFS='=' read -r key value; do
        case "$key" in
            DISPLAY|WAYLAND_DISPLAY|DBUS_SESSION_BUS_ADDRESS|XDG_RUNTIME_DIR|XAUTHORITY)
                export "$key=$value"
                ;;
        esac
    done < <(systemctl --user show-environment 2>/dev/null || true)
fi

# 2) Fallback: borrow the environment from an already-running desktop process
#    owned by the same user. This works regardless of how the session was set
#    up, as long as some GUI process (session manager, compositor, panel) is
#    already running.
if [ -z "${DISPLAY:-}" ] || [ -z "${WAYLAND_DISPLAY:-}" ]; then
    for pid in $(pgrep -u "$TARGET_USER" -f \
        'gnome-session|gnome-shell|plasmashell|xfce4-session|sway|Xorg|labwc|kwin_wayland' \
        2>/dev/null || true); do
        if [ -r "/proc/$pid/environ" ]; then
            while IFS='=' read -r -d '' entry; do
                key="${entry%%=*}"
                value="${entry#*=}"
                case "$key" in
                    DISPLAY|WAYLAND_DISPLAY|DBUS_SESSION_BUS_ADDRESS|XDG_RUNTIME_DIR|XAUTHORITY)
                        export "$key=$value"
                        ;;
                esac
            done < "/proc/$pid/environ"
            [ -n "${DISPLAY:-}" ] && [ -n "${WAYLAND_DISPLAY:-}" ] && break
        fi
    done
fi

# 3) Last-resort sensible defaults for a standard single-user desktop login.
USER_ID="$(id -u "$TARGET_USER" 2>/dev/null || echo 1000)"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/${USER_ID}}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=${XDG_RUNTIME_DIR}/bus}"
export DISPLAY="${DISPLAY:-:0}"

exec "$REAL_BIN" "$@"
