# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## Project Overview

CSGHub Omnibus is a one-click Docker Compose deployment solution for OpenCSG's AI model management platform. It bundles all services (backend, frontend, database, git storage, monitoring, etc.) into a single containerized deployment using Runit for process supervision.

Two editions exist:
- **CE (Community Edition)**: Built from `Dockerfile`, uses standalone PostgreSQL
- **EE (Enterprise Edition)**: Built from `ee.Dockerfile`, adds Patroni for HA, plus extra services under `ee/opt/csghub/embedded/sv/` (billing, producer, xnet, worker, agentic, web)

## Build Commands

```bash
# Build Docker image (single platform, auto-runs version-update + checks)
make build

# Build and push multi-platform images (arm64 + amd64)
make buildx-push

# Merge component version manifests from dockerfiles/*/version-manifests.json
make version-update

# Verify required tools (docker, jq, docker-buildx) and files
make check-deps

# Show all component versions from version-manifests.json
make versions

# Remove local built images
make clean
```

Prerequisites: Docker, `jq`, Docker Buildx plugin.

## Deployment

```bash
# Basic features (no Kubernetes-dependent features like model eval/inference/fine-tuning/Spaces)
docker compose -f docker-compose-simple.yml up -d

# Full features (requires Kubernetes 1.28+)
docker compose -f docker-compose.yml up -d
```

## Architecture

### Service Management Flow

1. `scripts/entrypoint.sh` — runs `csghub-ctl reconfigure` twice (with retry), then starts Runit daemon
2. `csghub-ctl` (Go binary at `toolbox/csghub-ctl/`) — CLI for reconfigure, start/stop/restart, tail logs, psql, creds
3. Runit supervises all services defined under `opt/csghub/embedded/sv/` (or `ee/opt/...` for EE)
4. Each service directory contains `templates/` with config template files rendered during reconfigure

### Configuration Priority (highest to lowest)

1. `CSGHUB_OMNIBUS_CONFIG` environment variable
2. `/etc/csghub/csghub.yaml` (user config)
3. `/opt/csghub/etc/csghub/default.yaml` (defaults)

### Key Directories

- `opt/csghub/embedded/sv/<service>/` — service definitions with run scripts and config templates
- `opt/csghub/etc/csghub/default.yaml` — default configuration for all services
- `opt/csghub/version-manifests.json` — centralized version tracking for all components
- `dockerfiles/` — per-component Dockerfiles and version manifests
- `toolbox/csghub-ctl/` — Go-based management CLI (`cmd/` for commands, `internal/` for business logic)
- `scripts/entrypoint.sh` — container entrypoint
- `example/` — sample Docker Compose files (CE and EE)

### Documentation

项目文档存在于两个位置：
- `docs/` — 仓库内置文档（已有内容，不要新增）
- `/Users/cyrus/workspace/csghub-omnibus-ws/csghub-omnibus-docs` — 外部文档目录

**规则：除非用户明确指定路径，所有新文档只能写到 `/Users/cyrus/workspace/csghub-omnibus-ws/csghub-omnibus-docs/`，不允许写入仓库内的 `docs/` 目录。**

### Core Services (30+ total)

- **csghub-server**: Backend API service
- **csghub-portal**: Web frontend
- **nginx**: Reverse proxy (ports 80/443)
- **postgresql/redis**: Data storage and caching
- **gitaly/gitlab-shell**: Git repository storage and SSH access (port 2222)
- **minio**: S3-compatible object storage
- **casdoor**: Identity and access management (SSO/OAuth)
- **consul**: Service discovery
- **temporal**: Workflow orchestration
- **nats**: Message broker
- **prometheus/loki**: Monitoring and logging
- **registry**: Docker container registry (port 5000)
- **dnsmasq**: DNS resolution

### Version Management

Component versions are tracked in `opt/csghub/version-manifests.json`. Per-component manifests live in `dockerfiles/*/version-manifests.json` and are merged via `make version-update`. The Makefile extracts version build args from this JSON and passes them as `--build-arg` during Docker build.

### csghub-ctl CLI (Go)

Located at `toolbox/csghub-ctl/`. Built with `urfave/cli/v2`. Key commands:
- `reconfigure` — renders all service config templates and restarts services
- `start/stop/restart/status/tail` — service lifecycle management
- `psql` — database shell access
- `creds` — fetch service credentials
- `consul`, `patroni`, `praefect` — service-specific subcommands
- `kyml` — Kubernetes YAML generation

## CI/CD

GitLab CI (`.gitlab-ci.yml`) detects changed components and triggers parallel child pipeline builds for both `linux/arm64` and `linux/amd64` platforms.
