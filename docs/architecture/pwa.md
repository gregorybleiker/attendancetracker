---
type: Reference
title: Installable PWA
description: Web app manifest and service worker that make the kiosk installable while staying online-first.
tags: [pwa, manifest, service-worker, static]
status: stable
generated: { by: human:gregorybleiker, at: 2026-10-03T00:00:00Z }
verified: { by: human:gregorybleiker, at: 2026-10-03T00:00:00Z }
sources:
  - id: repo
    resource: https://github.com/gregorybleiker/attendancetracker
    title: AttendanceTracker source repository
    author: human:gregorybleiker
  - id: manifest
    resource: ../../priv/static/manifest.webmanifest
    title: Web app manifest
    author: human:gregorybleiker
  - id: service-worker
    resource: ../../priv/static/service-worker.js
    title: Service worker
    author: human:gregorybleiker
  - id: pwa-controller
    resource: ../../lib/attendancetracker_web/controllers/pwa_controller.ex
    title: PWA controller
    author: human:gregorybleiker
---

# Manifest

The app ships a web app manifest (`priv/static/manifest.webmanifest`) with
192/512 PNG icons plus a maskable variant and `display: standalone`, so it can
be installed to a phone's home screen. The manifest is served by
`PwaController` rather than `Plug.Static` because production static paths are
digested and the manifest must keep its `application/manifest+json` content
type. The root layout links the manifest, `theme-color` and an Apple touch
icon.

# Service worker

A small service worker (`priv/static/service-worker.js`) is registered from
`app.js` in production builds only (esbuild's `NODE_ENV` gate). It
stale-while-revalidates the bundled CSS/JS, images and fonts, and deliberately
does **not** intercept LiveView websockets or check-in traffic — the kiosk
stays online-first, never serving stale data.
