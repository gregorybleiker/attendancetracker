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

  test "preview reports the trainings that will be created" do
    training_fixture(%{name: "Kids Judo"})
    {:ok, _} = Directory.save_settings("fake", %{"token" => "x"})

    assert {:ok, preview} = Directory.preview()
    assert preview.new_trainings == ["Kung Fu"]
  end

  test "preview reports new members and matches existing ones" do
    training_fixture(%{name: "Kids Judo"})
    _ada = participant_fixture(%{name: "Ada Lovelace"})
    {:ok, _} = Directory.save_settings("fake", %{"token" => "x"})

    assert {:ok, preview} = Directory.preview()
    assert preview.total == 2
    assert [%{name: "Ada Lovelace"}] = preview.existing
    assert [%{name: "Grace Hopper", phone: "079 222"}] = preview.new
    assert preview.new_trainings == ["Kung Fu"]

    assert_received {:fake_fetch, %{"token" => "x"}}
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

  test "import_members creates missing trainings with default schedule" do
    training_fixture(%{name: "Kids Judo"})
    {:ok, _} = Directory.save_settings("fake", %{"token" => "x"})

    {:ok, preview} = Directory.preview()

    assert {:ok, %{trainings_created: 1}} = Directory.import_members(preview)

    training = Enum.find(Tracker.list_trainings(), &(&1.name == "Kung Fu"))
    assert training.weekday == 1
    assert training.starts_at == ~T[19:00:00]
    assert training.ends_at == ~T[21:30:00]
  end

  test "import_members links members to the trainings in their training field" do
    training_fixture(%{name: "Kids Judo"})
    {:ok, _} = Directory.save_settings("fake", %{"token" => "x"})

    {:ok, preview} = Directory.preview()
    assert {:ok, %{memberships: 2}} = Directory.import_members(preview)

    kids_judo = Enum.find(Tracker.list_trainings(), &(&1.name == "Kids Judo"))
    kung_fu = Enum.find(Tracker.list_trainings(), &(&1.name == "Kung Fu"))

    assert member_names(kids_judo) == ["Ada Lovelace"]
    assert member_names(kung_fu) == ["Grace Hopper"]
  end

  defp member_names(training) do
    Tracker.list_training_members(training)
    |> Enum.map(&AttendanceTracker.Tracker.Participant.full_name/1)
  end

  test "import_members adds trainings even to members that already exist" do
    training_fixture(%{name: "Kids Judo"})
    ada = participant_fixture(%{name: "Ada Lovelace"})
    {:ok, _} = Directory.save_settings("fake", %{"token" => "x"})

    {:ok, preview} = Directory.preview()
    assert [%{name: "Ada Lovelace"}] = preview.existing

    {:ok, _} = Directory.import_members(preview)

    kids_judo = Enum.find(Tracker.list_trainings(), &(&1.name == "Kids Judo"))
    assert Enum.map(Tracker.list_training_members(kids_judo), & &1.id) == [ada.id]
  end

  test "import_members only adds memberships, never removes existing ones" do
    legacy = training_fixture(%{name: "Legacy Class", weekday: 2})
    alan = participant_fixture(%{name: "Alan Turing"})
    {:ok, :created} = Tracker.add_training_member(legacy, alan)

    {:ok, _} = Directory.save_settings("fake", %{"token" => "x"})
    {:ok, preview} = Directory.preview()
    {:ok, _} = Directory.import_members(preview)

    kung_fu = Enum.find(Tracker.list_trainings(), &(&1.name == "Kung Fu"))
    assert member_names(kung_fu) == ["Grace Hopper"]
    assert Enum.map(Tracker.list_training_members(legacy), & &1.id) == [alan.id]
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
