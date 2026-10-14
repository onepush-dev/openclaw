#!/bin/sh
# Railway wrapper for the official OpenClaw image.
#  1. fix ownership of the root-owned Railway volume (/data)
#  2. seed a minimal openclaw.json on first boot (gateway.mode=local, lan bind,
#     Control UI origin = this service's public Railway domain)
#  3. drop to the unprivileged `node` user and exec the upstream entrypoint
#     (tini -> docker-entrypoint.mjs, which runs `openclaw doctor --fix`).
set -e

DATA_ROOT="${RAILWAY_VOLUME_MOUNT_PATH:-/data}"
STATE_DIR="${OPENCLAW_STATE_DIR:-$DATA_ROOT/.openclaw}"
CONFIG_PATH="${OPENCLAW_CONFIG_PATH:-$STATE_DIR/openclaw.json}"
WORKSPACE_DIR="${OPENCLAW_WORKSPACE_DIR:-$DATA_ROOT/workspace}"
SECRET_DIR="$DATA_ROOT/.config/openclaw"
APP_UID=1000
APP_GID=1000

if [ "$(id -u)" = "0" ]; then
  mkdir -p "$STATE_DIR" "$WORKSPACE_DIR" "$SECRET_DIR" "$(dirname "$CONFIG_PATH")"

  # Persist the auth-profile secret dir (~/.config/openclaw) on the volume too.
  if [ ! -L /home/node/.config/openclaw ]; then
    if [ -d /home/node/.config/openclaw ]; then
      cp -a /home/node/.config/openclaw/. "$SECRET_DIR"/ 2>/dev/null || true
      rm -rf /home/node/.config/openclaw
    fi
    ln -s "$SECRET_DIR" /home/node/.config/openclaw
  fi

  # First boot: seed a minimal config. ${VAR} placeholders are resolved by
  # OpenClaw at runtime, so the origin follows the Railway domain and the
  # token stays in Railway variables instead of the file.
  if [ ! -f "$CONFIG_PATH" ]; then
    echo "railway-entrypoint: seeding $CONFIG_PATH"
    cat > "$CONFIG_PATH" <<'JSON'
{
  "gateway": {
    "mode": "local",
    "bind": "lan",
    "port": 18789,
    "auth": {
      "mode": "token"
    },
    "controlUi": {
      "allowedOrigins": ["https://${RAILWAY_PUBLIC_DOMAIN}"]
    }
  }
}
JSON
  fi

  find "$DATA_ROOT" \( ! -user "$APP_UID" -o ! -group "$APP_GID" \) -exec chown -h "$APP_UID:$APP_GID" {} + 2>/dev/null || true
  chmod 700 "$STATE_DIR" "$SECRET_DIR" 2>/dev/null || true
  chmod 600 "$CONFIG_PATH" 2>/dev/null || true

  export HOME=/home/node USER=node
  if command -v setpriv >/dev/null 2>&1; then
    exec setpriv --reuid="$APP_UID" --regid="$APP_GID" --init-groups \
      tini -s -- node /app/docker-entrypoint.mjs "$@"
  elif command -v runuser >/dev/null 2>&1; then
    exec runuser -u node -- tini -s -- node /app/docker-entrypoint.mjs "$@"
  fi
  echo "WARNING: no setpriv/runuser found; running OpenClaw as root" >&2
fi
exec tini -s -- node /app/docker-entrypoint.mjs "$@"
