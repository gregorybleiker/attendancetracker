---
type: Reference
title: Web layer
description: Router, LiveView lifecycle, streams, forms, components, JS commands, colocated hooks, photo storage, CSV report, and PIN-gated actions.
tags: [phoenix, liveview, heex, components, forms, uploads]
status: stable
generated: { by: human:gregorybleiker, at: 2026-10-03T00:00:00Z }
verified: { by: human:gregorybleiker, at: 2026-10-03T00:00:00Z }
sources:
  - id: repo
    resource: https://github.com/gregorybleiker/attendancetracker
    title: AttendanceTracker source repository
    author: human:gregorybleiker
  - id: router
    resource: ../../lib/attendancetracker_web/router.ex
    title: Router
    author: human:gregorybleiker
  - id: check-in-live
    resource: ../../lib/attendancetracker_web/live/check_in_live.ex
    title: Check-in kiosk LiveView
    author: human:gregorybleiker
  - id: core-components
    resource: ../../lib/attendancetracker_web/components/core_components.ex
    title: Core components
    author: human:gregorybleiker
  - id: participant-components
    resource: ../../lib/attendancetracker_web/components/participant_components.ex
    title: Participant components
    author: human:gregorybleiker
  - id: report-controller
    resource: ../../lib/attendancetracker_web/controllers/report_controller.ex
    title: CSV report controller
    author: human:gregorybleiker
  - id: photo-controller
    resource: ../../lib/attendancetracker_web/controllers/photo_controller.ex
    title: Photo controller
    author: human:gregorybleiker
  - id: session-controller
    resource: ../../lib/attendancetracker_web/controllers/session_controller.ex
    title: Session controller (login)
    author: human:gregorybleiker
  - id: require-admin-pin
    resource: ../../lib/attendancetracker_web/plugs/require_admin_pin.ex
    title: RequireAdminPin plug
    author: human:gregorybleiker
---

# Router with verified routes

```elixir
live "/", CheckInLive, :index
live "/training/:id/edit", TrainingLive.Form, :edit
```

In templates, paths are written as `~p"/training"` — **verified routes**:
the compiler checks them against the router, so a typo is a compile error, not
a 404 at runtime.

**Everything except the check-in kiosk sits behind a login guard.** The
`:authenticated` pipeline runs `Plugs.RequireAdminPin`, which redirects to
`/login` until the client has entered the admin PIN once
(`get_session(conn, :admin_pin_ok)`). The kiosk `/` (so participants can tap
their photos), `/login` itself — a LiveView form and the `POST /login` it
submits to `SessionController` — are exempt.

# LiveView lifecycle

A LiveView is an Elixir process holding state in `socket.assigns`. Three
callbacks matter here:

```
mount/3        ── runs TWICE: once for the initial HTTP render, once when the
                  WebSocket connects → side effects are guarded:
                  `if connected?(socket), do: Tracker.subscribe(session)`

handle_event/3 ── user interactions ("check_in", "select_training", ...)

handle_info/3  ── PubSub messages from other clients
```

**Idiom: immutability means rebinding.** `assign/3` returns a *new* socket;
you always thread it through pipelines and return it:

```elixir
{:noreply,
 socket
 |> assign(:checked_in_count, Tracker.check_in_count(session))
 |> stream(:participants, participants, reset: true)}
```

# Streams for collections

Participants are assigned as a **stream**, not a list:

```elixir
|> stream(:participants, participants)                 # initial
|> stream_insert(:participants, participant)           # one changed item
|> stream(:participants, participants, reset: true)    # full replace
```

```heex
<div id="participants" phx-update="stream">
  <div :for={{id, participant} <- @streams.participants} id={id}>
    <.participant_card participant={participant} />
  </div>
</div>
```

**Why:** streams keep only DOM IDs server-side — memory stays flat for large
collections, and updates are surgical DOM patches.

**Consequences (and how the code handles them):**

- *Streams are not enumerable* → counts are separate assigns
  (`@checked_in_count`), incremented/decremented in `handle_info`.
- *No empty state* → pure-CSS trick: a `.hidden only:block` div that only
  displays when it's the sole child of the grid.
- *Changing collections* (switching training) → refetch + `reset: true`.

# Forms: `to_form/2` everywhere

Two flavors are used:

**Changeset-backed** (training form):

```elixir
assign(:form, to_form(Tracker.change_training(training)))
```

```heex
<.form for={@form} id="training-form" phx-change="validate" phx-submit="save">
  <.input field={@form[:weekday]} type="select" options={Training.weekday_options()} />
```

Validation on every change (`phx-change`) re-assigns
`to_form(changeset, action: :validate)` — errors only render once the changeset
has an **action**, which is how a fresh form shows no errors.

**Param-map-backed** (PIN prompts, training selector):

```elixir
to_form(%{"pin" => ""}, errors: [pin: {"Wrong PIN", []}])
```

No changeset needed — server-pushed errors are passed via the `:errors` option.
Used for the unlock forms where validation is a single DB read
(`Tracker.admin_pin_valid?/1`).

# HEEx components

**Function components with typed attrs** (`participant_components.ex`):

```elixir
attr :participant, :map, required: true
attr :dim, :boolean, default: false, doc: "render the avatar greyed out"

def avatar(assigns) do ... end
```

Compile-time-checked, self-documenting, and reusable across LiveViews
(`import AttendanceTrackerWeb.ParticipantComponents`).

**Slots** (`core_components.ex` `<.header>`):

```heex
<.header>
  Training
  <:subtitle>Configure the weekly training schedule…</:subtitle>
  <:actions><.button variant="primary" …>New training</.button></:actions>
</.header>
```

**Class lists with conditionals** — HEEx attributes accept lists; `&&` picks a
class only when truthy:

```elixir
class={[
  "group relative flex w-full cursor-pointer …",
  if(checked_in, do: "border-emerald-500 …", else: "border-base-300 …")
]}
```

**Directives**: `:if` (conditional render), `:for` (comprehension),
`phx-value-id` (event payload), `phx-click` (event binding). Text uses
`{@assign}`; blocks use `<%= if … do %>`.

# JS commands without JavaScript

```heex
<.link phx-click={JS.push("delete", value: %{id: participant.id}) |> hide("##{id}")}
       data-confirm="Are you sure?">Delete</.link>
```

`Phoenix.LiveView.JS` composes **server-encoded client commands**: the row
hides instantly (optimistic UI) while the delete event round-trips. No custom
JS written.

# Colocated hooks: the camera capture

When you *do* need JavaScript (webcam access), Phoenix 1.8 colocated hooks keep
it next to the markup:

```heex
<div id="camera-capture" phx-hook=".CameraCapture" phx-update="ignore">
  <video autoplay playsinline muted …></video>
  <button data-capture>Capture photo</button>
</div>

<script :type={Phoenix.LiveView.ColocatedHook} name=".CameraCapture">
  export default {
    async mounted() { /* getUserMedia, wire up [data-capture] */ },
    destroyed() { this.stream?.getTracks().forEach(t => t.stop()) }
  }
</script>
```

**Idioms highlighted:**

- **`phx-update="ignore"` + unique DOM id** — mandatory when a hook manages its
  own DOM (the `<video>` stream); LiveView skips patching that subtree.
- **Colocated hook naming** starts with `.` (`.CameraCapture`); the compiler
  extracts it into the app bundle (`app.js` imports
  `phoenix-colocated/attendancetracker`).
- **Client → server events** with `this.pushEvent("captured_photo", …)`; the
  captured JPEG travels as a data URL — for a downscaled snapshot this is
  simpler than the upload pipeline (used elsewhere, see below).
- **Cleanup in `destroyed()`** — the camera stream stops when the modal
  disappears from the DOM, regardless of how it closed.

# Photo storage

Photos are small (max 5 MB via `allow_upload/3`, and webcam snapshots are
downscaled) and there is one per participant, so they live in the database as
BLOBs instead of on disk. The other photo path uses LiveView's built-in upload
machinery:

```elixir
|> allow_upload(:photo, accept: ~w(.jpg .jpeg .png .webp), max_entries: 1, max_file_size: 5_000_000)
```

`consume_uploaded_entries/3` runs at save time and `File.read/1`s the temp file;
`Tracker.put_participant_photo/3` upserts a `participant_photos` row (`:binary`
`data` + `content_type`, unique on `participant_id`, `on_delete: :delete_all`).
Drag-and-drop, progress, and validation come free.

Participant queries never load the bytes: the context left-joins the photo and
selects only the lightweight `has_photo` / `photo_updated_at` virtual fields, so
the kiosk's participant stream stays small. `PhotoController.show/2` serves the
bytes from `/photos/:id/:version`; the `updated_at` in the URL busts the browser
cache when a photo is replaced (`cache-control: public, max-age=…, immutable`).
The webcam path (`check_in_live.ex`) feeds the same context function by decoding
the base64 JPEG data URL.

# CSV report

Reporting follows the login pattern: a LiveView renders the UI, a controller
does the non-LiveView work. `ReportLive` offers a year select (years derived
from the sessions in the DB via `Tracker.list_session_years/0`); the form is a
*regular* GET form to `/reporting/download?year=…` — LiveView can't send file
downloads. `ReportController.download/2` fetches
`Tracker.list_sessions_for_report(year)` (one query, shaped preloads:
`check_ins: :participant` in check-in order) and replies with
`send_resp/3`, a `content-disposition: attachment` header, and a
`text/csv` body — one file per full year, one row per session:
`training,date,participants` (names joined with `"; "`), RFC-4180 quoting
plus a UTF-8 BOM so spreadsheet tools pick the right encoding.

# PIN-gated actions

The check-out flow shows how LiveView state machines read:

```elixir
def handle_event("prompt_check_out", %{"id" => id}, socket) do
  if socket.assigns.admin_unlocked do
    check_out_participant(socket, id)               # already unlocked this session
  else
    {:noreply, assign(socket, :toggle_participant, Tracker.get_participant!(id))}
  end                                                # → modal renders (:if)
end
```

The modal is plain markup toggled by `:if={@toggle_participant}` — modals need
no JS framework in LiveView, just assigns. `AdminLive` uses the same pattern:
one boolean (`@unlocked`) swaps the whole page between PIN prompt and settings.

**Admin mode on the kiosk.** The same `@admin_unlocked` assign doubles as the
kiosk's admin mode: it starts from the session flag
(`lv_session["admin_pin_ok"]` in `mount/3`, set by the "Admin mode" menu item
→ `/login` → `SessionController`) and is also set by the in-page PIN unlock
above. Only in admin mode do the participant cards show the camera button and
the emergency number; `open_camera` additionally ignores its event when not
unlocked. Because those elements live inside the stream, flipping the assign
in `submit_pin` re-streams the participants (`stream(..., reset: true)`) so the
already rendered cards pick up the new UI.

**Navbar toggle and logout.** A global `on_mount` hook
(`AssignAdminMode`, attached in the `live_view` quote in `my_app_web.ex`)
exposes the session flag to every LiveView as `@admin_mode`, and each
template passes it to `<Layouts.app>`. The navbar shows "Admin mode" (→
`/login`) when logged out and "Exit admin mode" when logged in — the latter
is a `DELETE /logout` link (`SessionController.delete/2` drops
`:admin_pin_ok` from the session and redirects to `/`). Note the two assigns
stay separate on purpose: the transient in-page PIN unlock reveals the kiosk
cards via `@admin_unlocked` but does not flip the session-backed `@admin_mode`
in the navbar.

**Logging in (first connection).** Before any of that, every new client must
enter the admin PIN once. `LoginLive` renders a plain `<.form
action={~p"/login"} method="post">` — a *regular* HTTP POST, not a LiveView
event, because only a controller can write the session. On success,
`SessionController.create/2` renews the session and marks it
(`put_session(:admin_pin_ok, true)`); on failure it redirects back with a
flash error. The flag lives in the session cookie, so the login survives page
reloads and navigation between LiveViews.

See also [Real-time](/architecture/real-time.md),
[Imports](/architecture/imports.md), and [End-to-end flows](/architecture/flows.md).
