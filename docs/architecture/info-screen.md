---
type: Reference
title: Info screen
description: Full-screen idle slideshow on the kiosk, driven by admin-authored rich-text slides.
tags: [kiosk, idle, slideshow, wysiwyg, liveview, hooks]
status: stable
generated: { by: human:gregorybleiker, at: 2026-11-08T00:00:00Z }
verified: { by: human:gregorybleiker, at: 2026-11-08T00:00:00Z }
sources:
  - id: repo
    resource: https://github.com/gregorybleiker/attendancetracker
    title: AttendanceTracker source repository
    author: human:gregorybleiker
  - id: info
    resource: ../../lib/attendancetracker/tracker/info.ex
    title: Info schema
    author: human:gregorybleiker
  - id: info-components
    resource: ../../lib/attendancetracker_web/components/info_components.ex
    title: Info mode + WYSIWYG components
    author: human:gregorybleiker
  - id: admin-infos-live
    resource: ../../lib/attendancetracker_web/live/admin_infos_live.ex
    title: Admin info-slide editor
    author: human:gregorybleiker
---

# Idle → full-screen info

When a kiosk screen (check-in and event check-in) goes untouched for
`idle_timeout_minutes` (default 10), it switches to a full-screen slideshow of
**info slides**. **Tapping anywhere on the screen** dismisses the overlay and
always returns to the main check-in screen (`/`) — so an info screen triggered
on the event check-in tab navigates back to check-in — resetting the idle
timer.

The behaviour lives entirely in the `.InfoMode` colocated hook printed by
`AttendanceTrackerWeb.InfoComponents.info_mode/1`, rendered by
`CheckInLive`/`EventCheckInLive`. The hook listens on `window` for pointer/key
activity, arms a timeout, and on expiry reveals `#info-mode` and starts a
rotation timer. Slides are the `[data-info-slide]` elements already rendered by
the server (the overlay uses `phx-update="ignore"`).

The left flyout menu also offers a **Show info** button (`#show-info-mode-btn`,
an entry in `Layouts.app`'s `<:menu>` slot) that starts the slideshow on demand
without waiting for the idle timeout; it dispatches `info-mode:show` at the
overlay via `JS.dispatch/2`.

# Rotation

Slides rotate every `info_rotation_seconds` (default 15), configurable
alongside the idle timeout on the admin page. With a single slide the hook
shows it without a timer; with none it simply re-arms.

# Content and the WYSIWYG editor

Slides are `AttendanceTracker.Tracker.Info` rows (`title`, rich-text `body`,
`position`, `active`), managed at `/admin/infos` (`AdminInfosLive`) — an
admin-mode item in the left flyout menu, alongside the other admin links. Only
`active` rows, ordered by `position`, are shown.

The `body` is authored with `InfoComponents.wysiwyg/1`: a contenteditable area
plus a small toolbar (bold/italic/underline, headings, lists, links, clear)
wired by the `.WysiwygEditor` colocated hook using `document.execCommand`. The
hook mirrors the HTML into a visually hidden `<textarea>` so it submits with
the normal `Phoenix.Component.form/1`. Stored HTML is rendered with
`Phoenix.HTML.raw/1`; it is admin-authored (PIN-gated), not visitor input.

See also [Web layer](/architecture/web-layer.md) and
[Domain model](/architecture/domain-model.md).
