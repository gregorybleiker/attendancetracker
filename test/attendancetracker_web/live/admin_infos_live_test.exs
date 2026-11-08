defmodule AttendanceTrackerWeb.AdminInfosLiveTest do
  use AttendanceTrackerWeb.ConnCase

  import Phoenix.LiveViewTest

  alias AttendanceTracker.Tracker

  setup %{conn: conn} do
    %{conn: log_in(conn)}
  end

  test "creates an info slide", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/admin/infos")

    view |> element("#new-info-btn") |> render_click()
    assert has_element?(view, "#info-form")

    view
    |> form("#info-form", %{info: %{title: "Welcome", body: "<p>Hello</p>", position: 1}})
    |> render_submit()

    assert [%{title: "Welcome", body: "<p>Hello</p>", position: 1}] = Tracker.list_infos()
    assert has_element?(view, "#infos-list", "Welcome")
  end

  test "edits an info slide", %{conn: conn} do
    {:ok, info} = Tracker.create_info(%{title: "Old", body: "<p>old</p>"})

    {:ok, view, _html} = live(conn, ~p"/admin/infos")

    view |> element("#edit-info-#{info.id}") |> render_click()

    view
    |> form("#info-form", %{info: %{title: "New", body: "<p>new</p>"}})
    |> render_submit()

    assert Tracker.get_info!(info.id).title == "New"
    assert has_element?(view, "#infos-list", "New")
  end

  test "deletes an info slide", %{conn: conn} do
    {:ok, info} = Tracker.create_info(%{body: "<p>bye</p>"})

    {:ok, view, _html} = live(conn, ~p"/admin/infos")

    view |> element("#delete-info-#{info.id}") |> render_click()

    assert Tracker.list_infos() == []
    assert has_element?(view, "#no-infos")
  end

  test "validates that the body is required", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/admin/infos")

    view |> element("#new-info-btn") |> render_click()

    html =
      view
      |> form("#info-form", %{info: %{title: "No body", body: ""}})
      |> render_submit()

    assert html =~ "blank"
    assert Tracker.list_infos() == []
  end
end
