---
type: Reference
title: Localisation
description: Gettext English/German strings, per-process locale detection, translated Ecto errors, and date formatting.
tags: [i18n, gettext, locale, dates]
status: stable
generated: { by: human:gregorybleiker, at: 2026-10-03T00:00:00Z }
verified: { by: human:gregorybleiker, at: 2026-10-03T00:00:00Z }
sources:
  - id: repo
    resource: https://github.com/gregorybleiker/attendancetracker
    title: AttendanceTracker source repository
    author: human:gregorybleiker
  - id: gettext
    resource: ../../lib/attendancetracker_web/gettext.ex
    title: Gettext backend
    author: human:gregorybleiker
  - id: date-format
    resource: ../../lib/attendancetracker_web/date_format.ex
    title: DateFormat
    author: human:gregorybleiker
  - id: set-locale
    resource: ../../lib/attendancetracker_web/plugs/set_locale.ex
    title: SetLocale plug
    author: human:gregorybleiker
  - id: locale-controller
    resource: ../../lib/attendancetracker_web/controllers/locale_controller.ex
    title: Locale controller
    author: human:gregorybleiker
  - id: assign-admin-mode
    resource: ../../lib/attendancetracker_web/assign_admin_mode.ex
    title: AssignAdminMode on_mount hook
    author: human:gregorybleiker
---

# Locale handling

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
