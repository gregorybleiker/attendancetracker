defmodule AttendanceTrackerWeb.Plugs.RequireKioskSession do
  @moduledoc """
  Guards the check-in kiosk behind the session PIN on full page loads.

  When no session PIN is configured the kiosk stays open. Otherwise clients
  without a valid kiosk session cookie are redirected to the session unlock
  page. When the cookie is valid, its token is mirrored into the Plug session
  so `AttendanceTrackerWeb.KioskSessionHook` can enforce the same check on
  WebSocket connects and LiveView live navigation (which do not run plugs).
  """

  use AttendanceTrackerWeb, :verified_routes

  import Plug.Conn, only: [halt: 1, put_session: 3]
  import Phoenix.Controller, only: [redirect: 2]

  alias AttendanceTracker.Tracker
  alias AttendanceTrackerWeb.KioskSession

  def init(opts), do: opts

  def call(conn, _opts) do
    cond do
      not Tracker.session_pin_configured?() ->
        conn

      KioskSession.valid?(conn) ->
        put_session(conn, :kiosk_token, KioskSession.token(conn))

      true ->
        conn
        |> redirect(to: ~p"/start")
        |> halt()
    end
  end
end
