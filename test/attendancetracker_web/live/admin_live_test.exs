defmodule AttendanceTrackerWeb.AdminLiveTest do
  use AttendanceTrackerWeb.ConnCase

  import Phoenix.LiveViewTest

  alias AttendanceTracker.Tracker

  setup %{conn: conn} do
    %{conn: log_in(conn)}
  end

  test "does not ask for the PIN again when already in admin mode", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/admin")

    refute has_element?(view, "#admin-unlock-form")
    assert has_element?(view, "#admin-pin-form")
  end

  test "changes the admin PIN", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/admin")

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

  test "sets the session PIN", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/admin")

    view
    |> form("#session-pin-form", %{
      session_pin: %{new_pin: "2468", new_pin_confirmation: "2468"}
    })
    |> render_submit()

    assert Tracker.session_pin() == "2468"
    assert Tracker.session_pin_valid?("2468")
  end

  test "validates the new session PIN", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/admin")

    html =
      view
      |> form("#session-pin-form", %{
        session_pin: %{new_pin: "12", new_pin_confirmation: "12"}
      })
      |> render_submit()

    assert html =~ "must be 4 to 12 digits"
    refute Tracker.session_pin_configured?()
  end

  test "sets the session expiry", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/admin")
    assert has_element?(view, "#session-expiry-form")

    view
    |> form("#session-expiry-form", %{session_expiry: %{days: 7}})
    |> render_submit()

    assert Tracker.session_expiry_days() == 7
  end

  test "validates the session expiry", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/admin")

    html =
      view
      |> form("#session-expiry-form", %{session_expiry: %{days: 0}})
      |> render_submit()

    assert html =~ "must be between 1 and 3650 days"
    assert Tracker.session_expiry_days() == 30
  end

  test "sets the log settings", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/admin")
    assert has_element?(view, "#logs-settings-form")

    view
    |> form("#logs-settings-form", %{logs: %{max_entries: 500, prune_interval_minutes: 15}})
    |> render_submit()

    assert AttendanceTracker.Logs.max_entries() == 500
    assert AttendanceTracker.Logs.prune_interval_minutes() == 15
  end

  describe "user management import" do
    import AttendanceTracker.TrackerFixtures

    alias AttendanceTracker.Directory
    alias AttendanceTracker.Directory.FakeSource

    setup do
      Application.put_env(:attendancetracker, :directory_sources, %{"fake" => FakeSource})

      on_exit(fn ->
        Application.delete_env(:attendancetracker, :directory_sources)
      end)

      :ok
    end

    test "saves the connector settings", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin")

      assert has_element?(view, "#directory-settings-form")

      view
      |> form("#directory-settings-form", %{directory: %{source: "fake"}})
      |> render_change()

      view
      |> form("#directory-settings-form", %{directory: %{source: "fake", token: "s3cret"}})
      |> render_submit()

      assert Directory.source() == "fake"
      assert Directory.config("fake") == %{"token" => "s3cret"}
    end

    test "previews members and imports the new ones", %{conn: conn} do
      training_fixture(%{name: "Kids Judo"})
      participant_fixture(%{name: "Ada Lovelace"})

      {:ok, view, _html} = live(conn, ~p"/admin")

      view
      |> form("#directory-settings-form", %{directory: %{source: "fake"}})
      |> render_change()

      view
      |> form("#directory-settings-form", %{directory: %{source: "fake", token: "x"}})
      |> render_submit()

      view |> element("#directory-preview-btn") |> render_click()

      assert has_element?(view, "#directory-preview")
      assert has_element?(view, "#directory-preview", "Grace Hopper")
      refute has_element?(view, "#directory-preview", "Ada Lovelace")

      view |> element("#directory-import-btn") |> render_click()

      assert render(view) =~ "Imported 1 participants"
      refute has_element?(view, "#directory-preview")

      assert Enum.any?(
               Tracker.list_participants(),
               &(AttendanceTracker.Tracker.Participant.full_name(&1) == "Grace Hopper")
             )
    end

    test "explains when no training has an alias", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin")

      view |> element("#directory-preview-btn") |> render_click()

      assert render(view) =~ "No training has an alias"
      refute has_element?(view, "#directory-preview")
    end
  end
end
