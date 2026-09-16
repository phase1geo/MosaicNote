#!/usr/bin/env bash
# mosaic-mcp-launch.sh
# Wrapper that resolves the desktop session env vars at runtime
# (Claude Desktop launches this as a subprocess without them set)
# before exec'ing the real mosaic-mcp binary.

set -euo pipefail

UID_NUM="$(id -u)"

# Find the active graphical session for this user
SESSION_ID="$(loginctl list-sessions --no-legend 2>/dev/null \
  | awk -v u="$(id -un)" '$3 == u { print $1; exit }')"

get_session_env() {
  local var="$1"
  [ -n "${SESSION_ID:-}" ] || return 1
  loginctl show-session "$SESSION_ID" -p "$var" --value 2>/dev/null
}

# --- DISPLAY ---
if [ -z "${DISPLAY:-}" ]; then
  DISPLAY="$(get_session_env Display || true)"
  [ -n "$DISPLAY" ] || DISPLAY=":0"
fi
export DISPLAY

# --- DBUS_SESSION_BUS_ADDRESS ---
if [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
  export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${UID_NUM}/bus"
fi

# --- WAYLAND_DISPLAY ---
if [ -z "${WAYLAND_DISPLAY:-}" ]; then
  # Try loginctl first (systemd ≥ 252 exposes this on some distros)
  WAYLAND_DISPLAY="$(get_session_env Type 2>/dev/null | grep -qx wayland \
    && get_session_env WaylandDisplay || true)"

  # Fallback: scan the runtime dir for a wayland socket
  if [ -z "$WAYLAND_DISPLAY" ]; then
    for sock in "/run/user/${UID_NUM}"/wayland-*; do
      [ -S "$sock" ] || continue
      WAYLAND_DISPLAY="$(basename "$sock")"
      break
    done
  fi
fi
[ -n "${WAYLAND_DISPLAY:-}" ] && export WAYLAND_DISPLAY

export XDG_RUNTIME_DIR="/run/user/${UID_NUM}"

exec "$(dirname "$0")/venv/bin/mosaic-mcp" "$@"
