defmodule AttendanceTrackerWeb.ParticipantLiveTest do
  use AttendanceTrackerWeb.ConnCase

  import Phoenix.LiveViewTest
  import AttendanceTracker.TrackerFixtures

  @create_attrs %{active: true, name: "some name", emergency_number: "0151 234567"}
  @update_attrs %{active: false, name: "some updated name", emergency_number: "0160 987654"}
  @invalid_attrs %{active: false, name: nil}

  setup %{conn: conn} do
    %{conn: log_in(conn)}
  end

  defp create_participant(_) do
    participant = participant_fixture()

    %{participant: participant}
  end

  describe "Index" do
    setup [:create_participant]

    test "lists all participants", %{conn: conn, participant: participant} do
      {:ok, _index_live, html} = live(conn, ~p"/participants")

      assert html =~ "Listing Participants"
      assert html =~ participant.name
    end

    test "shows the Webling/local source badge", %{conn: conn} do
      webling = participant_fixture(%{name: "From Webling", source: "webling"})
      local = participant_fixture(%{name: "Local Only"})

      {:ok, view, _html} = live(conn, ~p"/participants")

      assert has_element?(view, "#source-webling-#{webling.id}")
      assert has_element?(view, "#source-local-#{local.id}")
    end

    test "saves new participant", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/participants")

      assert {:ok, form_live, _} =
               index_live
               |> element("a", "New Participant")
               |> render_click()
               |> follow_redirect(conn, ~p"/participants/new")

      assert render(form_live) =~ "New Participant"

      assert form_live
             |> form("#participant-form", participant: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#participant-form", participant: @create_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/participants")

      html = render(index_live)
      assert html =~ "Participant created successfully"
      assert html =~ "some name"
    end

    test "updates participant in listing", %{conn: conn, participant: participant} do
      {:ok, index_live, _html} = live(conn, ~p"/participants")

      assert {:ok, form_live, _html} =
               index_live
               |> element("#participants-#{participant.id} a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/participants/#{participant}/edit")

      assert render(form_live) =~ "Edit Participant"

      assert form_live
             |> form("#participant-form", participant: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, index_live, _html} =
               form_live
               |> form("#participant-form", participant: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/participants")

      html = render(index_live)
      assert html =~ "Participant updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes participant in listing", %{conn: conn, participant: participant} do
      {:ok, index_live, _html} = live(conn, ~p"/participants")

      assert index_live
             |> element("#participants-#{participant.id} a", "Delete")
             |> render_click()

      refute has_element?(index_live, "#participants-#{participant.id}")
    end
  end

  describe "Show" do
    setup [:create_participant]

    test "displays participant", %{conn: conn, participant: participant} do
      {:ok, _show_live, html} = live(conn, ~p"/participants/#{participant}")

      assert html =~ "Show Participant"
      assert html =~ participant.name
    end

    test "updates participant and returns to show", %{conn: conn, participant: participant} do
      {:ok, show_live, _html} = live(conn, ~p"/participants/#{participant}")

      assert {:ok, form_live, _} =
               show_live
               |> element("a", "Edit")
               |> render_click()
               |> follow_redirect(conn, ~p"/participants/#{participant}/edit?return_to=show")

      assert render(form_live) =~ "Edit Participant"

      assert form_live
             |> form("#participant-form", participant: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert {:ok, show_live, _html} =
               form_live
               |> form("#participant-form", participant: @update_attrs)
               |> render_submit()
               |> follow_redirect(conn, ~p"/participants/#{participant}")

      html = render(show_live)
      assert html =~ "Participant updated successfully"
      assert html =~ "some updated name"
      assert html =~ "0160 987654"
    end
  end
end
