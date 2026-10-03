---
type: Reference
title: Domain logic
description: Pure schedule math, pattern matching as control flow, race-safe get-or-create, shaped preloads, and Erlang interop in the Tracker context.
tags: [elixir, ecto, domain, patterns]
status: stable
generated: { by: human:gregorybleiker, at: 2026-10-03T00:00:00Z }
verified: { by: human:gregorybleiker, at: 2026-10-03T00:00:00Z }
sources:
  - id: repo
    resource: https://github.com/gregorybleiker/attendancetracker
    title: AttendanceTracker source repository
    author: human:gregorybleiker
  - id: training
    resource: ../../lib/attendancetracker/tracker/training.ex
    title: Training schema and pure schedule math
    author: human:gregorybleiker
  - id: tracker-context
    resource: ../../lib/attendancetracker/tracker.ex
    title: Tracker context
    author: human:gregorybleiker
---

# Pure domain logic lives in the schema module

The recurring-schedule math (`training.ex`) is side-effect free and trivially
testable:

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

# Pattern matching as control flow

"Which training is current?" (`Tracker.current_training/3`) is expressed as
**multiple function clauses** and a clear priority chain:

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

# Get-or-create and race safety

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

# Shaped preloads

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

# Erlang interop

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

See also [Domain model](/architecture/domain-model.md) and
[End-to-end flows](/architecture/flows.md).
