# OpenClaw on Railway

One-click [OpenClaw](https://github.com/openclaw/openclaw) **2026.10.3**: the self-hosted AI agent gateway with its web Control UI. It runs on the **official image, pinned by digest**, and keeps its state on a Railway volume. You fill in nothing at deploy time.

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/Oq97C0)

Template: https://railway.com/deploy/Oq97C0 (template editor for maintainers: https://railway.com/workspace/templates/e8e63bf3-0c80-4dd8-8de4-e81a82514e69)

## What you get

| | |
|---|---|
| Image | `openclaw/openclaw:2026.10.3-browser@sha256:c84c4c37e7b9dc02dd869c9699ba0c4fb20ff821febe4b789bb2f8f4bfd9c8a3` (multi-arch index: linux/amd64 + linux/arm64). The browser variant ships Chromium + Xvfb for the agent's browser tool. |
| Gateway | Listens on port `18789` with `--bind lan`. Token auth uses an auto-generated `OPENCLAW_GATEWAY_TOKEN`. |
| Control UI | `https://<your-domain>/`. The origin is allow-listed automatically from `RAILWAY_PUBLIC_DOMAIN`. |
| Reverse proxy | `gateway.trustedProxies = ["100.64.0.0/10"]` covers Railway's edge, so the real client IP is used and Control UI routes are not rejected with `proxy_attribution_required`. |
| Persistence | Volume at `/data`, holding `openclaw.json`, the SQLite state and auth stores, sessions, the agent workspace and the auth-profile key dir. |
| Health | Liveness at `/healthz`; `/startupz` and `/readyz` are also exposed. |
| Upgrades | The image's own entrypoint runs `openclaw doctor --fix --non-interactive` on every boot, so moving to a newer image migrates state safely. |

### How it compares to other OpenClaw templates

Older Railway templates wrap an npm install of `openclaw@2026.9.x` behind a custom `/setup` page. This one runs the **official 2026.10.3 container** unmodified. It is pinned by digest, needs no extra build step, uses upstream's entrypoint and doctor migrations, and requires zero deploy inputs.

## After deploy

1. **Open the Control UI** at `https://<your-domain>/`.
2. **Paste the gateway token.** It's in Railway → service → **Variables** → `OPENCLAW_GATEWAY_TOKEN`.
3. **Approve this browser (one time).** OpenClaw pairs every new browser device. Open a Railway shell (`railway ssh`, or the service's **Shell** tab) and run:
   ```bash
   su node -s /bin/sh -c 'openclaw devices list'
   su node -s /bin/sh -c 'openclaw devices approve <requestId>'
   ```
   Keep the page open: it connects on its own once you approve. You can also run `su node -s /bin/sh -c 'openclaw dashboard --json'` and open its one-time `browserUrl`. Swap the loopback base for your Railway domain and use it within 10 minutes.
4. **Add a model provider.** Set `OPENAI_API_KEY`, `ANTHROPIC_API_KEY` (or any other provider key) in Railway Variables, or configure one in the Control UI. The service redeploys and picks it up.
5. **Connect channels** (optional). For example, set `TELEGRAM_BOT_TOKEN` and add the channel in the Control UI or with `openclaw channels add --channel telegram --use-env`.

## Variables

| Variable | Default | Purpose |
|---|---|---|
| `OPENCLAW_GATEWAY_TOKEN` | `${{secret(48, "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")}}` | Shared admin secret for the Gateway and Control UI. Treat it like a password. |
| `OPENCLAW_RAILWAY_CONFIG` | see below | A `openclaw config set --batch-json` payload applied on every boot |
| `PORT` / `OPENCLAW_GATEWAY_PORT` | `18789` | Gateway listener port (the Railway domain targets 18789) |
| `OPENCLAW_GATEWAY_BIND` | `lan` | Bind mode (the start command also passes `--bind lan`) |
| `OPENCLAW_STATE_DIR` / `OPENCLAW_CONFIG_DIR` | `/data/.openclaw` | State and config directory on the volume |
| `OPENCLAW_CONFIG_PATH` | `/data/.openclaw/openclaw.json` | Config file |
| `OPENCLAW_WORKSPACE_DIR` | `/data/workspace` | Agent workspace on the volume |
| `HOME` / `OPENCLAW_HOME` | `/home/node` | Upstream container home |
| `TZ` | `UTC` | Container timezone |
| `RAILWAY_RUN_UID` | `0` | Starts the container as root only to `chown` the volume; the gateway then runs as `node` (uid 1000) via `setpriv` |
| `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `TELEGRAM_BOT_TOKEN` | empty | Optional; add them after deploy |

Default `OPENCLAW_RAILWAY_CONFIG`:

```json
[{"path":"gateway.mode","value":"local"},
 {"path":"gateway.publicOrigin","value":"https://${{RAILWAY_PUBLIC_DOMAIN}}"},
 {"path":"gateway.controlUi.allowedOrigins","value":["https://${{RAILWAY_PUBLIC_DOMAIN}}"]},
 {"path":"gateway.trustedProxies","value":["100.64.0.0/10"]}]
```

(Keep it on one line, without spaces, in the variable.) If you add a custom domain, put its origin in `allowedOrigins` here. Edits you make to these four keys elsewhere are re-applied from this variable on each boot.

## Service settings (template)

- **Source:** the image above (digest-pinned)
- **Start command:** see [`start-command.txt`](start-command.txt). It fixes volume ownership, applies `OPENCLAW_RAILWAY_CONFIG`, then `exec`s upstream `tini -> docker-entrypoint.mjs -> openclaw gateway --bind lan --port 18789 --allow-unconfigured` as `node`.
- **Volume:** `/data`
- **Healthcheck:** `/healthz`, timeout 300 s; restart policy on failure
- **Networking:** public HTTP domain → port `18789`
- **Resources:** about 1.1 GB RAM at idle, with peaks around 1.7 GB during first-boot doctor and startup

You can also deploy this repo's `Dockerfile` + `railway-entrypoint.sh` + `railway.toml` from GitHub. It applies the same logic and needs no `RAILWAY_RUN_UID`.

## Backups

```bash
su node -s /bin/sh -c 'openclaw backup create'
```

## Upstream

- Source: https://github.com/openclaw/openclaw
- Docs: https://docs.openclaw.ai (Docker: https://docs.openclaw.ai/install/docker)
- License: MIT
