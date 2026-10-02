// Service worker for AttendanceTracker.
//
// It only takes over static, cacheable assets (bundled CSS/JS, images, fonts)
// with a stale-while-revalidate strategy. Everything else — LiveView
// websockets, check-ins, API calls — is left to the network, so the app never
// serves stale or broken content.

const CACHE = "attendancetracker-v1"

const PRECACHE = [
  "/manifest.webmanifest",
  "/images/icon-192.png",
  "/images/icon-512.png",
  "/images/icon-maskable-512.png",
]

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches
      .open(CACHE)
      .then((cache) => cache.addAll(PRECACHE))
      .then(() => self.skipWaiting())
  )
})

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((keys) => Promise.all(keys.filter((key) => key !== CACHE).map((key) => caches.delete(key))))
      .then(() => self.clients.claim())
  )
})

const isCacheableAsset = (url) =>
  url.pathname.startsWith("/assets/") ||
  url.pathname.startsWith("/images/") ||
  url.pathname.startsWith("/fonts/")

self.addEventListener("fetch", (event) => {
  const request = event.request

  if (request.method !== "GET") return

  const url = new URL(request.url)

  if (url.origin !== self.location.origin) return
  if (!isCacheableAsset(url)) return

  event.respondWith(
    caches.open(CACHE).then((cache) =>
      cache.match(request).then((cached) => {
        const network = fetch(request)
          .then((response) => {
            if (response && response.status === 200 && response.type === "basic") {
              cache.put(request, response.clone())
            }
            return response
          })
          .catch(() => cached)

        return cached || network
      })
    )
  )
})