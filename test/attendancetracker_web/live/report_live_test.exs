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

  test "lists not-in-Webling participants who have attended a training", %{conn: conn} do
    training = training_fixture(%{name: "Judo"})
    session = training_session_fixture(%{training_id: training.id})

    local = participant_fixture(%{name: "Local Person", source: "local"})
    webling = participant_fixture(%{name: "Imported Person", source: "webling"})
    never = participant_fixture(%{name: "Never Attended", source: "local"})

    check_in_fixture(%{participant: local, training_session: session})
    check_in_fixture(%{participant: webling, training_session: session})

    {:ok, view, _html} = live(conn, ~p"/reporting")

    assert has_element?(view, "#non-webling-attenders")
    assert has_element?(view, "#non-webling-#{local.id}")
    refute has_element?(view, "#non-webling-#{webling.id}")
    refute has_element?(view, "#non-webling-#{never.id}")

    assert render(view) =~ "Local Person"
    assert render(view) =~ "Judo"
  end

  test "shows an empty state when nobody matches", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/reporting")

    assert has_element?(view, "#non-webling-attenders-empty")
    refute has_element?(view, "#non-webling-attenders")
  end
end
