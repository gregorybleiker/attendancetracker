---
type: Runbook
title: Troubleshooting
description: Common production issues: boot crashes, permissions, HTTPS/ACME, liveview websockets, and Podman/WSL mount errors.
tags: [troubleshooting, docker, caddy, websockets, podman]
status: stable
generated: { by: human:gregorybleiker, at: 2026-10-03T00:00:00Z }
verified: { by: human:gregorybleiker, at: 2026-10-03T00:00:00Z }
sources:
  - id: repo
    resource: https://github.com/gregorybleiker/attendancetracker
    title: AttendanceTracker source repository
    author: human:gregorybleiker
  - id: runtime-exs
    resource: ../config/runtime.exs
    title: runtime.exs (env var checks, allowed origins)
    author: human:gregorybleiker
  - id: dockerfile
    resource: ../Dockerfile
    title: Dockerfile (/data ownership)
    author: human:gregorybleiker
---

# Common issues

- `docker compose logs app` is the first stop for everything.
- **Crash-loop on first boot:** usually a missing env var — `runtime.exs`
  raises a clear error naming it (`SECRET_KEY_BASE`, `DATABASE_PATH`).
- **No upload / DB write permission errors:** `/data` (including `/data/db`)
  is created and `chown`ed to the `nobody` user at image build time (see
  `Dockerfile`). If you changed that, make sure the directory is writable by
  UID 65534. A host directory used via `DATABASE_DIR` must be writable by the
  same UID.
- **HTTPS not working:** DNS must resolve to the VPS *and* ports 80/443
  must be reachable for the ACME challenge — check `docker compose logs
  caddy`.
- **LiveView disconnects:** Caddy proxies websockets by default, no extra
  config needed. If you swap in nginx, remember the `Upgrade`/`Connection`
  headers. Locally, also make sure `PHX_HOST` is in the endpoint's allowed
  origins (`config/runtime.exs` allows the configured host plus `localhost`).
- **`crun: mount ... Not a directory` (Podman on WSL):** a known bug with
  *single-file* bind mounts and relative paths in `podman compose`. Mount a
  directory instead (the Caddyfile lives in `caddy/`, mounted at
  `/etc/caddy`), or make the compose provider WSL-native — the Windows
  `docker-compose.exe` in `/mnt/c/...` mis-resolves relative paths.

See also [Deployment](/deployment.md) and [Backups](/backups.md).
