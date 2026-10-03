# AttendanceTracker — Code Tour

An attendance kiosk for a club (e.g. judo): participants tap their photo on a
check-in screen, trainings recur weekly ("every Monday 19:00–21:30"), and an
admin PIN guards corrections. Built with Phoenix 1.8, LiveView, Ecto + SQLite.

This document walks the codebase layer by layer and calls out the important
**Elixir and Phoenix idioms** it relies on.

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

---

## 1. Directory map

```
Dockerfile / compose.yml / Caddyfile / DEPLOY.md / .env.example
                              # Production deployment: OTP release in Docker
                              # behind Caddy (TLS), SQLite (incl. photos) on a volume
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

**Idiom: contexts as boundaries.** Everything the web layer needs goes through
one module, `AttendanceTracker.Tracker`. LiveViews never call `Repo` directly.
This is the "context" concept from `phx.gen.context`: a plain module grouping
related operations — no framework magic, just a convention that keeps the web
and persistence layers decoupled.

---

## 2. The domain layer

### 2.1 Schemas and changesets (`tracker/*.ex`)

```elixir
schema "trainings" do
  field :name, :string
  field :weekday, :integer
  field :starts_at, :time
  field :ends_at, :time

  has_many :training_sessions, AttendanceTracker.Tracker.TrainingSession

  timestamps(type: :utc_datetime)
end
```

**Idiom: schema ≠ model.** An Ecto schema is just a typed struct plus a
*changeset* function. Validation is a pure data pipeline — nothing touches the
database until a `Repo` call:

```elixir
def changeset(training, attrs) do
  training
  |> cast(attrs, [:name, :weekday, :starts_at, :ends_at])  # whitelist + type-cast external input
  |> validate_required([:weekday, :starts_at, :ends_at])
  |> validate_inclusion(:weekday, 1..7)
  |> validate_ends_after_start()                            # custom, cross-field
end
```

Key points:

- **`cast/3` is the security boundary**: only listed fields are accepted from
  user input. `training_id` on `TrainingSession` is set programmatically,
  but still cast because sessions are only created server-side.
- **Custom validation** reads other fields with `get_field/2` (you must not
  pattern-match the changeset for values — changes wrap the data):

  ```elixir
  defp validate_ends_after_start(changeset) do
    starts_at = get_field(changeset, :starts_at)
    ends_at = get_field(changeset, :ends_at)

    if starts_at && ends_at && Time.compare(ends_at, starts_at) != :gt do
      add_error(changeset, :ends_at, "must be after the start time")
    else
      changeset
    end
  end
  ```

- **Database-backed constraints** are declared but enforced by SQLite;
  Ecto converts the violation into a changeset error:

  ```elixir
  |> unique_constraint(:date)                        # ad-hoc sessions (partial index)
  |> unique_constraint([:training_id, :date])    # one session per training per date
  ```

### 2.2 Pure domain logic lives in the schema module (`training.ex`)

The recurring-schedule math is side-effect free and trivially testable:

```elixir
def occurrence_on_or_before(%__MODULE__{weekday: weekday}, %Date{} = date) do
  days_back = rem(Date.day_of_week(date) - weekday + 7, 7)
  Date.add(date, -days_back)
end
```

**Idioms highlighted:**

- **Pattern matching in the argument list** destructures the struct — no
  accessor calls needed.
- **Standard-library date/time**: `Date.day_of_week/1` (ISO, Monday = 1, which
  is exactly what we store), `Time.compare/2` returning `:lt | :eq | :gt`,
  `NaiveDateTime` arithmetic. No date library dependency.
- **Guard-free arithmetic with `rem/2`** — the `+ 7` keeps the modulo positive.

### 2.3 Pattern matching as control flow (`Tracker.current_training/3`)

"Which training is current?" is expressed as **multiple function clauses** and
a clear priority chain:

```elixir
def current_training(trainings, date, time)

def current_training([], _date, _time), do: nil          # empty list clause

def current_training(trainings, %Date{} = date, %Time{} = time) do
  in_progress = ...   # Enum.max_by(& &1.starts_at, Time, fn -> nil end)
  upcoming_today = ... # Enum.min_by(& &1.starts_at, Time, fn -> nil end)

  in_progress ||
    upcoming_today ||
    Enum.max_by(trainings, &Training.most_recent_start(&1, date, time), NaiveDateTime)
end
```

**Idioms highlighted:**

- **Function head with docs, clauses below** — the `def f(...)` line without a
  body holds the `@doc`, clauses follow.
- **`Enum.max_by/4` with a module sorter** (`Time`, `NaiveDateTime`) — Elixir
  ≥ 1.14 lets you pass any module with `compare/2` instead of a comparator
  function, plus an **empty fallback** (`fn -> nil end`) instead of crashing on
  empty lists.
- **`||` chains** work because nil is falsy — a common, readable alternative to
  nested `case`.

### 2.4 Get-or-create and race safety (`Tracker.todays_session/0`)

```elixir
def todays_session do
  today = local_today()

  %TrainingSession{}
  |> TrainingSession.changeset(%{date: today})
  |> Repo.insert(on_conflict: :nothing)      # insert, ignore if it already exists

  Repo.one!(from s in TrainingSession,
    where: s.date == ^today and is_nil(s.training_id))
end
```

**Idiom: "upsert then read".** Two kiosks opening the app at the same time can
race to create today's session. The **unique index makes the race safe**:
the loser inserts nothing and both read the same row. The migration even keeps
ad-hoc sessions unique with a **partial index** (`where: "training_id IS
NULL"`), because SQLite treats `NULL`s as distinct in unique indexes.

**Idiom: `is_nil/1` in queries** — `Repo.get_by(training_id: nil)` is a
compile error; Ecto forces you to write the NULL-safe `is_nil/1` explicitly.

### 2.5 Shaped preloads (`Tracker.list_participants_with_check_ins/1`)

```elixir
check_in_query = from c in CheckIn, where: c.training_session_id == ^session.id

Repo.all(
  from p in Participant,
    where: p.active,
    order_by: p.name,
    preload: [check_ins: ^check_in_query]
)
```

**Idiom: preload a filtered association.** Each participant comes back with
`check_ins` containing *at most the one check-in for this session* — the
template can then just do `List.first(@participant.check_ins)` to know the
status. One query for participants + one for check-ins, no N+1, and no loading
of irrelevant history.

### 2.6 Schemaless changesets (`Tracker.change_admin_pin/1`)

Not every form maps to a table. The "change PIN" form validates a virtual
shape:

```elixir
types = %{new_pin: :string, new_pin_confirmation: :string}

{%{}, types}
|> Ecto.Changeset.cast(params, [:new_pin, :new_pin_confirmation])
|> Ecto.Changeset.validate_required([:new_pin])
|> Ecto.Changeset.validate_format(:new_pin, ~r/^\d{4,12}$/, message: "must be 4 to 12 digits")
|> Ecto.Changeset.validate_confirmation(:new_pin, message: "does not match")
```

**Idiom: `{data, types}` changesets.** You get casting, errors, and form
integration for free without a schema. `validate_confirmation/3` is built-in —
it compares `new_pin` with `new_pin_confirmation`.

The PIN itself lives in a generic key-value `settings` table, defaulting to
`"1234"` when no row exists (`admin_pin/0`), updated via
`Repo.insert_or_update/1` (upsert by primary key presence).

### 2.7 Erlang interop (`Tracker.local_today/0`)

```elixir
def local_today do
  {date, _time} = :calendar.local_time()
  Date.from_erl!(date)
end
```

**Idiom: zero-cost Erlang interop.** `:calendar.local_time/0` is the Erlang
standard library, called directly with atom module names. It gives us local
wall-clock time (training times are local!) without a timezone-database
dependency.

---

## 3. Real-time: Phoenix.PubSub (`tracker.ex`, kiosk section)

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

---

## 4. The web layer

### 4.1 Router with verified routes (`router.ex`)

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

### 4.2 LiveView lifecycle (`check_in_live.ex`)

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

### 4.3 Streams for collections

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

### 4.4 Forms: `to_form/2` everywhere

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

### 4.5 HEEx components

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

### 4.6 JS commands without JavaScript (`participant_live/index.ex`)

```heex
<.link phx-click={JS.push("delete", value: %{id: participant.id}) |> hide("##{id}")}
       data-confirm="Are you sure?">Delete</.link>
```

`Phoenix.LiveView.JS` composes **server-encoded client commands**: the row
hides instantly (optimistic UI) while the delete event round-trips. No custom
JS written.

### 4.7 Colocated hooks: the camera capture (`check_in_live.ex`)

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
  simpler than the upload pipeline (used elsewhere, see 4.8).
- **Cleanup in `destroyed()`** — the camera stream stops when the modal
  disappears from the DOM, regardless of how it closed.

### 4.8 Photo storage (`participant_live/form.ex`, `check_in_live.ex`)

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

### 4.9 CSV report (`report_live.ex` + `report_controller.ex`)

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

### 4.10 PIN-gated actions (undo check-in, `/admin`, admin mode on the kiosk)

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

### 4.11 Importing from user management (`directory.ex` + connectors)

The admin area can pull members from an external user-management system and
create participants for everyone enrolled in a training matching a training's
alias. The design deliberately separates the *connector* from the
*pipeline* so non-REST sources are possible:

- `AttendanceTracker.Directory.Source` is a **behaviour** (`@callback
  fetch_members/2`, `config_fields/0`, `label/0`). A connector only has to
  return normalised `%{first_name, last_name, phone}` maps.
- `AttendanceTracker.Directory.Webling` implements it with `Req`: it fetches all
  members (`GET /api/1/member?format=full`) and keeps those whose configurable
  `training_field` property contains the whole text of a training alias
  (case-insensitive substring match; the field may also be a multi-value list).
  Property names (`Vorname`, `Name`, `Telefon`) are configurable.
- `AttendanceTracker.Directory` is the context. It stores the selected connector
  and its (JSON) configuration in the settings table (`directory_source`,
  `directory_config`), builds a schemaless changeset for the admin form, and
  runs the source-agnostic `preview/0` → `import_members/1` flow: members are
  normalised, de-duplicated by name, and compared against existing participants
  (case/whitespace-insensitive). Missing ones are created and matched ones are
  updated, both flagged `source: "webling"`; the phone becomes the participant's
  `emergency_number`. The `source` field (`"local"` or `"webling"`, never cast
  from user input) drives the `<.source_badge>` shown in admin mode on the
  check-in grid.

`AdminLive` renders the connectors' `config_fields/0` dynamically: switching the
connector re-renders its fields, so adding a connector is "register the module
in `config :attendancetracker, :directory_sources`" with no template change.
The import is previewed first and confirmed in a second click, so the admin
sees exactly who would be created.

### 4.12 Installable PWA (`manifest.webmanifest`, `service-worker.js`)

The app ships a web app manifest (`priv/static/manifest.webmanifest`) with
192/512 PNG icons plus a maskable variant and `display: standalone`, so it can
be installed to a phone's home screen. The manifest is served by
`PwaController` rather than `Plug.Static` because production static paths are
digested and the manifest must keep its `application/manifest+json` content
type. The root layout links the manifest, `theme-color` and an Apple touch
icon.

A small service worker (`priv/static/service-worker.js`) is registered from
`app.js` in production builds only (esbuild's `NODE_ENV` gate). It
stale-while-revalidates the bundled CSS/JS, images and fonts, and deliberately
does **not** intercept LiveView websockets or check-in traffic — the kiosk
stays online-first, never serving stale data.

### 4.13 Localisation (Gettext, English + German)

Every user-facing string goes through Gettext (`AttendanceTrackerWeb.Gettext`,
messages in `priv/gettext/{en,de}/LC_MESSAGES`). The locale is per-process, so
it is set twice: by `Plugs.SetLocale` for the HTTP request (which also detects
`Accept-Language` on the first visit and remembers the choice in the session),
and by the `AssignAdminMode` `on_mount` hook for each LiveView process. The
navbar switcher links to `/locale/:locale`, which stores the choice and does a
full reload so every LiveView re-mounts in the new language.

`translate_error/1` looks up Ecto changeset messages in the `errors` domain, so
validation errors are translated too. Weekday and connector-field labels are
runtime strings, translated with `Gettext.dgettext/3`. Dates are rendered with
`AttendanceTrackerWeb.DateFormat` (`long_date/1`, `short_date/1`), which routes
month/weekday names through Gettext and reorders day/month via a translatable
format string (`%{month} %{day}` → `%{day}. %{month}`). CSV exports keep ISO
dates.

### 4.14 Logs (`logs.ex`, `logs/pruner.ex`)

Two database-backed log streams, both kept small by design:

- **Audit log** (`audit_logs`) records user interactions: `Tracker.check_in/2`
  and `check_out/2` append a row (`action`, participant id/name, session id).
- **Program log** (`program_logs`) records sync operations. The directory
  context logs every Webling fetch (the full call description and the number of
  members matched, or the error) and every import (`created`/`linked` counts).

`AttendanceTracker.Logs` writes entries, reads them newest-first, and trims each
stream to a maximum. Every insert opportunistically deletes the oldest rows
beyond the cap, and `AttendanceTracker.Logs.Pruner` (a `GenServer` in the app
supervision tree) additionally prunes on a timer. Both the maximum
(`log_max_entries`, default 10 000) and the interval
(`log_prune_interval_minutes`, default 60) are stored in the settings table and
editable in the admin area. `AdminLogsLive` (`/admin/logs`, reachable from the
admin panel) shows both streams in a tabbed, scrollable view (500 newest
entries each).

### 4.15 Merging duplicates (`duplicates.ex`)

Participants that ended up with only a first name or only a last name (e.g.
from an import) often duplicate a participant that has the full name.
`AttendanceTracker.Duplicates.list_candidates/0` pairs each such incomplete
participant with full-name participants whose first/last name matches its
single name (case-insensitive, exact or substring). `AdminDuplicatesLive`
(`/admin/duplicates`) lists the pairs; opening one shows a merge mask prefilled
with the first non-empty value of each field, which the admin can adjust.

`Duplicates.merge/3` runs in a transaction: it applies the mask to the
survivor, moves the duplicate's check-ins over (on a session both attended the
survivor's check-in wins and the duplicate's is dropped), moves the duplicate's
photo when the survivor has none, flags the survivor as a Webling member if
either record was, deletes the duplicate, and writes an audit-log entry.

---

## 5. End-to-end flows

**First connection (login):**
any guarded URL → `RequireAdminPin` plug → 302 to `/login` → PIN form POST →
`Tracker.admin_pin_valid?/1` → session marked → redirect to `/`. Wrong PIN →
flash error, back to `/login`. The kiosk `/` itself never requires a login.
Leaving admin mode works the same way in reverse: "Exit admin mode" →
`DELETE /logout` → session flag cleared → redirect to `/`.

**Check-in (multi-client):**
tap → `handle_event("check_in")` → `Tracker.check_in/2` (idempotent thanks to
the unique constraint — double taps are safe) → broadcast → every connected
kiosk (including the sender) receives `{:checked_in, …}` → `handle_info`
re-preloads that one participant and `stream_insert`s it → emerald card, count
+1.

**Auto-selecting the training:**
mount → `list_trainings/0` → `current_training/3` (in progress →
upcoming today → most recent) → `occurrence_on_or_before/2` gives the concrete
date → `session_for_training/2` get-or-creates the session. No trainings
configured → fall back to one ad-hoc session per day (`[]` clause).

**Switching training:**
`phx-change` → unsubscribe old PubSub topic, subscribe new → refetch →
`stream(..., reset: true)`. Check-ins stay separated per (training, date).

**Undo a check-in:**
tap checked-in card → PIN modal → `admin_pin_valid?/1` (fresh DB read, so PIN
changes apply instantly) → `Tracker.check_out/2` → `{:checked_out, …}`
broadcast → badge disappears everywhere.

**Camera photo (admin mode only):**
camera icon (rendered only when unlocked, entry guarded in `open_camera`) →
modal + hook starts webcam → capture → data URL →
`store_captured_photo/1` (a `with` chain: base64 decode → write file) →
`Tracker.update_participant/2` → `stream_insert` shows the new avatar.

---

## 6. Testing

- **`DataCase` / `ConnCase`** wrap every test in a SQL sandbox transaction —
  tests run concurrently (`max_cases`) and never see each other's data.
- **Fixtures** (`TrackerFixtures`) create valid entities with overridable
  defaults: `training_fixture(%{weekday: 3})`.
- **LiveView tests** drive the real process:

  ```elixir
  {:ok, view, _html} = live(conn, ~p"/")
  view |> element("#check-in-btn-#{participant.id}") |> render_click()
  view |> form("#pin-form", %{pin: "1234"}) |> render_submit()
  assert has_element?(view, "#checked-in-badge-#{participant.id}")
  ```

  Assertions target **element IDs**, not copy — resilient to rewording.
  `render_hook/3` simulates events pushed from JS hooks (the camera capture).
- **PubSub is tested through the real thing**: `Tracker.subscribe(session)` in
  the test process, then `assert_received {:checked_in, ^check_in}` — the `^`
  pin operator asserts on the *value*, not rebinding.
- Time-dependent logic is pure (`current_training(days, date, time)`), so
  tests pass explicit dates (`~D[2026-09-14]` is a Monday) instead of sleeping
  or mocking clocks.

---

## 7. Feature cheat sheet

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

## 8. Useful commands

```bash
mix setup          # install deps, create+migrate+seed the DB
mix phx.server     # start (or: iex -S mix phx.server for a live shell)
mix test           # test suite
mix precommit      # compile --warnings-as-errors + deps.unlock --unused + format + test
```
