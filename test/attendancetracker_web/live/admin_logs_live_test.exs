defmodule AttendanceTrackerWeb.AdminLogsLiveTest do
  use AttendanceTrackerWeb.ConnCase

  import Phoenix.LiveViewTest

  alias AttendanceTracker.Logs

  setup %{conn: conn} do
    %{conn: log_in(conn)}
  end

  test "shows the audit log and can switch to the program log", %{conn: conn} do
    {:ok, _} =
      Logs.audit(%{action: "check_in", participant_name: "Ada Lovelace", training_session_id: 1})

    {:ok, _} =
      Logs.program(%{
        source: "webling",
        command: "fetch_members",
        status: "ok",
        request: "GET /member",
        result: "3 members"
      })

    {:ok, view, _html} = live(conn, ~p"/admin/logs")

    assert has_element?(view, "#log-view")
    assert has_element?(view, "#audit-log-table", "Ada Lovelace")

    view |> element("#show-program-log") |> render_click()

    assert has_element?(view, "#program-log-table", "fetch_members")
    assert has_element?(view, "#program-log-table", "3 members")
    refute has_element?(view, "#audit-log-table")
  end

  test "shows an empty state", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/admin/logs")

    assert html =~ "No log entries yet."
  end
end
