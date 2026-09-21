defmodule AttendanceTrackerWeb.ReportControllerTest do
  use AttendanceTrackerWeb.ConnCase

  import AttendanceTracker.TrackerFixtures

  setup %{conn: conn} do
    %{conn: log_in(conn)}
  end

  test "downloads the year's trainings, dates and participants as one CSV", %{conn: conn} do
    training_day =
      training_day_fixture(%{
        name: "Kids Judo Monday",
        weekday: 1,
        starts_at: ~T[19:00:00],
        ends_at: ~T[21:30:00]
      })

    session = training_session_fixture(%{date: ~D[2026-01-05], training_day_id: training_day.id})

    check_in_fixture(%{
      participant: participant_fixture(%{name: "Alex Rivera"}),
      training_session: session
    })

    check_in_fixture(%{
      participant: participant_fixture(%{name: "Sam Chen"}),
      training_session: session
    })

    conn = get(conn, ~p"/reporting/download?year=2026")

    assert get_resp_header(conn, "content-type") == ["text/csv; charset=utf-8"]

    assert [~s(attachment; filename="attendance-2026.csv")] =
             get_resp_header(conn, "content-disposition")

    body = response(conn, 200)
    assert body =~ "training,date,participants"
    assert body =~ "Kids Judo Monday · 19:00–21:30,2026-01-05,Alex Rivera; Sam Chen"
  end

  test "excludes sessions outside the selected year", %{conn: conn} do
    training_session_fixture(%{date: ~D[2025-12-31]})

    conn = get(conn, ~p"/reporting/download?year=2026")

    refute response(conn, 200) =~ "2025-12-31"
  end

  test "labels ad-hoc sessions", %{conn: conn} do
    session = training_session_fixture(%{date: ~D[2026-02-02]})

    check_in_fixture(%{
      participant: participant_fixture(%{name: "Robin Solo"}),
      training_session: session
    })

    conn = get(conn, ~p"/reporting/download?year=2026")

    assert response(conn, 200) =~ "Ad-hoc training,2026-02-02,Robin Solo"
  end

  test "escapes commas and quotes in values", %{conn: conn} do
    session = training_session_fixture(%{date: ~D[2026-02-02]})

    check_in_fixture(%{
      participant: participant_fixture(%{name: ~s(Doe, "Jane")}),
      training_session: session
    })

    conn = get(conn, ~p"/reporting/download?year=2026")

    assert response(conn, 200) =~ ~s("Doe, ""Jane""")
  end

  test "rejects an invalid year", %{conn: conn} do
    conn = get(conn, ~p"/reporting/download?year=abc")

    assert redirected_to(conn) == ~p"/reporting"
  end
end
