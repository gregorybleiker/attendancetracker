defmodule AttendanceTrackerWeb.SessionControllerTest do
  use AttendanceTrackerWeb.ConnCase

  import Phoenix.LiveViewTest
  import AttendanceTracker.TrackerFixtures

  test "DELETE /logout clears admin mode and redirects to the kiosk", %{conn: conn} do
    participant = participant_fixture(%{active: true})
    conn = log_in(conn)

    {:ok, view, _html} = live(conn, ~p"/")
    assert has_element?(view, "#exit-admin-mode-menu")
    assert has_element?(view, "#camera-btn-#{participant.id}")

    conn = delete(conn, ~p"/logout")

    assert redirected_to(conn) == ~p"/"

    {:ok, view, _html} = live(conn, ~p"/")
    assert has_element?(view, "#admin-mode-menu")
    refute has_element?(view, "#exit-admin-mode-menu")
    refute has_element?(view, "#camera-btn-#{participant.id}")
  end

  test "DELETE /logout works when not logged in", %{conn: conn} do
    conn = delete(conn, ~p"/logout")

    assert redirected_to(conn) == ~p"/"
  end
end
