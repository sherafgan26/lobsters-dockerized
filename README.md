# Lobsters Dockerized

[![Build and push Docker image](https://github.com/sherafgan26/lobsters-dockerized/actions/workflows/docker-image.yml/badge.svg)](https://github.com/sherafgan26/lobsters-dockerized/actions/workflows/docker-image.yml)

A production-ready Docker stack for the [Lobsters](https://github.com/lobsters/lobsters) Rails application. The Rails code is imported unchanged from upstream Lobsters; the **Docker, Docker Compose, and Docker Swarm setup is mine**.

## What this repo demonstrates

- **Plain Docker** — multi-stage Dockerfile, slim runtime, non-root user, jemalloc preload, `HEALTHCHECK`, BuildKit cache mounts, hardened `.dockerignore`.
- **Docker Compose (prod)** — `docker-compose.prod.yml` layered on top of the upstream dev compose. Drops the source mount, adds a `solid_queue` worker, log rotation, restart policies, and DB health gates.
- **Docker Swarm** — `stack.yml` with overlay network, external secrets (`_FILE` env pattern), rolling updates with `start-first`, memory limits, Traefik routing labels, and a manager-pinned DB.
- **CI** — GitHub Actions workflow builds the image on every push and tag and pushes to GHCR, with multi-tag labels via `docker/metadata-action` and Buildx layer cache via `type=gha`.
- **Operator DX** — Makefile shortcuts (`make docker-build`, `make prod-up`, `make stack-deploy`).

## Files I added

| File | Purpose |
| --- | --- |
| [`Dockerfile`](Dockerfile) | Multi-stage production image |
| [`.dockerignore`](.dockerignore) | Build context filter |
| [`docker-compose.prod.yml`](docker-compose.prod.yml) | Production compose override |
| [`stack.yml`](stack.yml) | Docker Swarm deploy stack |
| [`.env.example`](.env.example) | Runtime environment variables |
| [`.github/workflows/docker-image.yml`](.github/workflows/docker-image.yml) | CI build + GHCR push |
| [`docs/docker_production.md`](docs/docker_production.md) | Full operator walkthrough |
| [`Makefile`](Makefile) | Convenience targets (added prod targets to upstream's) |

## Quick start

```bash
cp .env.example .env
# fill in SECRET_KEY_BASE, DATABASE_PASSWORD, DATABASE_ROOT_PASSWORD

make docker-build          # builds the production image locally
make prod-up               # web + worker + db with the production image
```

For full details — including Swarm deployment, secrets, scaling, and the CI pipeline — see [`docs/docker_production.md`](docs/docker_production.md).

## Attribution

The application code in this repository is imported from
[`lobsters/lobsters`](https://github.com/lobsters/lobsters) at commit
`36644efd` and is distributed under its original
[LICENSE](LICENSE). I did not author the Rails application; that credit
belongs to the Lobsters maintainers. My contributions are limited to the
Docker / Compose / Swarm / CI files listed above.

The upstream Lobsters README is preserved as [`README.upstream.md`](README.upstream.md).
