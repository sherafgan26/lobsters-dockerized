# Running Lobsters in production with Docker

This doc covers the production-style Docker setup added alongside the existing
dev `Dockerfile.dev` / `docker-compose.yaml`. The dev files are unchanged.

## Files

| File | Purpose |
| --- | --- |
| `Dockerfile` | Multi-stage production image (builder + slim runtime, non-root user, jemalloc, `HEALTHCHECK`). |
| `.dockerignore` | Keeps the build context small. |
| `docker-compose.prod.yml` | Override layered on top of `docker-compose.yaml` to run the built image plus a `solid_queue` worker. |
| `stack.yml` | Docker Swarm stack with replicas, secrets, overlay network, rolling updates, and Traefik labels. |
| `.env.example` | Required runtime variables. Copy to `.env` and fill in. |
| `.github/workflows/docker-image.yml` | Builds the image on push/tag and pushes to `ghcr.io/sherafgan26/lobsters`. |
| `Makefile` | Shortcuts: `make docker-build`, `make prod-up`, `make stack-deploy`, etc. |

## Local production-style run

```bash
cp .env.example .env
# fill in SECRET_KEY_BASE, DATABASE_PASSWORD, DATABASE_ROOT_PASSWORD

make docker-build          # builds ghcr.io/sherafgan26/lobsters:latest
make prod-up               # starts app + worker + db with the prod image
make prod-down             # tears it down
```

The override file disables the source mount and adds log rotation and a
`solid_queue` worker that runs `bin/jobs start`.

## Swarm deploy

1. On the manager node, initialise swarm and create the three secrets:

   ```bash
   docker swarm init
   printf '%s' "$SECRET_KEY_BASE"        | docker secret create lobsters_secret_key_base -
   printf '%s' "$DATABASE_PASSWORD"      | docker secret create lobsters_db_password -
   printf '%s' "$DATABASE_ROOT_PASSWORD" | docker secret create lobsters_db_root_password -
   ```

2. Deploy:

   ```bash
   make stack-deploy
   ```

3. Inspect:

   ```bash
   docker stack services lobsters
   docker service logs -f lobsters_app
   ```

4. Scale:

   ```bash
   docker service scale lobsters_app=5 lobsters_worker=3
   ```

The stack pins the `db` service to the manager node so the named volume stays
on one host. For a multi-node DB you'd run MariaDB externally and remove the
service from the stack.

## CI / Registry

The workflow at `.github/workflows/docker-image.yml` builds for every push to
`main` and every `v*.*.*` tag, then pushes to GHCR with these tag patterns:

- `main` (branch)
- `pr-<n>` (pull requests, build only, not pushed)
- `vX.Y.Z` and `X.Y.Z` (release tags)
- `sha-<short>` (every push)

Buildx layer cache is stored in GHA so subsequent builds are fast.
