defmodule AttendanceTrackerWeb.PhotoControllerTest do
  use AttendanceTrackerWeb.ConnCase

  import AttendanceTracker.TrackerFixtures

  alias AttendanceTracker.Tracker

  test "returns the photo bytes with the stored content type", %{conn: conn} do
    participant = participant_fixture()
    participant_photo_fixture(participant, %{data: "jpeg-bytes", content_type: "image/png"})

    conn = get(conn, ~p"/photos/#{participant.id}/123")

    assert response(conn, 200) == "jpeg-bytes"
    assert get_resp_header(conn, "content-type") == ["image/png"]
  end

  test "returns 404 when the participant has no photo", %{conn: conn} do
    participant = participant_fixture()

    conn = get(conn, ~p"/photos/#{participant.id}/123")

    assert response(conn, 404) == ""
  end

  test "is forbidden when a session PIN is configured and the client is not authenticated",
       %{conn: conn} do
    participant = participant_fixture()
    participant_photo_fixture(participant)
    {:ok, _} = Tracker.update_session_pin("2468")

    conn = get(conn, ~p"/photos/#{participant.id}/123")

    assert response(conn, 403) == ""
  end

  test "is accessible to a logged-in admin even when a session PIN is configured", %{conn: conn} do
    participant = participant_fixture()
    participant_photo_fixture(participant, %{data: "admin-photo"})
    {:ok, _} = Tracker.update_session_pin("2468")

    conn = conn |> log_in() |> get(~p"/photos/#{participant.id}/123")

    assert response(conn, 200) == "admin-photo"
  end
end
