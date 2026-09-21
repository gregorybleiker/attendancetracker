defmodule AttendanceTrackerWeb.LoginLiveTest do
  use AttendanceTrackerWeb.ConnCase

  import Phoenix.LiveViewTest

  test "shows the login form", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/login")

    assert has_element?(view, "#login-form")
  end

  test "all pages except the check-in are guarded when not logged in", %{conn: _conn} do
    for path <- [
          ~p"/participants",
          ~p"/training_days",
          ~p"/reporting",
          ~p"/reporting/download?year=2026",
          ~p"/admin"
        ] do
      assert build_conn() |> get(path) |> redirected_to() == ~p"/login"
    end
  end

  test "the check-in page is public", %{conn: conn} do
    conn = get(conn, ~p"/")

    assert html_response(conn, 200)
  end

  test "logging in with the correct PIN redirects to the check-in page", %{conn: conn} do
    conn = post(conn, ~p"/login", %{"pin" => "1234"})
    assert redirected_to(conn) == ~p"/"

    # the client can now reach the app
    conn = get(conn, ~p"/")
    assert html_response(conn, 200)
  end

  test "logging in with a wrong PIN redirects back with an error", %{conn: conn} do
    conn = post(conn, ~p"/login", %{"pin" => "0000"})

    assert redirected_to(conn) == ~p"/login"
    assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Wrong PIN"

    # still locked out
    conn = get(conn, ~p"/admin")
    assert redirected_to(conn) == ~p"/login"
  end

  test "redirects away from the login page when already logged in", %{conn: conn} do
    conn = log_in(conn)

    assert {:error, {:redirect, %{to: "/"}}} = live(conn, ~p"/login")
  end
end
