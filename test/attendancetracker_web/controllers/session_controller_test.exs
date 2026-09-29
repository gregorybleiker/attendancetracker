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

  describe "kiosk session PIN" do
    alias AttendanceTracker.Tracker

    test "the kiosk stays open while no session PIN is configured", %{conn: conn} do
      assert {:ok, _view, _html} = live(conn, ~p"/")
    end

    test "the kiosk redirects to /start once a session PIN is configured", %{conn: conn} do
      {:ok, _} = Tracker.update_session_pin("2468")

      conn = get(conn, ~p"/")

      assert redirected_to(conn) == ~p"/start"
    end

    test "starting a session with the correct PIN unlocks the kiosk", %{conn: conn} do
      {:ok, _} = Tracker.update_session_pin("2468")

      conn = post(conn, ~p"/start", %{"pin" => "2468"})
      assert redirected_to(conn) == ~p"/"

      assert {:ok, _view, _html} = live(conn, ~p"/")
    end

    test "a wrong PIN does not unlock the kiosk", %{conn: conn} do
      {:ok, _} = Tracker.update_session_pin("2468")

      conn = post(conn, ~p"/start", %{"pin" => "0000"})
      assert redirected_to(conn) == ~p"/start"

      conn = get(conn, ~p"/")
      assert redirected_to(conn) == ~p"/start"
    end

    test "changing the session PIN invalidates an existing session", %{conn: conn} do
      {:ok, _} = Tracker.update_session_pin("2468")

      conn = post(conn, ~p"/start", %{"pin" => "2468"})
      assert {:ok, _view, _html} = live(conn, ~p"/")

      {:ok, _} = Tracker.update_session_pin("1357")

      conn = get(conn, ~p"/")
      assert redirected_to(conn) == ~p"/start"
    end
  end

  describe "session unlock page" do
    alias AttendanceTracker.Tracker

    test "renders the unlock form when a session PIN is configured", %{conn: conn} do
      {:ok, _} = Tracker.update_session_pin("2468")

      {:ok, view, _html} = live(conn, ~p"/start")

      assert has_element?(view, "#session-unlock-form")
    end

    test "redirects to the kiosk when no session PIN is configured", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/"}}} = live(conn, ~p"/start")
    end
  end
end
