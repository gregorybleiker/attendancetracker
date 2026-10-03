---
type: Reference
title: Directory map
description: Where each module, asset, and test lives in the AttendanceTracker repository.
tags: [architecture, layout, reference]
status: stable
generated: { by: human:gregorybleiker, at: 2026-10-03T00:00:00Z }
verified: { by: human:gregorybleiker, at: 2026-10-03T00:00:00Z }
sources:
  - id: repo
    resource: https://github.com/gregorybleiker/attendancetracker
    title: AttendanceTracker source repository
    author: human:gregorybleiker
---

# Layout

```
Dockerfile / compose.yml / Caddyfile / .env.example
                              # Production deployment: OTP release in Docker
                              # behind Caddy (TLS), SQLite (incl. photos) on a volume
docs/                         # This OKF knowledge bundle
lib/
  attendancetracker/
    tracker.ex                    # The Tracker context — all business logic entry points
    tracker/
      participant.ex              # Ecto schemas + changesets + pure domain logic
      participant_photo.ex        # Photo bytes + content type (BLOB)
      training.ex
      training_session.ex
      check_in.ex
      setting.ex
    directory.ex                  # Context: connector registry + import pipeline
    directory/
      source.ex                   # Behaviour for user-management connectors
      webling.ex                  # Webling connector (Req)
    logs.ex                       # Context: audit + program logs, retention settings
    logs/
      audit_log.ex                # Ecto schema (user interactions)
      program_log.ex              # Ecto schema (sync calls + results)
      pruner.ex                   # Periodic retention GenServer
    duplicates.ex                 # Detect + merge likely duplicate participants
  attendancetracker_web/
    router.ex                     # Routes (all LiveView)
    components/
      layouts.ex                  # App shell: navbar, theme toggle, flash group
      core_components.ex          # <.button>, <.input>, <.table>, <.icon>, …
      participant_components.ex   # Domain components: <.avatar>, <.source_badge>
    live/
      check_in_live.ex            # The kiosk: photo grid, check-in, PIN, camera
      login_live.ex               # Login page: PIN form POSTed to the session controller
      participant_live/           # Generated-style CRUD: index/form/show
      training_live/              # Weekly schedule config: index/form
      report_live.ex              # Year picker for the CSV attendance report
      admin_live.ex               # PIN-gated admin area
      admin_logs_live.ex          # Scrollable audit/program log viewer
      admin_duplicates_live.ex    # Detect + merge duplicate participants
    controllers/
      session_controller.ex       # Login: checks the PIN, marks the session
      report_controller.ex        # CSV download of a full year's attendance
      photo_controller.ex         # Serves /photos/:id/:version from the DB
      pwa_controller.ex           # Serves the web app manifest
      locale_controller.ex        # Stores the chosen language in the session
    plugs/
      require_admin_pin.ex        # Redirects to /login until the client logs in
      set_locale.ex               # Detects/remembers the locale
    gettext.ex                    # Gettext backend (en + de)
    locales.ex                    # The supported locales
priv/
  repo/migrations/                # Database history
  repo/seeds.exs                  # Demo data
  gettext/                        # en/de PO files (default + errors domains)
  static/
    manifest.webmanifest          # PWA manifest (served via PwaController)
    service-worker.js             # PWA service worker (static-asset cache)
    images/icon-*.png             # Install icons (192/512 + maskable + apple)
test/
  support/fixtures/               # TrackerFixtures — test data helpers
  attendancetracker/              # Context tests
  attendancetracker_web/live/     # LiveView tests
```

Related: [Overview](/overview.md), [Deployment](/deployment.md).
