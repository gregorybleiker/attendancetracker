---
type: Reference
title: End-to-end flows
description: Step-by-step flows for login, check-in across clients, training selection, switching, undo, and camera capture.
tags: [flows, liveview, pubsub, kiosk]
status: stable
generated: { by: human:gregorybleiker, at: 2026-10-03T00:00:00Z }
verified: { by: human:gregorybleiker, at: 2026-10-03T00:00:00Z }
sources:
  - id: repo
    resource: https://github.com/gregorybleiker/attendancetracker
    title: AttendanceTracker source repository
    author: human:gregorybleiker
  - id: check-in-live
    resource: ../../lib/attendancetracker_web/live/check_in_live.ex
    title: Check-in kiosk LiveView
    author: human:gregorybleiker
  - id: session-controller
    resource: ../../lib/attendancetracker_web/controllers/session_controller.ex
    title: Session controller (login)
    author: human:gregorybleiker
---

# First connection (login)

any guarded URL → `RequireAdminPin` plug → 302 to `/login` → PIN form POST →
`Tracker.admin_pin_valid?/1` → session marked → redirect to `/`. Wrong PIN →
flash error, back to `/login`. The kiosk `/` itself never requires a login.
Leaving admin mode works the same way in reverse: "Exit admin mode" →
`DELETE /logout` → session flag cleared → redirect to `/`.

# Check-in (multi-client)

tap → `handle_event("check_in")` → `Tracker.check_in/2` (idempotent thanks to
the unique constraint — double taps are safe) → broadcast → every connected
kiosk (including the sender) receives `{:checked_in, …}` → `handle_info`
re-preloads that one participant and `stream_insert`s it → emerald card, count
+1.

# Auto-selecting the training

mount → `list_trainings/0` → `current_training/3` (in progress →
upcoming today → most recent) → `occurrence_on_or_before/2` gives the concrete
date → `session_for_training/2` get-or-creates the session. No trainings
configured → fall back to one ad-hoc session per day (`[]` clause).

# Switching training

`phx-change` → unsubscribe old PubSub topic, subscribe new → refetch →
`stream(..., reset: true)`. Check-ins stay separated per (training, date).

# Undo a check-in

tap checked-in card → PIN modal → `admin_pin_valid?/1` (fresh DB read, so PIN
changes apply instantly) → `Tracker.check_out/2` → `{:checked_out, …}`
broadcast → badge disappears everywhere.

# Camera photo (admin mode only)

camera icon (rendered only when unlocked, entry guarded in `open_camera`) →
modal + hook starts webcam → capture → data URL →
`store_captured_photo/1` (a `with` chain: base64 decode → write file) →
`Tracker.update_participant/2` → `stream_insert` shows the new avatar.

See also [Real-time](/architecture/real-time.md) and the
[Web layer](/architecture/web-layer.md).
