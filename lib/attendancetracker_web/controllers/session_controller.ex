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

  def delete(conn, _params) do
    conn
    |> delete_session(:admin_pin_ok)
    |> put_flash(:info, "Admin mode off")
    |> redirect(to: ~p"/")
  end
end
