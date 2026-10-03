defmodule AttendanceTracker.DuplicatesTest do
  use AttendanceTracker.DataCase

  alias AttendanceTracker.Duplicates
  alias AttendanceTracker.Logs
  alias AttendanceTracker.Tracker
  alias AttendanceTracker.Tracker.Participant

  import AttendanceTracker.TrackerFixtures

  test "detects an incomplete name matching a full name" do
    participant_fixture(%{first_name: "Ada", last_name: "Lovelace"})
    participant_fixture(%{first_name: "Ada", last_name: ""})

    assert [%{survivor: survivor, duplicate: duplicate}] = Duplicates.list_candidates()
    assert Participant.full_name(survivor) == "Ada Lovelace"
    assert Participant.full_name(duplicate) == "Ada"
  end

  test "detects a last-name-only entry via substring match" do
    participant_fixture(%{first_name: "Ada", last_name: "Lovelace"})
    participant_fixture(%{first_name: "", last_name: "Love"})

    assert [%{survivor: %{}, duplicate: %{}}] = Duplicates.list_candidates()
  end

  test "ignores unrelated names" do
    participant_fixture(%{first_name: "Ada", last_name: "Lovelace"})
    participant_fixture(%{first_name: "Bob", last_name: ""})

    assert Duplicates.list_candidates() == []
  end

  test "merge applies values, moves check-ins, flags webling and deletes the duplicate" do
    survivor = participant_fixture(%{first_name: "Ada", last_name: "Lovelace"})
    duplicate = participant_fixture(%{first_name: "Ada", last_name: "", source: "webling"})

    session = training_session_fixture()
    _ = check_in_fixture(%{participant: duplicate, training_session: session})

    assert {:ok, merged} =
             Duplicates.merge(survivor, duplicate, %{
               "first_name" => "Ada",
               "last_name" => "Lovelace",
               "emergency_number" => "079 111",
               "active" => "true"
             })

    assert merged.emergency_number == "079 111"
    assert merged.source == "webling"

    assert_raise Ecto.NoResultsError, fn -> Tracker.get_participant!(duplicate.id) end

    assert Enum.any?(
             Tracker.list_check_ins(),
             &(&1.participant_id == survivor.id and &1.training_session_id == session.id)
           )
  end

  test "keeps the survivor's check-in when both attended the same session" do
    survivor = participant_fixture(%{first_name: "Ada", last_name: "Lovelace"})
    duplicate = participant_fixture(%{first_name: "Ada", last_name: ""})

    session = training_session_fixture()
    _ = check_in_fixture(%{participant: survivor, training_session: session})
    _ = check_in_fixture(%{participant: duplicate, training_session: session})

    assert {:ok, _} =
             Duplicates.merge(survivor, duplicate, %{
               "first_name" => "Ada",
               "last_name" => "Lovelace"
             })

    check_ins = Tracker.list_check_ins()
    assert Enum.count(check_ins, &(&1.training_session_id == session.id)) == 1
    assert hd(check_ins).participant_id == survivor.id
  end

  test "moves the duplicate's photo when the survivor has none" do
    survivor = participant_fixture(%{first_name: "Ada", last_name: "Lovelace"})
    duplicate = participant_fixture(%{first_name: "Ada", last_name: ""})
    participant_photo_fixture(duplicate, %{data: "dup-photo"})

    assert {:ok, _} =
             Duplicates.merge(survivor, duplicate, %{
               "first_name" => "Ada",
               "last_name" => "Lovelace"
             })

    assert Tracker.get_participant_photo(survivor.id).data == "dup-photo"
    assert Tracker.get_participant_photo(duplicate.id) == nil
  end

  test "writes an audit log entry" do
    survivor = participant_fixture(%{first_name: "Ada", last_name: "Lovelace"})
    duplicate = participant_fixture(%{first_name: "Ada", last_name: ""})

    assert {:ok, _} =
             Duplicates.merge(survivor, duplicate, %{
               "first_name" => "Ada",
               "last_name" => "Lovelace"
             })

    assert [%{action: "merge", participant_name: "Ada Lovelace"}] = Logs.list_audit_logs()
  end
end
