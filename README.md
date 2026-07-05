# supermemory-docker

Wrapper Docker image for self-hosted [Supermemory](https://github.com/supermemoryai/supermemory).

Upstream Supermemory ships a single precompiled binary (`supermemory-server`) — no official Docker image. This repo wraps it into an `arm64` image, published to public GHCR for use by Coolify.

## Image

`ghcr.io/ravibaskaran/supermemory-server:latest` (also tagged `:v${VERSION}` per release)

- Base: `debian:bookworm-slim`
- Entrypoint: `tini -- /usr/local/bin/supermemory-server`
- Listens on `:6767`
- Data volume: `/data`
- The binary is downloaded and sha256-verified at build time

## Auto-upgrade pipeline

Two GitHub Actions workflows:

- **`build.yml`** — on push to `main` or `workflow_dispatch`. Builds `linux/arm64`, pushes to GHCR with `:latest` and `:v${SUPERMEMORY_VERSION}` tags.
- **`check-upstream.yml`** — hourly cron. Polls the upstream supermemory release, bumps `.supermemory-version` if newer, triggers a rebuild, then calls Coolify's `/services/{uuid}/restart?latest=true` endpoint via deploy-scope token to perform a rolling upgrade.

## Required GitHub Actions secrets

- `COOLIFY_DEPLOY_TOKEN` — Coolify API token with `deploy` ability
- `COOLIFY_SERVICE_UUID` — UUID of the Coolify service to restart on upgrade

## Local test

```bash
OPENAI_API_KEY=sk-... docker compose up -d
curl -fsS http://localhost:6767/health
docker logs supermemory 2>&1 | grep -E 'api key|org id'   # capture the sm_... key
```

## Coolify deployment

Deployed as a Docker Compose Empty service on Coolify at `https://supermemory.justoinfo.com`. Container caps: 1 GB RAM / 0.5 CPU, `restart: on-failure:5`, log rotation `max-size=10m, max-file=3`.

## Configuration reference

See upstream docs: <https://supermemory.ai/docs/self-hosting/configuration>
