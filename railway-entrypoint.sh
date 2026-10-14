#!/bin/sh
# Railway wrapper for the official OpenClaw image (used when deploying this
# repo's Dockerfile). The image-based Railway template runs the same logic
# inline as its start command (see start-command.txt).
#  1. fix ownership of the root-owned Railway volume (/data)
#  2. persist ~/.config/openclaw (auth-profile secret dir) on the volume
#  3. apply OPENCLAW_RAILWAY_CONFIG (a `openclaw config set --batch-json`
#     payload: gateway.mode, public origin, allowed origins, Railway proxy range)
#  4. drop to `node` (uid 1000) and exec the upstream entrypoint
#     (tini -> docker-entrypoint.mjs, which runs `openclaw doctor --fix`).
set -ef

D="${RAILWAY_VOLUME_MOUNT_PATH:-/data}"
mkdir -p "$D/.openclaw" "$D/workspace" "$D/.config/openclaw"
if [ ! -L /home/node/.config/openclaw ]; then
  rm -rf /home/node/.config/openclaw
  ln -s "$D/.config/openclaw" /home/node/.config/openclaw
fi
find "$D" ! -user 1000 -exec chown -h 1000:1000 {} +
chmod 700 "$D/.openclaw"
cd /app

asnode() { setpriv --reuid=1000 --regid=1000 --init-groups env HOME=/home/node USER=node "$@"; }

if [ -n "${OPENCLAW_RAILWAY_CONFIG:-}" ]; then
  asnode node openclaw.mjs config set --batch-json "$OPENCLAW_RAILWAY_CONFIG" \
    || echo "railway-entrypoint: config batch failed" >&2
fi

exec setpriv --reuid=1000 --regid=1000 --init-groups env HOME=/home/node USER=node \
  tini -s -- node /app/docker-entrypoint.mjs "$@"
