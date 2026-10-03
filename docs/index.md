---
okf_version: "0.2"
---

# AttendanceTracker Knowledge Base

An [Open Knowledge Format](https://github.com/GoogleCloudPlatform/open-knowledge-format)
v0.2 bundle documenting the AttendanceTracker attendance kiosk (Phoenix 1.8,
LiveView, Ecto + SQLite). It supersedes the former repository-root
`ARCHITECTURE.md` and `DEPLOY.md`.

# Overview

* [Overview](/overview.md) - What the app is, its runtime layers, the context boundary, and the directory map.
* [Directory map](/architecture/directory-map.md) - Where everything lives in `lib/`, `priv/`, and `test/`.

# Architecture

* [Domain model](/architecture/domain-model.md) - Ecto schemas, changesets, and database constraints.
* [Domain logic](/architecture/domain-logic.md) - Pure schedule math, pattern matching as control flow, race-safe upserts, shaped preloads, Erlang interop.
* [Real-time](/architecture/real-time.md) - Phoenix.PubSub fan-out between connected kiosks.
* [Web layer](/architecture/web-layer.md) - Router, LiveView lifecycle, streams, forms, components, JS commands, colocated hooks, photo storage, CSV report, PIN gating.
* [Imports](/architecture/imports.md) - The Webling connector and the source-agnostic import pipeline.
* [PWA](/architecture/pwa.md) - Web app manifest and service worker.
* [Localisation](/architecture/localization.md) - Gettext English/German and locale detection.
* [Logs](/architecture/logs.md) - Audit and program logs with periodic retention.
* [Merging duplicates](/architecture/duplicates.md) - Detect and merge likely duplicate participants.
* [Elixir/Phoenix idioms](/architecture/idioms.md) - Feature-to-location cheat sheet.
* [End-to-end flows](/architecture/flows.md) - Login, check-in, training selection, undo, camera capture.

# Operations

* [Testing](/testing.md) - Sandbox, fixtures, LiveView tests, PubSub assertions.
* [Commands](/commands.md) - Common `mix` tasks.
* [Deployment](/deployment.md) - OTP release in Docker behind Caddy.
* [Backups](/backups.md) - SQLite-safe snapshots.
* [Troubleshooting](/troubleshooting.md) - Boot, permissions, HTTPS, websockets.

# History

* [Log](/log.md) - Chronological changes to this bundle.
