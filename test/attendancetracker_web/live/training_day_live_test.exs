defmodule AttendanceTrackerWeb.TrainingDayLiveTest do
  use AttendanceTrackerWeb.ConnCase

  import Phoenix.LiveViewTest
  import AttendanceTracker.TrackerFixtures

  defp create_training_day(_context) do
    %{training_day: training_day_fixture()}
  end

  describe "Index" do
    setup [:create_training_day]

    test "lists all training days", %{conn: conn} do
      training_day_fixture(%{name: "Kids Judo Wednesday", weekday: 3})

      {:ok, _view, html} = live(conn, ~p"/training_days")

      assert html =~ "Training days"
      assert html =~ "Monday"
      assert html =~ "19:00–21:30"
      assert html =~ "Kids Judo Wednesday"
    end

    test "deletes a training day", %{conn: conn, training_day: training_day} do
      {:ok, view, _html} = live(conn, ~p"/training_days")

      view
      |> element("#training_days-#{training_day.id} a", "Delete")
      |> render_click()

      refute has_element?(view, "#training_days-#{training_day.id}")
    end
  end

  describe "Form" do
    test "creates a training day", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/training_days/new")

      view
      |> form("#training-day-form",
        training_day: %{
          name: "Kids Judo Wednesday",
          weekday: "3",
          starts_at: "18:00",
          ends_at: "20:00"
        }
      )
      |> render_submit()

      {path, _flash} = assert_redirect(view)
      assert path == ~p"/training_days"

      {:ok, _view, html} = live(conn, ~p"/training_days")
      assert html =~ "Kids Judo Wednesday"
      assert html =~ "Wednesday"
      assert html =~ "18:00–20:00"
    end

    test "shows validation errors", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/training_days/new")

      html =
        view
        |> form("#training-day-form",
          training_day: %{weekday: "1", starts_at: "19:00", ends_at: "18:00"}
        )
        |> render_change()

      assert html =~ "must be after the start time"
    end

    test "updates a training day", %{conn: conn} do
      training_day = training_day_fixture()

      {:ok, view, _html} = live(conn, ~p"/training_days/#{training_day}/edit")

      view
      |> form("#training-day-form",
        training_day: %{weekday: "5", starts_at: "20:00", ends_at: "22:00"}
      )
      |> render_submit()

      {path, _flash} = assert_redirect(view)
      assert path == ~p"/training_days"

      {:ok, _view, html} = live(conn, ~p"/training_days")
      assert html =~ "Friday"
      assert html =~ "20:00–22:00"
    end
  end
end
