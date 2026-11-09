# AttendanceTracker

Attendance kiosk for training sessions and events, built with Phoenix
(LiveView, Ecto and SQLite). Participants tap their photo to check in; admins
manage participants, trainings, events, reports, duplicate merging, and the
idle info screen behind a PIN.

Project documentation lives in the `docs/` OKF bundle — start at
[`docs/index.md`](docs/index.md).

## Local development

* Run `mix setup` to install and set up dependencies.
* Start the server with `mix phx.server` (or `iex -S mix phx.server`).

Then visit [`localhost:4000`](http://localhost:4000).

## Docker Compose (production)

The app ships as an OTP release in a container, behind Caddy, which terminates
TLS and fetches a Let's Encrypt certificate automatically. State — the SQLite
database including participant photos — lives in a volume or host directory, so
container rebuilds are lossless.

1. **Point the proxy at your domain.** Edit `caddy/Caddyfile`, replacing
   `localhost` with your domain, e.g.:

   ```caddyfile
   attendance.example.com {
       reverse_proxy app:4000
   }
   ```

2. **Create `.env`** next to `compose.yml` (it is gitignored, never commit it):

   ```bash
   cp .env.example .env
   ```

   Fill in:

   - `SECRET_KEY_BASE` — generate with `mix phx.gen.secret`
   - `PHX_HOST` — your domain from step 1
   - `DATABASE_DIR` — *optional*. By default the database lives in the
     Docker-managed `db-data` volume. Point this at a host directory (e.g.
     `/srv/attendancetracker/db`, must be writable by UID 65534) to keep it on
     the host instead.

3. **Start it:**

   ```bash
   docker compose up -d
   docker compose logs -f app   # watch it boot; Ctrl-C detaches
   ```

   The container runs `/app/bin/migrate && /app/bin/server`, so pending
   migrations apply automatically on every (re)start. Open
   `https://<your-domain>` and log in with the default admin PIN `1234`, then
   **change the PIN under Admin immediately**.

See [`docs/deployment.md`](docs/deployment.md) for image publishing, the update
workflow, and the `start.sh` Podman helper.

## Brute-force throttling

PIN entry is rate-limited **in the application**, so it works with the Compose
stack above (or any other deployment) with no extra configuration:

- Every PIN check counts *failures* per client IP over a five-minute sliding
  window, and blocks further attempts — even the correct PIN — once the limit
  is reached. Defaults are 5 attempts for the admin PIN and 10 for the kiosk
  session PIN, plus a higher aggregate cap (30 / 60) so a distributed attack
  from many addresses cannot search the small PIN space.
- All four entry points are covered: the `/login` and `/start` POSTs and the
  LiveView in-page unlock and check-out prompts. The latter travel over the
  websocket, which is why the enforcement lives in the app rather than at the
  proxy.
- A successful verification clears the per-IP counter only, so an attacker
  cannot reset the aggregate by interleaving guesses.

The policy constants (`@admin_limit`, `@session_limit`, `@window_ms`, and the
aggregate caps) live in
[`lib/attendancetracker/pin_throttle.ex`](lib/attendancetracker/pin_throttle.ex).
Note that the aggregate caps can be abused as a denial-of-service vector — an
attacker with many IPs could keep admins locked out for the window; remove the
global entries from `admin_keys/1` / `session_keys/1` if you would rather rely
on the per-IP limits alone.

The throttle keys on the real client IP, read from the rightmost
`x-forwarded-for` entry (proxies append the peer, so the leftmost entries are
spoofable). The bundled Caddy sets this header automatically; if you put
another proxy in front, make sure it sets or appends `x-forwarded-for`.

### Optional reverse-proxy backstop

The app already limits each attempt; a reverse proxy rate limit is a cheap
extra layer that stops request floods before they reach the app. For nginx:

```nginx
# http context
limit_req_zone $binary_remote_addr zone=attendance_pin:10m rate=30r/m;

server {
    # ...
    location ~ ^/(login|start)$ {
        limit_req zone=attendance_pin burst=10 nodelay;
        limit_req_status 429;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        # ...remaining proxy headers...
        proxy_pass http://app:4000;
    }
}
```

With Caddy, keep the default config (the in-app throttle is the enforcement
point) or add a rate-limit plugin if you want the same edge behaviour.
