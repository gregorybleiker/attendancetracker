defmodule AttendanceTrackerWeb.LocaleTest do
  use AttendanceTrackerWeb.ConnCase

  test "detects the browser language", %{conn: conn} do
    conn =
      conn
      |> put_req_header("accept-language", "de-CH,de;q=0.9,en;q=0.8")
      |> get(~p"/login")

    assert html_response(conn, 200) =~ "Admin-PIN eingeben, um fortzufahren."
  end

  test "remembers the chosen language across requests", %{conn: conn} do
    conn = get(conn, ~p"/locale/de")
    assert redirected_to(conn) == "/"

    conn = get(recycle(conn), ~p"/login")
    assert html_response(conn, 200) =~ "Admin-PIN eingeben, um fortzufahren."
    assert html_response(conn, 200) =~ "/locale/en"
  end

  test "falls back to English for an unsupported language", %{conn: conn} do
    conn = get(conn, ~p"/locale/fr")
    assert redirected_to(conn) == "/"

    conn = get(recycle(conn), ~p"/login")
    assert html_response(conn, 200) =~ "Enter the admin PIN to continue."
  end

  test "translates the admin area", %{conn: conn} do
    conn = get(log_in(conn), ~p"/locale/de")
    conn = get(recycle(conn), ~p"/training")

    assert html_response(conn, 200) =~ "Wochentag"
    assert html_response(conn, 200) =~ "Neues Training"
  end
end
