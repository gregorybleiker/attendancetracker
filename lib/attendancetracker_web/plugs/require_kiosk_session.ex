defmodule AttendanceTrackerWeb.Plugs.RequireKioskSession do
  @moduledoc """
  Guards the check-in kiosk behind the session PIN.

  When no session PIN is configured the kiosk stays open. Otherwise clients
  without a valid kiosk session cookie are redirected to the session unlock
  page.
  """

  use AttendanceTrackerWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  alias AttendanceTracker.Tracker
  alias AttendanceTrackerWeb.KioskSession

  def init(opts), do: opts

  def call(conn, _opts) do
    if Tracker.session_pin_configured?() and not KioskSession.valid?(conn) do
      conn
      |> redirect(to: ~p"/start")
      |> halt()
    else
      conn
    end
  end
end
