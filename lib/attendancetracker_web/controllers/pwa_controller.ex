defmodule AttendanceTrackerWeb.PwaController do
  use AttendanceTrackerWeb, :controller

  @manifest_path "priv/static/manifest.webmanifest"

  @doc """
  Serves the web app manifest.

  It lives in `priv/static` but is served through the router rather than
  `Plug.Static` so it always gets the `application/manifest+json` content type,
  even in production where static paths are digested.
  """
  def manifest(conn, _params) do
    path = Application.app_dir(:attendancetracker, @manifest_path)

    conn
    |> put_resp_content_type("application/manifest+json", nil)
    |> put_resp_header("cache-control", "public, max-age=3600")
    |> send_file(200, path)
  end
end
