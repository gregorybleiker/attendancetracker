defmodule AttendanceTrackerWeb.CheckInLiveTest do
  use AttendanceTrackerWeb.ConnCase

  import Phoenix.LiveViewTest
  import AttendanceTracker.TrackerFixtures

  test "shows active participants and the attendance count", %{conn: conn} do
    participant_fixture(%{name: "Grid Person", active: true})

    {:ok, _view, html} = live(conn, ~p"/")

    assert html =~ "Grid Person"
    assert html =~ "0 / 1 present"
  end

  test "hides inactive participants", %{conn: conn} do
    participant_fixture(%{name: "Gone Person", active: false})

    {:ok, _view, html} = live(conn, ~p"/")

    refute html =~ "Gone Person"
  end

  test "shows the Notfallnummer on the participant tile only in admin mode", %{conn: conn} do
    with_number = participant_fixture(%{name: "Has Number", emergency_number: "0151 234567"})
    without = participant_fixture(%{name: "No Number", emergency_number: nil})

    {:ok, view, _html} = live(conn, ~p"/")

    refute has_element?(view, "#emergency-number-#{with_number.id}")

    {:ok, admin_view, _html} = live(log_in(conn), ~p"/")

    assert has_element?(admin_view, "#emergency-number-#{with_number.id}", "0151 234567")
    refute has_element?(admin_view, "#emergency-number-#{without.id}")
  end

  test "tapping a photo checks the participant in", %{conn: conn} do
    participant = participant_fixture(%{name: "Tapper", active: true})

    {:ok, view, _html} = live(conn, ~p"/")

    view |> element("#check-in-btn-#{participant.id}") |> render_click()

    assert has_element?(view, "#checked-in-badge-#{participant.id}")
    assert render(view) =~ "1 / 1 present"
  end

  test "the server ignores duplicate check-ins", %{conn: conn} do
    participant = participant_fixture(%{name: "Double Tapper", active: true})

    {:ok, view, _html} = live(conn, ~p"/")

    render_click(view, "check_in", %{"id" => to_string(participant.id)})
    render_click(view, "check_in", %{"id" => to_string(participant.id)})

    assert render(view) =~ "1 / 1 present"
  end

  describe "undoing a check-in" do
    test "tapping a checked-in card prompts for the admin PIN", %{conn: conn} do
      participant = participant_fixture(%{name: "Tapped", active: true})

      {:ok, view, _html} = live(conn, ~p"/")
      view |> element("#check-in-btn-#{participant.id}") |> render_click()

      refute has_element?(view, "#check-out-modal")

      view |> element("#check-in-btn-#{participant.id}") |> render_click()

      assert has_element?(view, "#check-out-modal")
      assert render(view) =~ "Undo check-in for Tapped?"
    end

    test "a wrong PIN keeps the check-in and shows an error", %{conn: conn} do
      participant = participant_fixture(%{active: true})

      {:ok, view, _html} = live(conn, ~p"/")
      view |> element("#check-in-btn-#{participant.id}") |> render_click()
      view |> element("#check-in-btn-#{participant.id}") |> render_click()

      view |> form("#pin-form", %{pin: "0000"}) |> render_submit()

      assert render(view) =~ "Wrong PIN"
      assert has_element?(view, "#check-out-modal")
      assert has_element?(view, "#checked-in-badge-#{participant.id}")
      assert render(view) =~ "1 / 1 present"
    end

    test "the correct PIN removes the check-in", %{conn: conn} do
      participant = participant_fixture(%{active: true})

      {:ok, view, _html} = live(conn, ~p"/")
      view |> element("#check-in-btn-#{participant.id}") |> render_click()
      view |> element("#check-in-btn-#{participant.id}") |> render_click()

      view |> form("#pin-form", %{pin: "1234"}) |> render_submit()

      refute has_element?(view, "#check-out-modal")
      refute has_element?(view, "#checked-in-badge-#{participant.id}")
      assert render(view) =~ "0 / 1 present"
    end

    test "cancel keeps the check-in and closes the modal", %{conn: conn} do
      participant = participant_fixture(%{active: true})

      {:ok, view, _html} = live(conn, ~p"/")
      view |> element("#check-in-btn-#{participant.id}") |> render_click()
      view |> element("#check-in-btn-#{participant.id}") |> render_click()

      view |> element("#check-out-modal button", "Cancel") |> render_click()

      refute has_element?(view, "#check-out-modal")
      assert has_element?(view, "#checked-in-badge-#{participant.id}")
    end

    test "once unlocked, further toggles skip the PIN prompt", %{conn: conn} do
      participant = participant_fixture(%{active: true})
      other = participant_fixture(%{name: "Other", active: true})

      {:ok, view, _html} = live(conn, ~p"/")

      # unlock via a first toggle
      view |> element("#check-in-btn-#{participant.id}") |> render_click()
      view |> element("#check-in-btn-#{participant.id}") |> render_click()
      view |> form("#pin-form", %{pin: "1234"}) |> render_submit()
      assert render(view) =~ "0 / 2 present"

      # second participant toggles without the modal
      view |> element("#check-in-btn-#{other.id}") |> render_click()
      view |> element("#check-in-btn-#{other.id}") |> render_click()

      refute has_element?(view, "#check-out-modal")
      refute has_element?(view, "#checked-in-badge-#{other.id}")
      assert render(view) =~ "0 / 2 present"
    end
  end

  describe "training day selection" do
    alias AttendanceTracker.Tracker

    test "hides the dropdown when no training days are configured", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      refute has_element?(view, "#training-day-select")
    end

    test "pre-selects the training day in progress", %{conn: conn} do
      today_weekday = Date.day_of_week(Tracker.local_today())

      current =
        training_day_fixture(%{
          name: "Kids Judo Today",
          weekday: today_weekday,
          starts_at: ~T[00:00:00],
          ends_at: ~T[23:59:59]
        })

      _other = training_day_fixture(%{weekday: other_weekday(today_weekday)})

      {:ok, view, _html} = live(conn, ~p"/")

      assert has_element?(
               view,
               "#training-day-select option[value='#{current.id}'][selected]"
             )

      # the dropdown shows the alias
      assert render(view) =~ "Kids Judo Today"
    end

    test "switching the training day switches the session", %{conn: conn} do
      today_weekday = Date.day_of_week(Tracker.local_today())

      current =
        training_day_fixture(%{
          weekday: today_weekday,
          starts_at: ~T[00:00:00],
          ends_at: ~T[23:59:59]
        })

      other = training_day_fixture(%{weekday: other_weekday(today_weekday)})
      participant = participant_fixture(%{name: "Switcher", active: true})

      {:ok, view, _html} = live(conn, ~p"/")

      # Check in on the current training day
      view |> element("#check-in-btn-#{participant.id}") |> render_click()
      assert render(view) =~ "1 / 1 present"

      # Switch to the other training day: separate session, nobody checked in
      view
      |> element("#training-day-select")
      |> render_change(%{"training_day_id" => to_string(other.id)})

      assert render(view) =~ "0 / 1 present"
      refute has_element?(view, "#checked-in-badge-#{participant.id}")
      assert has_element?(view, "#training-day-select option[value='#{other.id}'][selected]")

      # Switching back restores the check-in
      view
      |> element("#training-day-select")
      |> render_change(%{"training_day_id" => to_string(current.id)})

      assert render(view) =~ "1 / 1 present"
      assert has_element?(view, "#checked-in-badge-#{participant.id}")
    end

    defp other_weekday(today_weekday), do: rem(today_weekday, 7) + 1
  end

  describe "taking a photo" do
    test "the camera button is hidden outside admin mode", %{conn: conn} do
      participant = participant_fixture(%{name: "No Camera", active: true})

      {:ok, view, _html} = live(conn, ~p"/")

      refute has_element?(view, "#camera-btn-#{participant.id}")
    end

    test "the server ignores the open_camera event outside admin mode", %{conn: conn} do
      participant = participant_fixture(%{name: "No Camera", active: true})

      {:ok, view, _html} = live(conn, ~p"/")

      render_click(view, "open_camera", %{"id" => to_string(participant.id)})

      refute has_element?(view, "#camera-modal")
    end

    test "the camera button opens the camera modal", %{conn: conn} do
      participant = participant_fixture(%{name: "Photo Person", active: true})

      {:ok, view, _html} = live(log_in(conn), ~p"/")

      view |> element("#camera-btn-#{participant.id}") |> render_click()

      assert has_element?(view, "#camera-modal")
      assert render(view) =~ "Take a photo of Photo Person"

      view |> element("#camera-modal button", "Cancel") |> render_click()
      refute has_element?(view, "#camera-modal")
    end

    test "unlocking with the PIN reveals the camera button", %{conn: conn} do
      participant = participant_fixture(%{active: true})

      {:ok, view, _html} = live(conn, ~p"/")
      refute has_element?(view, "#camera-btn-#{participant.id}")

      view |> element("#check-in-btn-#{participant.id}") |> render_click()
      view |> element("#check-in-btn-#{participant.id}") |> render_click()
      view |> form("#pin-form", %{pin: "1234"}) |> render_submit()

      assert has_element?(view, "#camera-btn-#{participant.id}")
    end

    test "a captured photo becomes the participant's photo", %{conn: conn} do
      participant = participant_fixture(%{name: "Snapshot", active: true, photo: nil})

      {:ok, view, _html} = live(log_in(conn), ~p"/")
      view |> element("#camera-btn-#{participant.id}") |> render_click()

      jpeg = Base.encode64(<<255, 216, 255, 224, 1, 2, 3, 255, 217>>)
      render_hook(view, "captured_photo", %{"data" => "data:image/jpeg;base64," <> jpeg})

      photo = AttendanceTracker.Tracker.get_participant!(participant.id).photo
      assert photo =~ ~r"^/uploads/.+\.jpg$"

      on_exit(fn -> File.rm(Path.join([:code.priv_dir(:attendancetracker), "static", photo])) end)

      refute has_element?(view, "#camera-modal")
    end

    test "invalid photo data shows an error", %{conn: conn} do
      participant = participant_fixture(%{name: "Bad Data", active: true})

      {:ok, view, _html} = live(log_in(conn), ~p"/")
      view |> element("#camera-btn-#{participant.id}") |> render_click()

      render_hook(view, "captured_photo", %{"data" => "data:text/plain;base64,aGVsbG8="})

      assert has_element?(view, "#camera-modal")
      assert render(view) =~ "Could not save the photo"
    end
  end
end
