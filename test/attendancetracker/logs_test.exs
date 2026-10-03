defmodule AttendanceTracker.LogsTest do
  use AttendanceTracker.DataCase

  alias AttendanceTracker.Logs

  test "writes audit entries newest first" do
    assert {:ok, _} =
             Logs.audit(%{
               action: "check_in",
               participant_id: 1,
               participant_name: "Ada",
               training_session_id: 5
             })

    assert [%{action: "check_in", participant_name: "Ada", training_session_id: 5}] =
             Logs.list_audit_logs()
  end

  test "writes program entries" do
    assert {:ok, _} =
             Logs.program(%{
               source: "webling",
               command: "fetch_members",
               status: "ok",
               request: "GET /member",
               result: "3 members"
             })

    assert [%{command: "fetch_members", status: "ok", result: "3 members"}] =
             Logs.list_program_logs()
  end

  test "caps the audit log at the configured maximum, dropping the oldest" do
    :ok = Logs.update_settings(5, 60)

    for i <- 1..12, do: Logs.audit(%{action: "check_in", participant_name: "P#{i}"})

    logs = Logs.list_audit_logs()
    assert length(logs) == 5
    assert hd(logs).participant_name == "P12"
    refute Enum.any?(logs, &(&1.participant_name == "P7"))
  end

  test "caps the program log independently" do
    :ok = Logs.update_settings(3, 60)

    for i <- 1..6, do: Logs.program(%{command: "sync", status: "ok", result: "#{i}"})

    assert length(Logs.list_program_logs()) == 3
  end

  test "settings default to 10000 entries and a 60 minute interval" do
    assert Logs.max_entries() == 10_000
    assert Logs.prune_interval_minutes() == 60
    assert Logs.prune_interval_seconds() == 3600
  end

  test "validates the settings" do
    assert Logs.change_settings(%{max_entries: 100, prune_interval_minutes: 30}).valid?
    refute Logs.change_settings(%{max_entries: 0, prune_interval_minutes: 30}).valid?
    refute Logs.change_settings(%{max_entries: 100, prune_interval_minutes: 0}).valid?
  end
end
