---
type: Diagram
title: Data model graph
description: Entity-relationship graph of the AttendanceTracker database — how participants, trainings, sessions, check-ins, memberships, events, photos, content, and logs relate.
tags: [ecto, schema, database, diagram, domain]
status: stable
generated: { by: human:gregorybleiker, at: 2026-11-15T00:00:00Z }
verified: { by: human:gregorybleiker, at: 2026-11-15T00:00:00Z }
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
  - id: training-member
    resource: ../../lib/attendancetracker/tracker/training_member.ex
    title: Training member join schema
    author: human:gregorybleiker
  - id: check-in
    resource: ../../lib/attendancetracker/tracker/check_in.ex
    title: Check-in schema
    author: human:gregorybleiker
  - id: event
    resource: ../../lib/attendancetracker/tracker/event.ex
    title: Event schema
    author: human:gregorybleiker
  - id: event-participant
    resource: ../../lib/attendancetracker/tracker/event_participant.ex
    title: Event participant join schema
    author: human:gregorybleiker
  - id: participant-photo
    resource: ../../lib/attendancetracker/tracker/participant_photo.ex
    title: Participant photo schema
    author: human:gregorybleiker
  - id: info
    resource: ../../lib/attendancetracker/tracker/info.ex
    title: Info slide schema
    author: human:gregorybleiker
  - id: setting
    resource: ../../lib/attendancetracker/tracker/setting.ex
    title: Setting schema
    author: human:gregorybleiker
  - id: logs
    resource: ../../lib/attendancetracker/logs/
    title: Audit and program log schemas
    author: human:gregorybleiker
---

# Overview

All application state lives in one SQLite database. There are two independent
"worlds": the **recurring training** world (members, dated sessions, check-ins)
and the **one-off event** world (hand-picked participants). A participant is the
hub both connect to; content (`infos`) and tunables (`settings`) plus the two
log tables hang off to the side.

# Entity-relationship graph

```mermaid
erDiagram
    PARTICIPANT ||--o| PARTICIPANT_PHOTO : "has one"
    PARTICIPANT ||--o{ CHECK_IN : "checks in"
    PARTICIPANT ||--o{ TRAINING_MEMBER : "is member of"
    PARTICIPANT ||--o{ EVENT_PARTICIPANT : "takes part in"

    TRAINING ||--o{ TRAINING_SESSION : "occurs as"
    TRAINING ||--o{ TRAINING_MEMBER : "has members"
    TRAINING_SESSION ||--o{ CHECK_IN : "records"

    EVENT ||--o{ EVENT_PARTICIPANT : "has participants"

    PARTICIPANT {
        int id PK
        string first_name
        string last_name
        string emergency_number
        date birthday
        string gender
        boolean active
        string source "local | webling"
    }
    PARTICIPANT_PHOTO {
        int id PK
        int participant_id FK "unique"
        binary data
        string content_type
    }
    TRAINING {
        int id PK
        string name "optional alias"
        int weekday "1..7 ISO"
        time starts_at
        time ends_at
    }
    TRAINING_SESSION {
        int id PK
        int training_id FK "nullable"
        date date "unique per training"
    }
    TRAINING_MEMBER {
        int id PK
        int training_id FK
        int participant_id FK
        boolean hidden "per-training hide"
    }
    CHECK_IN {
        int id PK
        int participant_id FK
        int training_session_id FK
    }
    EVENT {
        int id PK
        string name
        date date
        time starts_at
        time ends_at
    }
    EVENT_PARTICIPANT {
        int id PK
        int event_id FK
        int participant_id FK
    }
    INFO {
        int id PK
        string title
        string body "rich-text HTML"
        int position
        boolean active
    }
    SETTING {
        int id PK
        string key PK "unique"
        string value
    }
    AUDIT_LOG {
        int id PK
        string action
        int participant_id "loose reference"
        string participant_name
        int training_session_id "loose reference"
    }
    PROGRAM_LOG {
        int id PK
        string source
        string command
        string status
        string request
        string result
    }
```

`INFO`, `SETTING`, `AUDIT_LOG`, and `PROGRAM_LOG` have no foreign keys and are
drawn without edges: they are intentionally unconstrained (settings are a
generic key/value store; log rows keep a denormalised copy so they survive the
deletion of the participant or session they mention).

# Reading the graph

**Membership vs. attendance.** `TRAINING_MEMBER` and `CHECK_IN` answer
different questions. A *member* (imported from user management, or added on
first check-in) belongs to the training as a whole — a stable relationship, and
the one that carries the per-training `hidden` flag. A *check-in* is attendance
at one concrete dated `TRAINING_SESSION`, so the same participant has many
check-ins over time. The kiosk lists members by default and shows everyone under
"show all" (see [Web layer](/architecture/web-layer.md)).

**Recurring vs. one-off.** A `TRAINING` is a weekly rule (weekday + times); the
dated `TRAINING_SESSION` rows are generated on demand from that rule, so
`TRAINING_SESSION.training_id` is nullable — a session with no training is an
ad-hoc day. An `EVENT` skips the rule and the sessions entirely: it is a single
dated row whose participants are chosen explicitly through
`EVENT_PARTICIPANT`, the event-side twin of `TRAINING_MEMBER` (without a hidden
flag). See [Events](/architecture/events.md).

**Uniqueness.** The join tables are unique per pair
(`training_members(training_id, participant_id)`,
`event_participants(event_id, participant_id)`,
`check_ins(participant_id, training_session_id)`), one `TRAINING_SESSION` per
training per date, one `PARTICIPANT_PHOTO` per participant (stored in the
database, not on disk — see [Web layer](/architecture/web-layer.md)).

**Deletion.** Photos, memberships, check-ins, and event selections cascade from
their parent (`on_delete: :delete_all`), while the audit/program logs do not —
they keep their denormalised names so history is never lost.

See also [Domain model](/architecture/domain-model.md),
[Domain logic](/architecture/domain-logic.md), and the
[Directory map](/architecture/directory-map.md).
