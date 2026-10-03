---
type: Reference
title: Elixir/Phoenix idioms
description: Cheat sheet mapping each Elixir and Phoenix feature used in the app to where it shows up.
tags: [elixir, phoenix, idioms, cheat-sheet]
status: stable
generated: { by: human:gregorybleiker, at: 2026-10-03T00:00:00Z }
verified: { by: human:gregorybleiker, at: 2026-10-03T00:00:00Z }
sources:
  - id: repo
    resource: https://github.com/gregorybleiker/attendancetracker
    title: AttendanceTracker source repository
    author: human:gregorybleiker
---

# Feature cheat sheet

| Elixir / Phoenix feature | Where it shows up |
|---|---|
| Pipe operator `\|>` | changeset pipelines, socket threading, query building |
| Pattern matching & function clauses | `current_training/3`, `store_captured_photo/1` (`"data:image/jpeg;base64," <> base64` matches the string prefix!) |
| `with` (happy-path chaining) | `store_captured_photo/1` |
| Immutability / rebinding | `socket = socket \|> assign(...) \|> stream(...)` |
| Module attributes as constants | `@pubsub`, `@default_admin_pin`, `@weekday_names` |
| Erlang interop | `:calendar.local_time()` |
| Ecto changesets & constraints | all schemas; unique + partial indexes in migrations |
| Filtered preloads | `list_participants_with_check_ins/1` |
| Upserts | `on_conflict: :nothing` (sessions), `insert_or_update` (PIN), photo replace |
| Schemaless changesets | `change_admin_pin/1` |
| Phoenix.PubSub | check-in/check-out fan-out to all kiosks |
| Plug + session guard | `Plugs.RequireAdminPin` + `SessionController` (login) |
| Binary download | `send_resp/3` + `content-disposition` (CSV report) |
| Binary image response | `PhotoController` (`send_resp/3` + cache headers) |
| Behaviour + registry plugin point | `Directory.Source` connectors |
| HTTP client (`Req`) | Webling member import |
| Gettext i18n + locale plug/hook | whole UI (en/de) |
| Dual logs + periodic retention | `Logs` context + `Logs.Pruner` |
| LiveView streams | participant grid (`reset: true` on training switch) |
| `connected?/1` mount guard | PubSub subscribe only on the live socket |
| Verified routes `~p` | every link/navigate |
| `to_form/2` + `<.form>` + `<.input>` | all forms (changeset- and map-backed) |
| Function components, attrs, slots | `avatar/1`, `header`, `core_components` |
| `Phoenix.LiveView.JS` commands | optimistic row hide on delete |
| Colocated JS hooks + `phx-update="ignore"` | webcam capture |
| LiveView uploads | participant photo form |
| HEEx `:if` / `:for` / class lists | all templates |

See the [Commands](/commands.md) reference for the `mix` tasks used in development.
