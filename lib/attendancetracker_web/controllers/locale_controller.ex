defmodule AttendanceTrackerWeb.LocaleController do
  use AttendanceTrackerWeb, :controller

  alias AttendanceTrackerWeb.Locales

  @doc """
  Stores the chosen locale in the session and redirects back to the page the
  user came from, so a full reload re-renders everything in the new language.
  """
  def update(conn, %{"locale" => locale}) do
    locale = if Locales.valid?(locale), do: locale, else: Locales.default()

    conn
    |> put_session(:locale, locale)
    |> redirect(to: return_to(conn))
  end

  defp return_to(conn) do
    case get_req_header(conn, "referer") do
      [referer | _] ->
        uri = URI.parse(referer)

        if uri.host in [nil, conn.host] do
          path = uri.path || "/"
          if uri.query, do: path <> "?" <> uri.query, else: path
        else
          "/"
        end

      _ ->
        "/"
    end
  end
end
