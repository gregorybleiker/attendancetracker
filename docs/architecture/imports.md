---
type: Reference
title: Importing from user management
description: The Directory connector behaviour, the Webling implementation, and the source-agnostic import pipeline.
tags: [import, webling, req, behaviour, directory]
status: stable
generated: { by: human:gregorybleiker, at: 2026-10-03T00:00:00Z }
verified: { by: human:gregorybleiker, at: 2026-10-03T00:00:00Z }
sources:
  - id: repo
    resource: https://github.com/gregorybleiker/attendancetracker
    title: AttendanceTracker source repository
    author: human:gregorybleiker
  - id: directory
    resource: ../../lib/attendancetracker/directory.ex
    title: Directory context
    author: human:gregorybleiker
  - id: directory-source
    resource: ../../lib/attendancetracker/directory/source.ex
    title: Directory.Source behaviour
    author: human:gregorybleiker
  - id: directory-webling
    resource: ../../lib/attendancetracker/directory/webling.ex
    title: Webling connector
    author: human:gregorybleiker
---

# Design

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

See also [Merging duplicates](/architecture/duplicates.md) and
[Logs](/architecture/logs.md).
