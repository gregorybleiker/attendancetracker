defmodule AttendanceTrackerWeb.Plugs.RequireAdminPin do
  @moduledoc """
  Guards the app behind the admin PIN: clients that have not logged in
  yet are redirected to the login page.
  """

  use AttendanceTrackerWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, _opts) do
    if get_session(conn, :admin_pin_ok) do
      conn
    else
      conn
      |> redirect(to: ~p"/login")
      |> halt()
    end
  end
end
