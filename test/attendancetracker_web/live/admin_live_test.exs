defmodule AttendanceTrackerWeb.AdminLiveTest do
  use AttendanceTrackerWeb.ConnCase

  import Phoenix.LiveViewTest

  alias AttendanceTracker.Tracker

  setup %{conn: conn} do
    %{conn: log_in(conn)}
  end

  test "requires the admin PIN", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/admin")

    assert has_element?(view, "#admin-unlock-form")
    refute has_element?(view, "#admin-pin-form")
  end

  test "rejects a wrong PIN", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/admin")

    html = view |> form("#admin-unlock-form", %{pin: "0000"}) |> render_submit()

    assert html =~ "Wrong PIN"
    refute has_element?(view, "#admin-pin-form")
  end

  test "unlocks with the default PIN 1234", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/admin")

    view |> form("#admin-unlock-form", %{pin: "1234"}) |> render_submit()

    assert has_element?(view, "#admin-pin-form")
  end

  test "changes the admin PIN", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/admin")
    view |> form("#admin-unlock-form", %{pin: "1234"}) |> render_submit()

    view
    |> form("#admin-pin-form", %{
      pin: %{new_pin: "9876", new_pin_confirmation: "9876"}
    })
    |> render_submit()

    assert Tracker.admin_pin() == "9876"
    assert Tracker.admin_pin_valid?("9876")
    refute Tracker.admin_pin_valid?("1234")
  end

  test "validates the new PIN", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/admin")
    view |> form("#admin-unlock-form", %{pin: "1234"}) |> render_submit()

    html =
      view
      |> form("#admin-pin-form", %{
        pin: %{new_pin: "abcd", new_pin_confirmation: "abcd"}
      })
      |> render_submit()

    assert html =~ "must be 4 to 12 digits"

    html =
      view
      |> form("#admin-pin-form", %{
        pin: %{new_pin: "9876", new_pin_confirmation: "9877"}
      })
      |> render_submit()

    assert html =~ "does not match"

    # still the default PIN
    assert Tracker.admin_pin_valid?("1234")
  end
end
