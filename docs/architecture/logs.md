---
type: Reference
title: Logs
description: Database-backed audit and program logs, with opportunistic and periodic retention pruning.
tags: [logs, audit, retention, genserver]
status: stable
generated: { by: human:gregorybleiker, at: 2026-10-03T00:00:00Z }
verified: { by: human:gregorybleiker, at: 2026-10-03T00:00:00Z }
sources:
  - id: repo
    resource: https://github.com/gregorybleiker/attendancetracker
    title: AttendanceTracker source repository
    author: human:gregorybleiker
  - id: logs
    resource: ../../lib/attendancetracker/logs.ex
    title: Logs context
    author: human:gregorybleiker
  - id: audit-log
    resource: ../../lib/attendancetracker/logs/audit_log.ex
    title: Audit log schema
    author: human:gregorybleiker
  - id: program-log
    resource: ../../lib/attendancetracker/logs/program_log.ex
    title: Program log schema
    author: human:gregorybleiker
  - id: pruner
    resource: ../../lib/attendancetracker/logs/pruner.ex
    title: Logs.Pruner GenServer
    author: human:gregorybleiker
---

# Two streams

Two database-backed log streams, both kept small by design:

- **Audit log** (`audit_logs`) records user interactions: `Tracker.check_in/2`
  and `check_out/2` append a row (`action`, participant id/name, session id).
- **Program log** (`program_logs`) records sync operations. The directory
  context logs every Webling fetch (the full call description and the number of
  members matched, or the error) and every import (`created`/`linked` counts).

# Retention

`AttendanceTracker.Logs` writes entries, reads them newest-first, and trims each
stream to a maximum. Every insert opportunistically deletes the oldest rows
beyond the cap, and `AttendanceTracker.Logs.Pruner` (a `GenServer` in the app
supervision tree) additionally prunes on a timer. Both the maximum
(`log_max_entries`, default 10 000) and the interval
(`log_prune_interval_minutes`, default 60) are stored in the settings table and
editable in the admin area. `AdminLogsLive` (`/admin/logs`, reachable from the
admin panel) shows both streams in a tabbed, scrollable view (500 newest
entries each).

See also [Imports](/architecture/imports.md) and
[Merging duplicates](/architecture/duplicates.md).
