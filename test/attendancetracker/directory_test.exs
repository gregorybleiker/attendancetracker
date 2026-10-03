defmodule AttendanceTracker.DirectoryTest do
  use AttendanceTracker.DataCase

  alias AttendanceTracker.Directory
  alias AttendanceTracker.Directory.FakeSource
  alias AttendanceTracker.Tracker

  import AttendanceTracker.TrackerFixtures

  setup do
    Application.put_env(:attendancetracker, :directory_sources, %{"fake" => FakeSource})

    on_exit(fn ->
      Application.delete_env(:attendancetracker, :directory_sources)
    end)

    :ok
  end

  test "change_settings pre-fills defaults and validates the connector" do
    changeset = Directory.change_settings("fake")

    assert changeset.valid?
    assert Ecto.Changeset.get_field(changeset, :token) == ""
    assert Ecto.Changeset.get_field(changeset, :source) == "fake"
  end

  test "save_settings stores the connector and its configuration" do
    assert {:ok, "fake"} = Directory.save_settings("fake", %{"token" => "s3cret"})

    assert Directory.source() == "fake"
    assert Directory.config("fake") == %{"token" => "s3cret"}
  end

  test "save_settings rejects an unknown connector" do
    assert {:error, :unknown_source} = Directory.save_settings("nope", %{})
  end

  test "preview requires a named training" do
    assert {:error, :no_named_trainings} = Directory.preview()
  end

  test "preview reports new members and matches existing ones" do
    training_fixture(%{name: "Kids Judo"})
    _ada = participant_fixture(%{name: "Ada Lovelace"})
    {:ok, _} = Directory.save_settings("fake", %{"token" => "x"})

    assert {:ok, preview} = Directory.preview()
    assert preview.total == 2
    assert [%{name: "Ada Lovelace"}] = preview.existing
    assert [%{name: "Grace Hopper", phone: "079 222"}] = preview.new

    assert_received {:fake_fetch, ["Kids Judo"], %{"token" => "x"}}
  end

  test "import_members creates new members and flags matched ones as Webling" do
    ada = participant_fixture(%{name: "Ada Lovelace"})
    refute AttendanceTracker.Tracker.Participant.webling?(ada)

    assert {:ok, %{created: 1, linked: 1}} =
             Directory.import_members(%{
               new: [
                 %{
                   name: "Grace Hopper",
                   first_name: "Grace",
                   last_name: "Hopper",
                   phone: "079 222"
                 }
               ],
               existing: [%{name: "Ada Lovelace", first_name: "Ada", last_name: "Lovelace"}]
             })

    participants = Tracker.list_participants()
    names = Enum.map(participants, &AttendanceTracker.Tracker.Participant.full_name(&1))

    assert "Grace Hopper" in names

    assert Enum.count(
             participants,
             &(AttendanceTracker.Tracker.Participant.full_name(&1) == "Ada Lovelace")
           ) == 1

    grace =
      Enum.find(
        participants,
        &(AttendanceTracker.Tracker.Participant.full_name(&1) == "Grace Hopper")
      )

    assert grace.emergency_number == "079 222"
    assert grace.active
    assert grace.source == "webling"

    ada = Tracker.get_participant!(ada.id)
    assert ada.source == "webling"
  end

  test "preview and import write program logs" do
    training_fixture(%{name: "Kids Judo"})
    {:ok, _} = Directory.save_settings("fake", %{"token" => "x"})

    {:ok, preview} = Directory.preview()
    {:ok, _} = Directory.import_members(preview)

    commands = AttendanceTracker.Logs.list_program_logs() |> Enum.map(& &1.command)

    assert "fetch_members" in commands
    assert "import" in commands
  end
end
