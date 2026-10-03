defmodule AttendanceTrackerWeb.AdminDuplicatesLiveTest do
  use AttendanceTrackerWeb.ConnCase

  import Phoenix.LiveViewTest
  import AttendanceTracker.TrackerFixtures

  setup %{conn: conn} do
    %{conn: log_in(conn)}
  end

  test "lists duplicates and merges them", %{conn: conn} do
    survivor = participant_fixture(%{first_name: "Ada", last_name: "Lovelace"})
    duplicate = participant_fixture(%{first_name: "Ada", last_name: ""})

    {:ok, view, _html} = live(conn, ~p"/admin/duplicates")

    assert has_element?(view, "#duplicate-#{duplicate.id}-#{survivor.id}")

    view |> element("#merge-btn-#{duplicate.id}-#{survivor.id}") |> render_click()

    assert has_element?(view, "#merge-mask")

    view
    |> form("#merge-form", %{
      merge: %{
        first_name: "Ada",
        last_name: "Lovelace",
        emergency_number: "079 111",
        active: "true"
      }
    })
    |> render_submit()

    assert render(view) =~ "Participants merged"
    refute has_element?(view, "#duplicate-#{duplicate.id}-#{survivor.id}")
    assert has_element?(view, "#no-duplicates")
  end

  test "shows an empty state without duplicates", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/admin/duplicates")

    assert html =~ "No likely duplicates found."
  end
end
