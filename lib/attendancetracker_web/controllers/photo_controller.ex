defmodule AttendanceTrackerWeb.PhotoController do
  use AttendanceTrackerWeb, :controller

  alias AttendanceTracker.Tracker
  alias AttendanceTrackerWeb.KioskSession

  @cache_control "public, max-age=31536000, immutable"

  @doc """
  Serves a participant's photo.

  The `:version` in the URL is only used to bust the browser cache when a
  photo is replaced; the current bytes are always served.
  """
  def show(conn, %{"id" => id}) do
    case Tracker.get_participant_photo(id) do
      nil ->
        send_resp(conn, :not_found, "")

      photo ->
        if accessible?(conn) do
          conn
          |> put_resp_content_type(photo.content_type, nil)
          |> put_resp_header("cache-control", @cache_control)
          |> send_resp(200, photo.data)
        else
          send_resp(conn, :forbidden, "")
        end
    end
  end

  # Photos are shown on the kiosk (guarded by the session PIN) and in the
  # admin area (guarded by the admin PIN), so allow either.
  defp accessible?(conn) do
    get_session(conn, :admin_pin_ok) == true or
      not Tracker.session_pin_configured?() or
      KioskSession.valid?(conn)
  end
end
