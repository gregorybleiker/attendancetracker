defmodule AttendanceTrackerWeb.TrainingLiveTest do
  use AttendanceTrackerWeb.ConnCase

  import Phoenix.LiveViewTest
  import AttendanceTracker.TrackerFixtures

  setup %{conn: conn} do
    %{conn: log_in(conn)}
  end

  defp create_training(_context) do
    %{training: training_fixture()}
  end

  describe "Index" do
    setup [:create_training]

    test "lists all trainings", %{conn: conn} do
      training_fixture(%{name: "Kids Judo Wednesday", weekday: 3})

      {:ok, _view, html} = live(conn, ~p"/training")

      assert html =~ "Training"
      assert html =~ "Monday"
      assert html =~ "19:00–21:30"
      assert html =~ "Kids Judo Wednesday"
    end

    test "deletes a training", %{conn: conn, training: training} do
      {:ok, view, _html} = live(conn, ~p"/training")

      view
      |> element("#trainings-#{training.id} a", "Delete")
      |> render_click()

      refute has_element?(view, "#trainings-#{training.id}")
    end
  end

  describe "Form" do
    test "creates a training", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/training/new")

      view
      |> form("#training-form",
        training: %{
          name: "Kids Judo Wednesday",
          weekday: "3",
          starts_at: "18:00",
          ends_at: "20:00"
        }
      )
      |> render_submit()

      {path, _flash} = assert_redirect(view)
      assert path == ~p"/training"

      {:ok, _view, html} = live(conn, ~p"/training")
      assert html =~ "Kids Judo Wednesday"
      assert html =~ "Wednesday"
      assert html =~ "18:00–20:00"
    end

    test "shows validation errors", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/training/new")

      html =
        view
        |> form("#training-form",
          training: %{weekday: "1", starts_at: "19:00", ends_at: "18:00"}
        )
        |> render_change()

      assert html =~ "must be after the start time"
    end

    test "updates a training", %{conn: conn} do
      training = training_fixture()

      {:ok, view, _html} = live(conn, ~p"/training/#{training}/edit")

      view
      |> form("#training-form",
        training: %{weekday: "5", starts_at: "20:00", ends_at: "22:00"}
      )
      |> render_submit()

      {path, _flash} = assert_redirect(view)
      assert path == ~p"/training"

      {:ok, _view, html} = live(conn, ~p"/training")
      assert html =~ "Friday"
      assert html =~ "20:00–22:00"
    end
  end
end
