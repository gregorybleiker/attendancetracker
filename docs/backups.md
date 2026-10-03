---
type: Runbook
title: Backups
description: SQLite-safe snapshots of the single database that holds participants and their photos.
tags: [backup, sqlite, operations, cron]
status: stable
generated: { by: human:gregorybleiker, at: 2026-10-03T00:00:00Z }
verified: { by: human:gregorybleiker, at: 2026-10-03T00:00:00Z }
sources:
  - id: repo
    resource: https://github.com/gregorybleiker/attendancetracker
    title: AttendanceTracker source repository
    author: human:gregorybleiker
  - id: compose
    resource: ../compose.yml
    title: compose.yml (volume definitions)
    author: human:gregorybleiker
---

# Snapshot

State is a single SQLite database at `/data/db/attendancetracker.db` (in the
`db-data` volume, or your `DATABASE_DIR` host directory), containing both the
participants and their photos. Back it up regularly, e.g. a cron job on the
VPS:

```bash
# SQLite-safe snapshot (works while the app is running)
docker run --rm \
  -v attendancetracker_db-data:/data/db \
  -v /root/backups:/backup \
  alpine sh -c 'apk add -q sqlite && sqlite3 /data/db/attendancetracker.db ".backup /backup/att-$(date +%F).db"'
```

(Adjust the volume name with `docker volume ls` — compose prefixes it with
the project directory name. If you set `DATABASE_DIR`, snapshot that host
directory with `sqlite3` directly instead.)

See also [Deployment](/deployment.md) and [Troubleshooting](/troubleshooting.md).
