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

  test "preview reports new members and skips existing ones" do
    training_fixture(%{name: "Kids Judo"})
    _ada = participant_fixture(%{name: "Ada Lovelace"})
    {:ok, _} = Directory.save_settings("fake", %{"token" => "x"})

    assert {:ok, preview} = Directory.preview()
    assert preview.total == 2
    assert preview.skipped == 1
    assert [%{name: "Grace Hopper", phone: "079 222"}] = preview.new

    assert_received {:fake_fetch, ["Kids Judo"], %{"token" => "x"}}
  end

  test "import_members creates participants for new members and skips existing ones" do
    _ada = participant_fixture(%{name: "Ada Lovelace"})

    assert {:ok, %{created: 1, skipped: 1}} =
             Directory.import_members([
               %{name: "Ada Lovelace", phone: "079 111"},
               %{name: "Grace Hopper", phone: "079 222"}
             ])

    participants = Tracker.list_participants()
    names = Enum.map(participants, & &1.name)

    assert "Grace Hopper" in names
    assert Enum.count(participants, &(&1.name == "Ada Lovelace")) == 1

    grace = Enum.find(participants, &(&1.name == "Grace Hopper"))
    assert grace.emergency_number == "079 222"
    assert grace.active
  end
end
