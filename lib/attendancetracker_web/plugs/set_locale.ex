defmodule AttendanceTrackerWeb.Plugs.SetLocale do
  @moduledoc """
  Picks the request locale and stores it in the session.

  The choice is remembered in the session; on the first visit it is detected
  from the browser's `Accept-Language` header, falling back to the default.
  """

  import Plug.Conn

  alias AttendanceTrackerWeb.Locales

  def init(opts), do: opts

  def call(conn, _opts) do
    locale = resolve(conn)
    Gettext.put_locale(AttendanceTrackerWeb.Gettext, locale)

    if get_session(conn, :locale) == locale do
      conn
    else
      put_session(conn, :locale, locale)
    end
  end

  defp resolve(conn) do
    session_locale = get_session(conn, :locale)

    cond do
      Locales.valid?(session_locale) -> session_locale
      detected = detect(conn) -> detected
      true -> Locales.default()
    end
  end

  defp detect(conn) do
    conn
    |> get_req_header("accept-language")
    |> List.first()
    |> parse_accept_language()
  end

  defp parse_accept_language(nil), do: nil

  defp parse_accept_language(header) do
    header
    |> String.split(",")
    |> Enum.map(fn part ->
      part
      |> String.split(";")
      |> List.first()
      |> String.trim()
      |> String.slice(0, 2)
      |> String.downcase()
    end)
    |> Enum.find(&Locales.valid?/1)
  end
end
