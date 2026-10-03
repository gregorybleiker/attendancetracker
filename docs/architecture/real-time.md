---
type: Reference
title: Real-time with Phoenix.PubSub
description: How the Tracker context broadcasts check-in and check-out events so every connected kiosk stays in sync.
tags: [phoenix, pubsub, liveview, realtime]
status: stable
generated: { by: human:gregorybleiker, at: 2026-10-03T00:00:00Z }
verified: { by: human:gregorybleiker, at: 2026-10-03T00:00:00Z }
sources:
  - id: repo
    resource: https://github.com/gregorybleiker/attendancetracker
    title: AttendanceTracker source repository
    author: human:gregorybleiker
  - id: tracker-context
    resource: ../../lib/attendancetracker/tracker.ex
    title: Tracker context (PubSub broadcast/subscribe)
    author: human:gregorybleiker
---

# Broadcasting domain events

```elixir
def subscribe(%TrainingSession{} = session),
  do: Phoenix.PubSub.subscribe(@pubsub, topic(session.id))

def check_in(%Participant{} = participant, %TrainingSession{} = session) do
  # ...insert...
  {:ok, check_in} ->
    Phoenix.PubSub.broadcast(@pubsub, topic(session.id), {:checked_in, check_in})
```

**Idioms highlighted:**

- **Module attributes as constants**: `@pubsub AttendanceTracker.PubSub`.
- **Every LiveView is a separate process** (one per connected client). PubSub
  is how they stay in sync: the context broadcasts domain events
  (`{:checked_in, ...}`, `{:checked_out, ...}`), and each process updates its
  own UI in `handle_info/2`. The *context* owns the topic naming
  (`"training_session:#{id}"`) — callers never build topic strings.
- **The sender also receives the broadcast** — that's why `handle_event` for
  check-in doesn't touch the UI at all; the UI update happens in exactly one
  place: `handle_info`.

See also the [Web layer](/architecture/web-layer.md) lifecycle and
[End-to-end flows](/architecture/flows.md).
