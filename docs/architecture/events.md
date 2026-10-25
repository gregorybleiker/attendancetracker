---
type: Reference
title: Events
description: One-off, single-day events with their own participant list, managed in their own admin tab.
tags: [events, participants, liveview]
status: stable
generated: { by: human:gregorybleiker, at: 2026-10-25T00:00:00Z }
verified: { by: human:gregorybleiker, at: 2026-10-25T00:00:00Z }
sources:
  - id: repo
    resource: https://github.com/gregorybleiker/attendancetracker
    title: AttendanceTracker source repository
    author: human:gregorybleiker
  - id: event
    resource: ../../lib/attendancetracker/tracker/event.ex
    title: Event schema
    author: human:gregorybleiker
  - id: event-live-index
    resource: ../../lib/attendancetracker_web/live/event_live/index.ex
    title: EventLive.Index
    author: human:gregorybleiker
  - id: event-live-show
    resource: ../../lib/attendancetracker_web/live/event_live/show.ex
    title: EventLive.Show (participant selection)
    author: human:gregorybleiker
---

# Overview

An **event** is like a `Training` but for a single day: it has a `name`, a
`date`, and optional `starts_at`/`ends_at` times. Where a training recurs
weekly (weekday) and drives the check-in kiosk, an event is a one-off
(competition, workshop, demo) with its own hand-picked participant list.

Events are managed in their own admin tab (`Admin mode → Events`, route
`/events`), separate from Trainings:

- `EventLive.Index` (`/events`) lists events chronologically and allows
  create/edit/delete; the **Participants** action opens the event.
- `EventLive.Form` (`/events/new`, `/events/:id/edit`) creates and edits the
  event. Saving a new event navigates straight to its participant picker.
- `EventLive.Show` (`/events/:id`) is the participant picker: it shows only
  the participants selected for this event by default, with a **Show all**
  toggle that reveals every active participant (each rendered as a tile,
  exactly like the check-in kiosk). Tapping toggles the selection for this
  event; deselecting someone in the selected-only view removes their tile.

There is also an **Event check-in** kiosk tab (`/event-check-in`,
`EventCheckInLive`, in the `:kiosk` `live_session` next to `/`): like the
check-in page but with an **events** dropdown instead of trainings. Selecting an
event renders its participant tiles; tapping toggles selection. It reuses
`ParticipantComponents.selectable_card/1`, the same tile used by the admin
picker.

Selection state is stored in the `event_participants` join table (the event
counterpart of `training_members`), so it is independent of trainings,
sessions and check-ins. `Tracker.list_participants_for_event/1` preloads each
participant's selection for the event, and `Tracker.add_event_participant/2` /
`remove_event_participant/2` toggle it idempotently.

See also [Domain model](/architecture/domain-model.md) and
[Web layer](/architecture/web-layer.md).
