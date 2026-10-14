# OpenClaw 2026.10.3 (browser variant, bundles Chromium + Xvfb) for Railway.
# Official image, pinned by multi-arch index digest (linux/amd64 + linux/arm64).
FROM openclaw/openclaw:2026.10.3-browser@sha256:c84c4c37e7b9dc02dd869c9699ba0c4fb20ff821febe4b789bb2f8f4bfd9c8a3

# Railway volumes mount root-owned, but OpenClaw runs as `node` (uid 1000).
# Start as root, fix ownership of /data and seed a minimal config, then drop
# to `node` and hand off to the image's own entrypoint (tini + doctor --fix).
USER root
COPY --chmod=755 railway-entrypoint.sh /usr/local/bin/railway-entrypoint.sh

ENV HOME=/home/node \
    OPENCLAW_HOME=/home/node \
    OPENCLAW_STATE_DIR=/data/.openclaw \
    OPENCLAW_CONFIG_DIR=/data/.openclaw \
    OPENCLAW_CONFIG_PATH=/data/.openclaw/openclaw.json \
    OPENCLAW_WORKSPACE_DIR=/data/workspace \
    OPENCLAW_GATEWAY_PORT=18789 \
    PORT=18789 \
    TZ=UTC

EXPOSE 18789
ENTRYPOINT ["/usr/local/bin/railway-entrypoint.sh"]
CMD ["node", "openclaw.mjs", "gateway", "--bind", "lan", "--port", "18789", "--allow-unconfigured"]
