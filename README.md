# OpenClaw on Railway

One-click [OpenClaw](https://github.com/openclaw/openclaw) gateway + Control UI on Railway, built on the **official image pinned by digest**.

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/TEMPLATE_CODE)

- Image: `openclaw/openclaw:2026.10.3-browser@sha256:c84c4c37e7b9dc02dd869c9699ba0c4fb20ff821febe4b789bb2f8f4bfd9c8a3` (linux/amd64 + arm64, bundles Chromium for the browser tool)
- Gateway on port `18789`, bound to `lan`, token auth with an auto-generated token
- Persistent state on a Railway volume at `/data`
- Health check: `/healthz`
- **Zero required inputs at deploy time.** Add LLM provider keys afterwards.

DEPLOY_DETAILS_PLACEHOLDER
