defmodule AttendanceTracker.TrackerTest do
  use AttendanceTracker.DataCase

  alias AttendanceTracker.Tracker

  describe "participants" do
    alias AttendanceTracker.Tracker.Participant

    import AttendanceTracker.TrackerFixtures

    @invalid_attrs %{active: nil, name: nil}

    test "list_participants/0 returns all participants" do
      participant = participant_fixture()
      assert Tracker.list_participants() == [participant]
    end

    test "get_participant!/1 returns the participant with given id" do
      participant = participant_fixture()
      assert Tracker.get_participant!(participant.id) == participant
    end

    test "create_participant/1 with valid data creates a participant" do
      valid_attrs = %{active: true, name: "some name"}

      assert {:ok, %Participant{} = participant} = Tracker.create_participant(valid_attrs)
      assert participant.active == true
      assert participant.name == "some name"
    end

    test "create_participant/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Tracker.create_participant(@invalid_attrs)
    end

    test "update_participant/2 with valid data updates the participant" do
      participant = participant_fixture()
      update_attrs = %{active: false, name: "some updated name"}

      assert {:ok, %Participant{} = participant} =
               Tracker.update_participant(participant, update_attrs)

      assert participant.active == false
      assert participant.name == "some updated name"
    end

    test "update_participant/2 with invalid data returns error changeset" do
      participant = participant_fixture()
      assert {:error, %Ecto.Changeset{}} = Tracker.update_participant(participant, @invalid_attrs)
      assert participant == Tracker.get_participant!(participant.id)
    end

    test "delete_participant/1 deletes the participant" do
      participant = participant_fixture()
      assert {:ok, %Participant{}} = Tracker.delete_participant(participant)
      assert_raise Ecto.NoResultsError, fn -> Tracker.get_participant!(participant.id) end
    end

    test "change_participant/1 returns a participant changeset" do
      participant = participant_fixture()
      assert %Ecto.Changeset{} = Tracker.change_participant(participant)
    end

    test "put_participant_photo/3 stores the bytes and flags the participant" do
      participant = participant_fixture()

      assert {:ok, photo} = Tracker.put_participant_photo(participant, "bytes", "image/png")
      assert photo.data == "bytes"
      assert photo.content_type == "image/png"

      reloaded = Tracker.get_participant!(participant.id)
      assert reloaded.has_photo
      assert %DateTime{} = reloaded.photo_updated_at
      assert Tracker.get_participant_photo(participant.id).data == "bytes"
    end

    test "put_participant_photo/3 replaces an existing photo" do
      participant = participant_fixture()
      {:ok, _} = Tracker.put_participant_photo(participant, "old", "image/jpeg")

      assert {:ok, photo} = Tracker.put_participant_photo(participant, "new", "image/webp")
      assert photo.data == "new"
      assert Tracker.get_participant_photo(participant.id).content_type == "image/webp"
    end

    test "get_participant_photo/1 returns nil and has_photo is false without a photo" do
      participant = participant_fixture()
      assert Tracker.get_participant_photo(participant.id) == nil
      refute Tracker.get_participant!(participant.id).has_photo
    end
  end

  describe "trainings" do
    alias AttendanceTracker.Tracker.Training

    import AttendanceTracker.TrackerFixtures

    @invalid_attrs %{weekday: nil, starts_at: nil, ends_at: nil}

    test "list_trainings/0 returns all trainings ordered by weekday and start time" do
      wednesday = training_fixture(%{weekday: 3})
      monday_evening = training_fixture(%{weekday: 1, starts_at: ~T[19:00:00]})
      monday_morning = training_fixture(%{weekday: 1, starts_at: ~T[08:00:00]})

      assert Tracker.list_trainings() == [monday_morning, monday_evening, wednesday]
    end

    test "get_training!/1 returns the training with given id" do
      training = training_fixture()
      assert Tracker.get_training!(training.id) == training
    end

    test "create_training/1 with valid data creates a training" do
      valid_attrs = %{weekday: 1, starts_at: ~T[19:00:00], ends_at: ~T[21:30:00]}

      assert {:ok, %Training{} = training} = Tracker.create_training(valid_attrs)
      assert training.weekday == 1
      assert training.starts_at == ~T[19:00:00]
      assert training.ends_at == ~T[21:30:00]
    end

    test "create_training/1 with an alias creates a training" do
      valid_attrs = %{
        name: "Kids Judo Monday",
        weekday: 1,
        starts_at: ~T[19:00:00],
        ends_at: ~T[21:30:00]
      }

      assert {:ok, %Training{} = training} = Tracker.create_training(valid_attrs)
      assert training.name == "Kids Judo Monday"
    end

    test "create_training/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Tracker.create_training(@invalid_attrs)
    end

    test "create_training/1 requires the end to be after the start" do
      attrs = %{weekday: 1, starts_at: ~T[19:00:00], ends_at: ~T[18:00:00]}

      assert {:error, %Ecto.Changeset{} = changeset} = Tracker.create_training(attrs)
      assert "must be after the start time" in errors_on(changeset).ends_at
    end

    test "create_training/1 validates the weekday range" do
      attrs = %{weekday: 8, starts_at: ~T[19:00:00], ends_at: ~T[21:30:00]}

      assert {:error, %Ecto.Changeset{} = changeset} = Tracker.create_training(attrs)
      assert errors_on(changeset).weekday != []
    end

    test "update_training/2 with valid data updates the training" do
      training = training_fixture()
      update_attrs = %{weekday: 4, starts_at: ~T[18:00:00], ends_at: ~T[20:00:00]}

      assert {:ok, %Training{} = training} =
               Tracker.update_training(training, update_attrs)

      assert training.weekday == 4
      assert training.starts_at == ~T[18:00:00]
      assert training.ends_at == ~T[20:00:00]
    end

    test "update_training/2 with invalid data returns error changeset" do
      training = training_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Tracker.update_training(training, @invalid_attrs)

      assert training == Tracker.get_training!(training.id)
    end

    test "delete_training/1 deletes the training" do
      training = training_fixture()
      assert {:ok, %Training{}} = Tracker.delete_training(training)
      assert_raise Ecto.NoResultsError, fn -> Tracker.get_training!(training.id) end
    end

    test "change_training/1 returns a training changeset" do
      training = training_fixture()
      assert %Ecto.Changeset{} = Tracker.change_training(training)
    end
  end

  describe "training schedule" do
    alias AttendanceTracker.Tracker.Training

    import AttendanceTracker.TrackerFixtures

    # 2026-09-14 is a Monday, 2026-09-16 a Wednesday, 2026-09-20 a Sunday.

    test "label/1 falls back to the weekday and time range" do
      training = %Training{weekday: 1, starts_at: ~T[19:00:00], ends_at: ~T[21:30:00]}
      assert Training.label(training) == "Monday · 19:00–21:30"
    end

    test "label/1 prefers the alias when set" do
      training = %Training{
        name: "Kids Judo Monday",
        weekday: 1,
        starts_at: ~T[19:00:00],
        ends_at: ~T[21:30:00]
      }

      assert Training.label(training) == "Kids Judo Monday · 19:00–21:30"

      assert Training.label(%{training | name: ""}) == "Monday · 19:00–21:30"
    end

    test "occurrence_on_or_before/2 returns the same date on the training weekday" do
      training = %Training{weekday: 1}
      assert Training.occurrence_on_or_before(training, ~D[2026-09-14]) == ~D[2026-09-14]
    end

    test "occurrence_on_or_before/2 returns the most recent past occurrence" do
      training = %Training{weekday: 1}
      assert Training.occurrence_on_or_before(training, ~D[2026-09-16]) == ~D[2026-09-14]
      assert Training.occurrence_on_or_before(training, ~D[2026-09-20]) == ~D[2026-09-14]
    end

    test "in_progress?/3 checks weekday and time window" do
      training = %Training{weekday: 1, starts_at: ~T[19:00:00], ends_at: ~T[21:30:00]}

      assert Training.in_progress?(training, ~D[2026-09-14], ~T[19:00:00])
      assert Training.in_progress?(training, ~D[2026-09-14], ~T[21:30:00])
      refute Training.in_progress?(training, ~D[2026-09-14], ~T[18:59:00])
      refute Training.in_progress?(training, ~D[2026-09-14], ~T[21:31:00])
      refute Training.in_progress?(training, ~D[2026-09-16], ~T[20:00:00])
    end

    test "current_training/3 returns nil for an empty list" do
      assert Tracker.current_training([], ~D[2026-09-14], ~T[20:00:00]) == nil
    end

    test "current_training/3 picks the training in progress" do
      monday = training_fixture(%{weekday: 1, starts_at: ~T[19:00:00], ends_at: ~T[21:30:00]})
      _wednesday = training_fixture(%{weekday: 3})

      assert Tracker.current_training([monday], ~D[2026-09-14], ~T[20:00:00]) == monday
    end

    test "current_training/3 picks the soonest upcoming training of the day" do
      morning =
        training_fixture(%{weekday: 1, starts_at: ~T[08:00:00], ends_at: ~T[09:00:00]})

      evening =
        training_fixture(%{weekday: 1, starts_at: ~T[19:00:00], ends_at: ~T[21:30:00]})

      past = training_fixture(%{weekday: 6, starts_at: ~T[10:00:00], ends_at: ~T[12:00:00]})

      # Sunday 07:00: both Monday trainings are upcoming tomorrow... none today,
      # so the most recently started one (Saturday) wins.
      assert Tracker.current_training([morning, evening, past], ~D[2026-09-20], ~T[07:00:00]) ==
               past

      # Monday 07:00: the morning training starts later today.
      assert Tracker.current_training([morning, evening, past], ~D[2026-09-14], ~T[07:00:00]) ==
               morning

      # Monday 10:00: only the evening training is still upcoming today.
      assert Tracker.current_training([morning, evening, past], ~D[2026-09-14], ~T[10:00:00]) ==
               evening
    end

    test "current_training/3 falls back to the most recently started training" do
      monday = training_fixture(%{weekday: 1, starts_at: ~T[19:00:00], ends_at: ~T[21:30:00]})

      wednesday =
        training_fixture(%{weekday: 3, starts_at: ~T[18:00:00], ends_at: ~T[20:00:00]})

      # Sunday: Wednesday's occurrence is more recent than Monday's.
      assert Tracker.current_training([monday, wednesday], ~D[2026-09-20], ~T[12:00:00]) ==
               wednesday

      # Wednesday 21:00, after the training ended: Wednesday wins over Monday.
      assert Tracker.current_training([monday, wednesday], ~D[2026-09-16], ~T[21:00:00]) ==
               wednesday
    end

    test "session_for_training/2 gets or creates a session per training and date" do
      monday = training_fixture(%{weekday: 1})
      other_monday = training_fixture(%{weekday: 1, starts_at: ~T[08:00:00]})

      session = Tracker.session_for_training(monday, ~D[2026-09-14])
      assert session.date == ~D[2026-09-14]
      assert session.training_id == monday.id

      # Idempotent
      assert Tracker.session_for_training(monday, ~D[2026-09-14]).id == session.id

      # Same date, different training: separate sessions
      other_session = Tracker.session_for_training(other_monday, ~D[2026-09-14])
      assert other_session.id != session.id
    end
  end

  describe "training_sessions" do
    alias AttendanceTracker.Tracker.TrainingSession

    import AttendanceTracker.TrackerFixtures

    @invalid_attrs %{date: nil}

    test "list_training_sessions/0 returns all training_sessions" do
      training_session = training_session_fixture()
      assert Tracker.list_training_sessions() == [training_session]
    end

    test "get_training_session!/1 returns the training_session with given id" do
      training_session = training_session_fixture()
      assert Tracker.get_training_session!(training_session.id) == training_session
    end

    test "create_training_session/1 with valid data creates a training_session" do
      valid_attrs = %{date: ~D[2026-09-14]}

      assert {:ok, %TrainingSession{} = training_session} =
               Tracker.create_training_session(valid_attrs)

      assert training_session.date == ~D[2026-09-14]
    end

    test "create_training_session/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Tracker.create_training_session(@invalid_attrs)
    end

    test "update_training_session/2 with valid data updates the training_session" do
      training_session = training_session_fixture()
      update_attrs = %{date: ~D[2026-09-15]}

      assert {:ok, %TrainingSession{} = training_session} =
               Tracker.update_training_session(training_session, update_attrs)

      assert training_session.date == ~D[2026-09-15]
    end

    test "update_training_session/2 with invalid data returns error changeset" do
      training_session = training_session_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Tracker.update_training_session(training_session, @invalid_attrs)

      assert training_session == Tracker.get_training_session!(training_session.id)
    end

    test "delete_training_session/1 deletes the training_session" do
      training_session = training_session_fixture()
      assert {:ok, %TrainingSession{}} = Tracker.delete_training_session(training_session)

      assert_raise Ecto.NoResultsError, fn ->
        Tracker.get_training_session!(training_session.id)
      end
    end

    test "change_training_session/1 returns a training_session changeset" do
      training_session = training_session_fixture()
      assert %Ecto.Changeset{} = Tracker.change_training_session(training_session)
    end
  end

  describe "check_ins" do
    alias AttendanceTracker.Tracker.CheckIn

    import AttendanceTracker.TrackerFixtures

    @invalid_attrs %{}

    test "list_check_ins/0 returns all check_ins" do
      check_in = check_in_fixture()
      assert Tracker.list_check_ins() == [check_in]
    end

    test "get_check_in!/1 returns the check_in with given id" do
      check_in = check_in_fixture()
      assert Tracker.get_check_in!(check_in.id) == check_in
    end

    test "check_in/2 checks a participant into a session" do
      participant = participant_fixture()
      session = training_session_fixture()

      assert {:ok, %CheckIn{} = check_in} = Tracker.check_in(participant, session)
      assert check_in.participant_id == participant.id
      assert check_in.training_session_id == session.id
    end

    test "check_in/2 is idempotent per participant and session" do
      participant = participant_fixture()
      session = training_session_fixture()

      assert {:ok, %CheckIn{}} = Tracker.check_in(participant, session)
      assert {:error, :already_checked_in} = Tracker.check_in(participant, session)
      assert Tracker.check_in_count(session) == 1
    end

    test "check_in/2 broadcasts to session subscribers" do
      participant = participant_fixture()
      session = training_session_fixture()
      Tracker.subscribe(session)

      assert {:ok, check_in} = Tracker.check_in(participant, session)
      assert_received {:checked_in, ^check_in}
    end

    test "check_out/2 removes a check-in and broadcasts to subscribers" do
      participant = participant_fixture()
      session = training_session_fixture()
      Tracker.subscribe(session)

      assert {:ok, check_in} = Tracker.check_in(participant, session)
      assert_received {:checked_in, ^check_in}
      assert Tracker.check_in_count(session) == 1

      assert {:ok, check_in} = Tracker.check_out(participant, session)
      assert_received {:checked_out, ^check_in}
      assert Tracker.check_in_count(session) == 0
    end

    test "check_out/2 returns an error when not checked in" do
      participant = participant_fixture()
      session = training_session_fixture()

      assert {:error, :not_checked_in} = Tracker.check_out(participant, session)
    end

    test "check_in/2 writes an audit log" do
      participant = participant_fixture(%{name: "Audit Person"})
      session = training_session_fixture()

      assert {:ok, _} = Tracker.check_in(participant, session)

      assert [%{action: "check_in", participant_name: "Audit Person", training_session_id: id}] =
               AttendanceTracker.Logs.list_audit_logs()

      assert id == session.id
    end

    test "check_out/2 writes an audit log" do
      participant = participant_fixture(%{name: "Audit Person"})
      session = training_session_fixture()

      assert {:ok, _} = Tracker.check_in(participant, session)
      assert {:ok, _} = Tracker.check_out(participant, session)

      assert [%{action: "check_out"}, %{action: "check_in"}] =
               AttendanceTracker.Logs.list_audit_logs()
    end

    test "todays_session/0 returns today's session, creating it once" do
      session = Tracker.todays_session()
      assert session.date == Tracker.local_today()
      assert session.training_id == nil
      assert Tracker.todays_session().id == session.id
    end

    test "create_check_in/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Tracker.create_check_in(@invalid_attrs)
    end

    test "delete_check_in/1 deletes the check_in" do
      check_in = check_in_fixture()
      assert {:ok, %CheckIn{}} = Tracker.delete_check_in(check_in)
      assert_raise Ecto.NoResultsError, fn -> Tracker.get_check_in!(check_in.id) end
    end

    test "change_check_in/1 returns a check_in changeset" do
      check_in = check_in_fixture()
      assert %Ecto.Changeset{} = Tracker.change_check_in(check_in)
    end
  end

  describe "admin pin" do
    test "admin_pin/0 defaults to 1234" do
      assert Tracker.admin_pin() == "1234"
    end

    test "admin_pin_valid?/1 checks the PIN" do
      assert Tracker.admin_pin_valid?("1234")
      refute Tracker.admin_pin_valid?("0000")
      refute Tracker.admin_pin_valid?(nil)
    end

    test "update_admin_pin/1 persists a new PIN" do
      assert {:ok, _setting} = Tracker.update_admin_pin("9876")

      assert Tracker.admin_pin() == "9876"
      assert Tracker.admin_pin_valid?("9876")
      refute Tracker.admin_pin_valid?("1234")
    end

    test "change_admin_pin/1 accepts a valid PIN with matching confirmation" do
      changeset = Tracker.change_admin_pin(%{new_pin: "9876", new_pin_confirmation: "9876"})
      assert changeset.valid?
    end

    test "change_admin_pin/1 validates the format" do
      for invalid <- ["", "12", "1234567890123", "12ab"] do
        changeset =
          Tracker.change_admin_pin(%{new_pin: invalid, new_pin_confirmation: invalid})

        refute changeset.valid?, "expected #{inspect(invalid)} to be invalid"
      end
    end

    test "change_admin_pin/1 validates the confirmation" do
      changeset =
        Tracker.change_admin_pin(%{new_pin: "9876", new_pin_confirmation: "1111"})

      refute changeset.valid?
      assert "does not match" in errors_on(changeset).new_pin_confirmation
    end
  end

  describe "session pin" do
    test "session_pin/0 is nil and the kiosk is open until configured" do
      assert Tracker.session_pin() == nil
      refute Tracker.session_pin_configured?()
      refute Tracker.session_pin_valid?("1234")
      assert Tracker.session_pin_fingerprint() == nil
    end

    test "update_session_pin/1 persists and validates the PIN" do
      assert {:ok, _setting} = Tracker.update_session_pin("2468")

      assert Tracker.session_pin() == "2468"
      assert Tracker.session_pin_configured?()
      assert Tracker.session_pin_valid?("2468")
      refute Tracker.session_pin_valid?("0000")
      refute Tracker.session_pin_valid?(nil)
    end

    test "session_pin_fingerprint/0 changes with the PIN" do
      assert {:ok, _} = Tracker.update_session_pin("2468")
      first = Tracker.session_pin_fingerprint()

      assert is_binary(first)

      assert {:ok, _} = Tracker.update_session_pin("1357")
      refute Tracker.session_pin_fingerprint() == first
    end

    test "change_session_pin/1 validates the format and confirmation" do
      assert Tracker.change_session_pin(%{new_pin: "2468", new_pin_confirmation: "2468"}).valid?

      refute Tracker.change_session_pin(%{new_pin: "12", new_pin_confirmation: "12"}).valid?

      refute Tracker.change_session_pin(%{
               new_pin: "2468",
               new_pin_confirmation: "1357"
             }).valid?
    end
  end

  describe "session expiry" do
    test "session_expiry_days/0 defaults to 30" do
      assert Tracker.session_expiry_days() == 30
      assert Tracker.session_expiry_seconds() == 30 * 86_400
    end

    test "update_session_expiry_days/1 persists the value" do
      assert {:ok, _setting} = Tracker.update_session_expiry_days(7)

      assert Tracker.session_expiry_days() == 7
      assert Tracker.session_expiry_seconds() == 7 * 86_400
    end

    test "change_session_expiry_days/1 requires a positive number of days" do
      assert Tracker.change_session_expiry_days(%{days: 30}).valid?

      for invalid <- [0, -1, 3651] do
        refute Tracker.change_session_expiry_days(%{days: invalid}).valid?,
               "expected #{invalid} to be invalid"
      end
    end
  end

  describe "report" do
    import AttendanceTracker.TrackerFixtures

    test "list_sessions_for_report/1 returns the year's sessions with check-ins" do
      in_year = training_session_fixture(%{date: ~D[2026-01-05]})
      _other_year = training_session_fixture(%{date: ~D[2025-01-06]})
      check_in = check_in_fixture(%{training_session: in_year})

      assert [%{date: ~D[2026-01-05], check_ins: [loaded]}] =
               Tracker.list_sessions_for_report(2026)

      assert loaded.id == check_in.id
      assert loaded.participant.name == "some name"
    end

    test "list_session_years/0 falls back to the current year without sessions" do
      assert Tracker.list_session_years() == [Tracker.local_today().year]
    end

    test "list_session_years/0 lists session years up to the current year" do
      training_session_fixture(%{date: ~D[2024-05-06]})
      training_session_fixture(%{date: ~D[2026-01-05]})

      assert Tracker.list_session_years() ==
               Enum.to_list(Tracker.local_today().year..2024//-1)
    end
  end
end
