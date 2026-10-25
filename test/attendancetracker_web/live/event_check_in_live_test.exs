defmodule AttendanceTrackerWeb.EventCheckInLiveTest do
  use AttendanceTrackerWeb.ConnCase

  import Phoenix.LiveViewTest
  import AttendanceTracker.TrackerFixtures

  alias AttendanceTracker.Tracker

  test "shows a message when there are no events", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/event-check-in")

    assert html =~ "No events yet."
  end

  test "toggles a participant's selection for the selected event", %{conn: conn} do
    event = event_fixture(%{name: "Summer camp", date: ~D[2026-07-01]})
    participant = participant_fixture(%{name: "Ada Lovelace"})

    {:ok, view, html} = live(conn, ~p"/event-check-in")

    assert html =~ "Summer camp"
    assert has_element?(view, "#event-participant-#{participant.id}")
    assert render(view) =~ "0 selected"

    view |> element("#event-participant-#{participant.id}") |> render_click()
    assert Tracker.event_participant?(event, participant)
    assert render(view) =~ "1 selected"

    view |> element("#event-participant-#{participant.id}") |> render_click()
    refute Tracker.event_participant?(event, participant)
    assert render(view) =~ "0 selected"
  end

  test "switching events reloads the selection", %{conn: conn} do
    _first = event_fixture(%{name: "First", date: ~D[2026-01-01]})
    second = event_fixture(%{name: "Second", date: ~D[2026-02-01]})
    participant = participant_fixture(%{name: "Ada Lovelace"})
    {:ok, :created} = Tracker.add_event_participant(second, participant)

    {:ok, view, _html} = live(conn, ~p"/event-check-in")

    assert render(view) =~ "0 selected"

    view |> form("#event-select", %{event_id: second.id}) |> render_change()

    assert render(view) =~ "Second"
    assert render(view) =~ "1 selected"
  end
end
