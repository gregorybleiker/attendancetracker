defmodule AttendanceTrackerWeb.Plugs.RequireAdminPin do
  @moduledoc """
  Guards the app behind the admin PIN: clients without an active admin session
  are redirected to the login page.

  An admin session expires after the configured idle timeout (see
  `AttendanceTracker.Tracker.admin_timeout_minutes/0`). Every authenticated
  request counts as activity and refreshes the session.
  """

  use AttendanceTrackerWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  alias AttendanceTracker.AdminSession
  alias AttendanceTracker.Tracker

  def init(opts), do: opts

  def call(conn, _opts) do
    token = get_session(conn, :admin_token)

    if AdminSession.refresh(token, Tracker.admin_timeout_seconds()) do
      conn
    else
      conn
      |> delete_session(:admin_token)
      |> redirect(to: ~p"/login")
      |> halt()
    end
  end
end
