defmodule AttendanceTrackerWeb.ReportLiveTest do
  use AttendanceTrackerWeb.ConnCase

  import Phoenix.LiveViewTest
  import AttendanceTracker.TrackerFixtures

  alias AttendanceTracker.Tracker

  setup %{conn: conn} do
    %{conn: log_in(conn)}
  end

  test "offers the years that have sessions for download", %{conn: conn} do
    training_session_fixture(%{date: ~D[2024-03-11]})
    training_session_fixture(%{date: ~D[2025-06-02]})

    {:ok, view, _html} = live(conn, ~p"/reporting")

    assert has_element?(view, ~s(#report-form[action="/reporting/download"]))

    for year <- [Tracker.local_today().year, 2025, 2024] do
      assert has_element?(view, "#report-form option[value='#{year}']")
    end
  end

  test "falls back to the current year without any sessions", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/reporting")

    assert has_element?(view, "#report-form option[value='#{Tracker.local_today().year}']")
  end
end
