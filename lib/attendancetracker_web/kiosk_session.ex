defmodule AttendanceTrackerWeb.KioskSession do
  @moduledoc """
  Issues and verifies the kiosk session cookie.

  A kiosk session is started by entering the session PIN (configured in the
  admin area) and lasts for the configured number of days. It is stored in a
  dedicated cookie, separate from the admin session, so that unlocking the
  kiosk never extends the lifetime of admin mode.

  The token is also mirrored into the Plug session so the LiveView
  `on_mount` hook (see `AttendanceTrackerWeb.KioskSessionHook`) can enforce the
  same check on WebSocket connects and live navigation, where the HTTP plug
  does not run.
  """

  import Plug.Conn, only: [fetch_cookies: 1, put_resp_cookie: 4, put_session: 3]

  alias AttendanceTracker.Tracker

  @cookie "kiosk_session"
  @salt "kiosk_session"
  @session_key :kiosk_token

  @doc """
  Sets the kiosk session cookie and session value on the connection, valid for
  the configured session expiry.
  """
  def issue(conn) do
    token = sign()

    conn
    |> put_resp_cookie(@cookie, token,
      max_age: Tracker.session_expiry_seconds(),
      http_only: true,
      same_site: "Lax"
    )
    |> put_session(@session_key, token)
  end

  @doc """
  Returns true when the connection carries a valid, unexpired kiosk session
  for the currently configured session PIN.
  """
  def valid?(conn), do: conn |> token() |> valid_token?()

  @doc """
  Returns the raw kiosk session token stored in the request cookie, or `nil`.
  """
  def token(conn) do
    conn
    |> fetch_cookies()
    |> Map.get(:req_cookies)
    |> Map.get(@cookie)
  end

  @doc """
  Returns true when `token` is a valid, unexpired kiosk session for the
  currently configured session PIN.
  """
  def valid_token?(token) when is_binary(token), do: verify(token)
  def valid_token?(_token), do: false

  defp sign do
    Phoenix.Token.sign(AttendanceTrackerWeb.Endpoint, @salt, %{
      fingerprint: Tracker.session_pin_fingerprint()
    })
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
