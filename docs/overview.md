---
type: System Overview
title: AttendanceTracker
description: An attendance kiosk for a club where participants tap their photo to check in, with weekly recurring trainings and an admin PIN.
tags: [architecture, overview, phoenix, liveview, ecto, sqlite]
status: stable
generated: { by: human:gregorybleiker, at: 2026-10-03T00:00:00Z }
verified: { by: human:gregorybleiker, at: 2026-10-03T00:00:00Z }
sources:
  - id: repo
    resource: https://github.com/gregorybleiker/attendancetracker
    title: AttendanceTracker source repository
    author: human:gregorybleiker
  - id: tracker-context
    resource: ../lib/attendancetracker/tracker.ex
    title: Tracker context
    author: human:gregorybleiker
  - id: router
    resource: ../lib/attendancetracker_web/router.ex
    title: Router
    author: human:gregorybleiker
---

# What it is

An attendance kiosk for a club (e.g. judo): participants tap their photo on a
check-in screen, trainings recur weekly ("every Monday 19:00–21:30"), and an
admin PIN guards corrections. Built with Phoenix 1.8, LiveView, Ecto + SQLite.

This bundle walks the codebase layer by layer and calls out the important
**Elixir and Phoenix idioms** it relies on. See the
[idioms cheat sheet](/architecture/idioms.md) for a quick feature index.

# Runtime layers

```
Browser(s)  ◄── WebSocket ──►  LiveViews (one process per connected client)
                                    │
                                    ▼
                            Tracker context          ◄── the only API the web
                             (lib/attendancetracker/      layer talks to
                              tracker.ex)
                                    │
                    ┌───────────────┼────────────────┐
                    ▼               ▼                ▼
                 Ecto Repo      Phoenix.PubSub    Photo controller
                  (SQLite,      (real-time sync)  (serves photos
                 incl. photos)                      from the DB)
```

**Idiom: contexts as boundaries.** Everything the web layer needs goes through
one module, `AttendanceTracker.Tracker`. LiveViews never call `Repo` directly.
This is the "context" concept from `phx.gen.context`: a plain module grouping
related operations — no framework magic, just a convention that keeps the web
and persistence layers decoupled.

# Where to go next

- [Directory map](/architecture/directory-map.md)
- [Domain model](/architecture/domain-model.md)
- [Web layer](/architecture/web-layer.md)
- [Deployment](/deployment.md)
