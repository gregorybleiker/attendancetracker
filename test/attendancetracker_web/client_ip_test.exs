defmodule AttendanceTrackerWeb.ClientIPTest do
  use ExUnit.Case, async: true

  import Plug.Conn, only: [put_req_header: 3]

  alias AttendanceTrackerWeb.ClientIP
  alias Phoenix.LiveView.Socket

  test "uses the rightmost x-forwarded-for entry, ignoring a spoofed prefix" do
    conn =
      Plug.Test.conn(:get, "/")
      |> put_req_header("x-forwarded-for", "1.2.3.4, 203.0.113.7")

    assert ClientIP.from_conn(conn) == "203.0.113.7"
  end

  test "falls back to the peer address without a forwarded header" do
    assert ClientIP.from_conn(Plug.Test.conn(:get, "/")) == "127.0.0.1"
  end

  test "ignores an unparseable forwarded value" do
    conn =
      Plug.Test.conn(:get, "/")
      |> put_req_header("x-forwarded-for", "not-an-ip")

    assert ClientIP.from_conn(conn) == "127.0.0.1"
  end

  test "reads the forwarded header from LiveView connect info" do
    socket =
      %Socket{
        private: %{
          connect_info: %{
            x_headers: [{"x-forwarded-for", "9.9.9.9, 8.8.8.8"}],
            peer_data: %{address: {127, 0, 0, 1}}
          }
        }
      }

    assert ClientIP.from_socket(socket) == "8.8.8.8"
  end

  test "falls back to the socket peer address without a forwarded header" do
    socket =
      %Socket{
        private: %{
          connect_info: %{
            x_headers: [],
            peer_data: %{address: {10, 0, 0, 5}}
          }
        }
      }

    assert ClientIP.from_socket(socket) == "10.0.0.5"
  end
end
