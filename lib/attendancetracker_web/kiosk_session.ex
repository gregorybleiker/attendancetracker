defmodule AttendanceTrackerWeb.KioskSession do
  @moduledoc """
  Issues and verifies the kiosk session cookie.

  A kiosk session is started by entering the session PIN (configured in the
  admin area) and lasts for the configured number of days. It is stored in a
  dedicated cookie, separate from the admin session, so that unlocking the
  kiosk never extends the lifetime of admin mode.
  """

  import Plug.Conn, only: [fetch_cookies: 1, put_resp_cookie: 4]

  alias AttendanceTracker.Tracker

  @cookie "kiosk_session"
  @salt "kiosk_session"

  @doc """
  Sets the kiosk session cookie on the connection, valid for the configured
  session expiry.
  """
  def issue(conn) do
    token =
      Phoenix.Token.sign(AttendanceTrackerWeb.Endpoint, @salt, %{
        fingerprint: Tracker.session_pin_fingerprint()
      })

    put_resp_cookie(conn, @cookie, token,
      max_age: Tracker.session_expiry_seconds(),
      http_only: true,
      same_site: "Lax"
    )
  end

  @doc """
  Returns true when the connection carries a valid, unexpired kiosk session
  for the currently configured session PIN.
  """
  def valid?(conn) do
    cookie = conn |> fetch_cookies() |> Map.get(:req_cookies) |> Map.get(@cookie)

    case cookie do
      nil -> false
      token -> verify(token)
    end
  end

  defp verify(token) do
    max_age = Tracker.session_expiry_seconds()

    with {:ok, %{fingerprint: fingerprint}} <-
           Phoenix.Token.verify(AttendanceTrackerWeb.Endpoint, @salt, token, max_age: max_age) do
      fingerprint == Tracker.session_pin_fingerprint()
    else
      _ -> false
    end
  end
end
