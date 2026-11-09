defmodule AttendanceTrackerWeb.ClientIP do
  @moduledoc """
  Extracts the client IP used to key the brute-force throttle.

  The app always runs behind a trusted reverse proxy (Caddy in the bundled
  compose, nginx in the shared stack). Proxies append the real peer to
  `x-forwarded-for`, so the *rightmost* entry is the address of the actual
  client while the leftmost entries are client-controlled and spoofable. We
  therefore read the rightmost entry and fall back to the raw peer address
  (loopback in tests, or a direct connection without a proxy).

  This deliberately does not trust `Plug.RewriteOn`'s leftmost value: behind a
  proxy that appends, a spoofed header would otherwise let an attacker rotate
  the throttle key at will.
  """

  import Phoenix.LiveView, only: [get_connect_info: 2]

  @doc "Client IP for a Plug connection, as a string."
  def from_conn(conn) do
    rightmost_forwarded(conn.req_headers) || format(conn.remote_ip)
  end

  @doc """
  Client IP for a LiveView socket, as a string.

  `get_connect_info/2` is only readable while mounting, so this must be called
  from `mount/3` and the result stored in assigns for later events.
  """
  def from_socket(socket) do
    forwarded =
      socket
      |> get_connect_info(:x_headers)
      |> List.wrap()
      |> rightmost_forwarded()

    peer = get_connect_info(socket, :peer_data)

    forwarded || format(peer && Map.get(peer, :address))
  end

  defp rightmost_forwarded(headers) do
    headers
    |> Enum.filter(fn {name, _value} -> name == "x-forwarded-for" end)
    |> Enum.map(fn {_name, value} -> value end)
    |> List.last()
    |> case do
      nil -> nil
      value -> value |> String.split(",") |> List.last() |> String.trim() |> valid_ip()
    end
  end

  defp valid_ip(candidate) do
    case :inet.parse_address(String.to_charlist(candidate)) do
      {:ok, _address} -> candidate
      {:error, _reason} -> nil
    end
  end

  defp format(ip) when is_tuple(ip), do: ip |> :inet.ntoa() |> to_string()
  defp format(_ip), do: "unknown"
end
