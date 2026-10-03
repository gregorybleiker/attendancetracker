---
type: Playbook
title: Testing
description: How the test suite is structured with the SQL sandbox, fixtures, LiveView tests, and PubSub assertions.
tags: [testing, exunit, liveview, sandbox]
status: stable
generated: { by: human:gregorybleiker, at: 2026-10-03T00:00:00Z }
verified: { by: human:gregorybleiker, at: 2026-10-03T00:00:00Z }
sources:
  - id: repo
    resource: https://github.com/gregorybleiker/attendancetracker
    title: AttendanceTracker source repository
    author: human:gregorybleiker
  - id: data-case
    resource: ../test/support/data_case.ex
    title: DataCase
    author: human:gregorybleiker
  - id: conn-case
    resource: ../test/support/conn_case.ex
    title: ConnCase
    author: human:gregorybleiker
  - id: tracker-fixtures
    resource: ../test/support/fixtures/tracker_fixtures.ex
    title: TrackerFixtures
    author: human:gregorybleiker
---

# Approach

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

See the [Commands](/commands.md) reference for `mix test`.
