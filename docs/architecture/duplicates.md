---
type: Reference
title: Merging duplicates
description: Detect participants with only a first or last name that likely duplicate a full-name participant, and merge them transactionally.
tags: [duplicates, merge, participants, transactions]
status: stable
generated: { by: human:gregorybleiker, at: 2026-10-03T00:00:00Z }
verified: { by: human:gregorybleiker, at: 2026-10-03T00:00:00Z }
sources:
  - id: repo
    resource: https://github.com/gregorybleiker/attendancetracker
    title: AttendanceTracker source repository
    author: human:gregorybleiker
  - id: duplicates
    resource: ../../lib/attendancetracker/duplicates.ex
    title: Duplicates context
    author: human:gregorybleiker
  - id: admin-duplicates-live
    resource: ../../lib/attendancetracker_web/live/admin_duplicates_live.ex
    title: AdminDuplicatesLive
    author: human:gregorybleiker
---

# Detection

Participants that ended up with only a first name or only a last name (e.g.
from an import) often duplicate a participant that has the full name.
`AttendanceTracker.Duplicates.list_candidates/0` pairs each such incomplete
participant with full-name participants whose first/last name matches its
single name (case-insensitive, exact or substring). `AdminDuplicatesLive`
(`/admin/duplicates`) lists the pairs; opening one shows a merge mask prefilled
with the first non-empty value of each field, which the admin can adjust.

# Merge

`Duplicates.merge/3` runs in a transaction: it applies the mask to the
survivor, moves the duplicate's check-ins over (on a session both attended the
survivor's check-in wins and the duplicate's is dropped), moves the duplicate's
photo when the survivor has none, flags the survivor as a Webling member if
either record was, deletes the duplicate, and writes an audit-log entry.

See also [Imports](/architecture/imports.md) and [Logs](/architecture/logs.md).
