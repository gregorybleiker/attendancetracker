defmodule AttendanceTrackerWeb.EventLiveTest do
  use AttendanceTrackerWeb.ConnCase

  import Phoenix.LiveViewTest
  import AttendanceTracker.TrackerFixtures

  alias AttendanceTracker.Tracker

  setup %{conn: conn} do
    %{conn: log_in(conn)}
  end

  describe "Index" do
    test "lists events", %{conn: conn} do
      event_fixture(%{name: "Summer camp", date: ~D[2026-07-01]})

      {:ok, view, html} = live(conn, ~p"/events")

      assert html =~ "Events"
      assert html =~ "Summer camp"
      assert has_element?(view, "#events")
    end

    test "deletes an event", %{conn: conn} do
      event = event_fixture()

      {:ok, view, _html} = live(conn, ~p"/events")

      view
      |> element("#events-#{event.id} a", "Delete")
      |> render_click()

      assert_raise Ecto.NoResultsError, fn -> Tracker.get_event!(event.id) end
    end
  end

  describe "Form" do
    test "creates an event", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/events/new")

      view
      |> form("#event-form",
        event: %{
          name: "Demo day",
          date: "2026-11-05",
          starts_at: "09:00",
          ends_at: "12:00"
        }
      )
      |> render_submit()

      {path, _flash} = assert_redirect(view)
      assert path =~ "/events/"

      assert Enum.any?(Tracker.list_events(), &(&1.name == "Demo day"))
    end

    test "shows validation errors", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/events/new")

      html =
        view
        |> form("#event-form",
          event: %{name: "", date: "", starts_at: "10:00", ends_at: "09:00"}
        )
        |> render_change()

      assert html =~ "be blank"
      assert html =~ "must be after the start time"
    end
  end

  describe "Show (participant selection)" do
    test "shows only selected participants by default and reveals all on demand", %{conn: conn} do
      event = event_fixture()
      ada = participant_fixture(%{name: "Ada Lovelace"})
      grace = participant_fixture(%{name: "Grace Hopper"})
      {:ok, _} = Tracker.add_event_participant(event, grace)

      {:ok, view, _html} = live(conn, ~p"/events/#{event}")

      assert render(view) =~ "1 selected"
      assert has_element?(view, "#event-participant-#{grace.id}")
      refute has_element?(view, "#event-participant-#{ada.id}")

      view |> element("#event-show-all-toggle") |> render_click()

      assert has_element?(view, "#event-participant-#{ada.id}")
      assert has_element?(view, "#event-participant-#{grace.id}")
    end

    test "selects and deselects participants", %{conn: conn} do
      event = event_fixture()
      participant = participant_fixture(%{name: "Ada Lovelace"})

      {:ok, view, _html} = live(conn, ~p"/events/#{event}")

      assert render(view) =~ "0 selected"
      refute has_element?(view, "#event-participant-#{participant.id}")

      view |> element("#event-show-all-toggle") |> render_click()
      assert has_element?(view, "#event-participant-#{participant.id}")

      view |> element("#event-participant-#{participant.id}") |> render_click()
      assert Tracker.event_participant?(event, participant)
      assert render(view) =~ "1 selected"

      view |> element("#event-show-all-toggle") |> render_click()
      assert has_element?(view, "#event-participant-#{participant.id}")

      view |> element("#event-participant-#{participant.id}") |> render_click()
      refute Tracker.event_participant?(event, participant)
      assert render(view) =~ "0 selected"
      refute has_element?(view, "#event-participant-#{participant.id}")
    end
  end
end
