defmodule AttendanceTrackerWeb.SessionController do
  use AttendanceTrackerWeb, :controller

  alias AttendanceTracker.Tracker

  def create(conn, %{"pin" => pin}) do
    if Tracker.admin_pin_valid?(pin) do
      conn
      |> configure_session(renew: true)
      |> put_session(:admin_pin_ok, true)
      |> redirect(to: ~p"/")
    else
      conn
      |> put_flash(:error, "Wrong PIN")
      |> redirect(to: ~p"/login")
    end
  end
end
