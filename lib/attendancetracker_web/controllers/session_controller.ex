defmodule AttendanceTrackerWeb.SessionController do
  use AttendanceTrackerWeb, :controller

  alias AttendanceTracker.AdminSession
  alias AttendanceTracker.PinThrottle
  alias AttendanceTracker.Tracker
  alias AttendanceTrackerWeb.ClientIP
  alias AttendanceTrackerWeb.KioskSession

  def create(conn, %{"pin" => pin}) do
    ip = ClientIP.from_conn(conn)

    case PinThrottle.check_admin(ip) do
      :ok ->
        if Tracker.admin_pin_valid?(pin) do
          PinThrottle.clear_admin(ip)
          token = AdminSession.start()

          conn
          |> configure_session(renew: true)
          |> put_session(:admin_token, token)
          |> redirect(to: ~p"/")
        else
          PinThrottle.record_admin_failure(ip)

          conn
          |> put_flash(:error, "Wrong PIN")
          |> redirect(to: ~p"/login")
        end

      {:error, retry_after} ->
        conn
        |> put_flash(:error, throttled_message(retry_after))
        |> redirect(to: ~p"/login")
    end
  end

  def delete(conn, _params) do
    AdminSession.forget(get_session(conn, :admin_token))

    conn
    |> delete_session(:admin_token)
    |> put_flash(:info, "Admin mode off")
    |> redirect(to: ~p"/")
  end

  @doc """
  Starts a kiosk session: validates the session PIN and, on success, issues
  the kiosk session cookie (valid for the configured expiry) before sending
  the client to the check-in screen.

  Repeated failures from the same client are throttled by
  `AttendanceTracker.PinThrottle`.
  """
  def start(conn, %{"pin" => pin}) do
    ip = ClientIP.from_conn(conn)

    case PinThrottle.check_session(ip) do
      :ok ->
        if Tracker.session_pin_valid?(pin) do
          PinThrottle.clear_session(ip)

          conn
          |> KioskSession.issue()
          |> redirect(to: ~p"/")
        else
          PinThrottle.record_session_failure(ip)

          conn
          |> put_flash(:error, "Wrong PIN")
          |> redirect(to: ~p"/start")
        end

      {:error, retry_after} ->
        conn
        |> put_flash(:error, throttled_message(retry_after))
        |> redirect(to: ~p"/start")
    end
  end

  defp throttled_message(retry_after) do
    gettext("Too many attempts. Try again in %{seconds} seconds.", seconds: retry_after)
  end
end
