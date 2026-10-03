---
type: Data Model
title: Domain model
description: Ecto schemas, changesets, and database constraints for trainings, sessions, participants, check-ins, and settings.
tags: [ecto, schema, changeset, database, domain]
status: stable
generated: { by: human:gregorybleiker, at: 2026-10-03T00:00:00Z }
verified: { by: human:gregorybleiker, at: 2026-10-03T00:00:00Z }
sources:
  - id: repo
    resource: https://github.com/gregorybleiker/attendancetracker
    title: AttendanceTracker source repository
    author: human:gregorybleiker
  - id: participant
    resource: ../../lib/attendancetracker/tracker/participant.ex
    title: Participant schema
    author: human:gregorybleiker
  - id: training
    resource: ../../lib/attendancetracker/tracker/training.ex
    title: Training schema
    author: human:gregorybleiker
  - id: training-session
    resource: ../../lib/attendancetracker/tracker/training_session.ex
    title: Training session schema
    author: human:gregorybleiker
  - id: check-in
    resource: ../../lib/attendancetracker/tracker/check_in.ex
    title: Check-in schema
    author: human:gregorybleiker
  - id: setting
    resource: ../../lib/attendancetracker/tracker/setting.ex
    title: Setting schema
    author: human:gregorybleiker
---

# Schemas and changesets

Schemas live in `lib/attendancetracker/tracker/*.ex`.

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

# Schemaless changesets

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

See also [Domain logic](/architecture/domain-logic.md) and the
[Web layer](/architecture/web-layer.md) forms section.
