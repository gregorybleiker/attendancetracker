defmodule AttendanceTrackerWeb.KioskSessionHook do
  @moduledoc """
  `on_mount` hook enforcing the kiosk session PIN for every LiveView in the
  `:kiosk` live session.

  LiveView live navigation reuses the WebSocket connection and does not run
  plugs, so the HTTP `RequireKioskSession` guard alone could be bypassed (for
  example by the navbar "Check-in" link from `/start`). This hook re-checks the
  kiosk session, whose token the plug mirrors into the session, on every mount.
  """

  use AttendanceTrackerWeb, :verified_routes

  import Phoenix.LiveView, only: [redirect: 2]

  alias AttendanceTracker.Tracker
  alias AttendanceTrackerWeb.KioskSession

  def on_mount(:default, _params, session, socket) do
    if Tracker.session_pin_configured?() and not KioskSession.valid_token?(session["kiosk_token"]) do
      {:halt, redirect(socket, to: ~p"/start")}
    else
      {:cont, socket}
    end
  end
end
