# Architecture

Code tour of AttendanceTracker, split into concepts. See also the bundle
[Overview](/overview.md).

# Domain

* [Domain model](/architecture/domain-model.md) - Ecto schemas, changesets, and database constraints.
* [Domain logic](/architecture/domain-logic.md) - Pure schedule math, pattern matching, race-safe upserts, shaped preloads, Erlang interop.

# Runtime

* [Real-time](/architecture/real-time.md) - Phoenix.PubSub fan-out between connected kiosks.
* [Web layer](/architecture/web-layer.md) - Router, LiveView lifecycle, streams, forms, components, JS commands, hooks, photos, CSV, PIN gating.
* [Imports](/architecture/imports.md) - The Webling connector and the import pipeline.
* [PWA](/architecture/pwa.md) - Web app manifest and service worker.
* [Localisation](/architecture/localization.md) - Gettext English/German and locale detection.
* [Logs](/architecture/logs.md) - Audit and program logs with retention.
* [Merging duplicates](/architecture/duplicates.md) - Detect and merge likely duplicate participants.

# Reference

* [Elixir/Phoenix idioms](/architecture/idioms.md) - Feature-to-location cheat sheet.
* [End-to-end flows](/architecture/flows.md) - Login, check-in, training selection, undo, camera capture.
* [Directory map](/architecture/directory-map.md) - Where everything lives.
