---
type: Command Reference
title: Useful commands
description: Common mix tasks for setting up, running, testing, and verifying the app.
tags: [mix, commands, development]
status: stable
generated: { by: human:gregorybleiker, at: 2026-10-03T00:00:00Z }
verified: { by: human:gregorybleiker, at: 2026-10-03T00:00:00Z }
sources:
  - id: repo
    resource: https://github.com/gregorybleiker/attendancetracker
    title: AttendanceTracker source repository
    author: human:gregorybleiker
  - id: mix-exs
    resource: ../mix.exs
    title: mix.exs (aliases, including precommit)
    author: human:gregorybleiker
---

# Commands

```bash
mix setup          # install deps, create+migrate+seed the DB
mix phx.server     # start (or: iex -S mix phx.server for a live shell)
mix test           # test suite
mix precommit      # compile --warnings-as-errors + deps.unlock --unused + format + test
```

See [Deployment](/deployment.md) for production commands and
[Testing](/testing.md) for the test approach.
