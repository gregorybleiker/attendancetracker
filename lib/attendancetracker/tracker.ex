defmodule AttendanceTracker.Tracker do
  @moduledoc """
  The Tracker context.
  """

  import Ecto.Query, warn: false
  alias AttendanceTracker.Repo
  alias AttendanceTracker.Logs

  alias AttendanceTracker.Tracker.Participant
  alias AttendanceTracker.Tracker.ParticipantPhoto

  @doc """
  Returns the list of participants.

  ## Examples

      iex> list_participants()
      [%Participant{}, ...]

  """
  def list_participants do
    Participant
    |> order_by([p], asc: p.first_name, asc: p.last_name)
    |> with_photo()
    |> Repo.all()
  end

  @doc """
  Like `list_participants/0`, but with each participant's
  `attended_trainings` populated (the distinct trainings they have ever
  attended).
  """
  def list_participants_with_trainings do
    list_participants()
    |> with_attended_trainings()
  end

  @doc """
  Gets a single participant.

  Raises `Ecto.NoResultsError` if the Participant does not exist.

  ## Examples

      iex> get_participant!(123)
      %Participant{}

      iex> get_participant!(456)
      ** (Ecto.NoResultsError)

  """
  def get_participant!(id), do: Repo.get!(with_photo(Participant), id)

  @doc """
  Gets a single participant with their `attended_trainings` populated.

  Raises `Ecto.NoResultsError` if the Participant does not exist.
  """
  def get_participant_with_trainings!(id) do
    [participant] = with_attended_trainings([get_participant!(id)])
    participant
  end

  @doc """
  Creates a participant.

  ## Examples

      iex> create_participant(%{field: value})
      {:ok, %Participant{}}

      iex> create_participant(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_participant(attrs) do
    create_participant(attrs, "local")
  end

  @participant_sources ~w(local webling)

  @doc """
  Creates a participant with an explicit source (`"local"` or `"webling"`).

  The source is set programmatically (it is not castable from user input).
  """
  def create_participant(attrs, source) when source in @participant_sources do
    %Participant{}
    |> Participant.changeset(attrs)
    |> Ecto.Changeset.put_change(:source, source)
    |> Repo.insert()
  end

  @doc """
  Sets a participant's source, e.g. flagging a manually created participant as
  also existing in Webling.
  """
  def set_participant_source(%Participant{} = participant, source)
      when source in @participant_sources do
    participant
    |> Ecto.Changeset.change(source: source)
    |> Repo.update()
  end

  @doc """
  Updates a participant.

  ## Examples

      iex> update_participant(participant, %{field: new_value})
      {:ok, %Participant{}}

      iex> update_participant(participant, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_participant(%Participant{} = participant, attrs) do
    participant
    |> Participant.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a participant.

  ## Examples

      iex> delete_participant(participant)
      {:ok, %Participant{}}

      iex> delete_participant(participant)
      {:error, %Ecto.Changeset{}}

  """
  def delete_participant(%Participant{} = participant) do
    Repo.delete(participant)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking participant changes.

  ## Examples

      iex> change_participant(participant)
      %Ecto.Changeset{data: %Participant{}}

  """
  def change_participant(%Participant{} = participant, attrs \\ %{}) do
    Participant.changeset(participant, attrs)
  end

  @doc """
  Stores (or replaces) a participant's photo from raw bytes.

  ## Examples

      iex> put_participant_photo(participant, <<255, 216, ...>>, "image/jpeg")
      {:ok, %ParticipantPhoto{}}

  """
  def put_participant_photo(%Participant{} = participant, data, content_type)
      when is_binary(data) and is_binary(content_type) do
    %ParticipantPhoto{participant_id: participant.id}
    |> ParticipantPhoto.changeset(%{data: data, content_type: content_type})
    |> Repo.insert(
      on_conflict: {:replace, [:data, :content_type, :updated_at]},
      conflict_target: :participant_id
    )
  end

  @doc """
  Fetches a participant's photo, or `nil` when they have none.
  """
  def get_participant_photo(participant_id) do
    Repo.get_by(ParticipantPhoto, participant_id: participant_id)
  end

  # Adds the lightweight `has_photo`/`photo_updated_at` fields to a
  # participant query without ever loading the photo bytes.
  defp with_photo(query) do
    from p in query,
      left_join: photo in assoc(p, :photo),
      select_merge: %{
        has_photo: not is_nil(photo.id),
        photo_updated_at: photo.updated_at
      }
  end

  alias AttendanceTracker.Tracker.Training
  alias AttendanceTracker.Tracker.TrainingMember

  @doc """
  Returns the list of trainings, ordered by weekday and start time.

  ## Examples

      iex> list_trainings()
      [%Training{}, ...]

  """
  def list_trainings do
    Repo.all(from t in Training, order_by: [asc: t.weekday, asc: t.starts_at])
  end

  @doc """
  Gets a single training.

  Raises `Ecto.NoResultsError` if the Training does not exist.

  ## Examples

      iex> get_training!(123)
      %Training{}

      iex> get_training!(456)
      ** (Ecto.NoResultsError)

  """
  def get_training!(id), do: Repo.get!(Training, id)

  @doc """
  Creates a training.

  ## Examples

      iex> create_training(%{field: value})
      {:ok, %Training{}}

      iex> create_training(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_training(attrs) do
    %Training{}
    |> Training.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a training.

  ## Examples

      iex> update_training(training, %{field: new_value})
      {:ok, %Training{}}

      iex> update_training(training, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_training(%Training{} = training, attrs) do
    training
    |> Training.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a training.

  ## Examples

      iex> delete_training(training)
      {:ok, %Training{}}

      iex> delete_training(training)
      {:error, %Ecto.Changeset{}}

  """
  def delete_training(%Training{} = training) do
    Repo.delete(training)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking training changes.

  ## Examples

      iex> change_training(training)
      %Ecto.Changeset{data: %Training{}}

  """
  def change_training(%Training{} = training, attrs \\ %{}) do
    Training.changeset(training, attrs)
  end

  @doc """
  Returns the participants who are members of a training, ordered by first then
  last name (with their photo preloaded).
  """
  def list_training_members(%Training{} = training) do
    from(p in Participant,
      join: tm in assoc(p, :training_members),
      where: tm.training_id == ^training.id,
      order_by: [asc: p.first_name, asc: p.last_name]
    )
    |> with_photo()
    |> Repo.all()
  end

  @doc """
  Adds a participant to a training's member list. Idempotent: returns
  `{:ok, :exists}` when the participant is already a member.
  """
  def add_training_member(%Training{} = training, %Participant{} = participant) do
    if Repo.get_by(TrainingMember, training_id: training.id, participant_id: participant.id) do
      {:ok, :exists}
    else
      %TrainingMember{}
      |> TrainingMember.changeset(%{training_id: training.id, participant_id: participant.id})
      |> Repo.insert()
      |> case do
        {:ok, _training_member} -> {:ok, :created}
        {:error, changeset} -> {:error, changeset}
      end
    end
  end

  alias AttendanceTracker.Tracker.Event
  alias AttendanceTracker.Tracker.EventParticipant

  @doc """
  Returns the list of events, chronologically by date then start time.
  """
  def list_events do
    Repo.all(from e in Event, order_by: [asc: e.date, asc: e.starts_at])
  end

  @doc """
  Gets a single event.

  Raises `Ecto.NoResultsError` if the Event does not exist.
  """
  def get_event!(id), do: Repo.get!(Event, id)

  @doc """
  Creates an event.
  """
  def create_event(attrs) do
    %Event{}
    |> Event.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an event.
  """
  def update_event(%Event{} = event, attrs) do
    event
    |> Event.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an event.
  """
  def delete_event(%Event{} = event), do: Repo.delete(event)

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking event changes.
  """
  def change_event(%Event{} = event, attrs \\ %{}) do
    Event.changeset(event, attrs)
  end

  @doc """
  Returns the participants selected for an event, ordered by first then last
  name (with their photo preloaded).
  """
  def list_event_participants(%Event{} = event) do
    from(p in Participant,
      join: ep in assoc(p, :event_participants),
      where: ep.event_id == ^event.id,
      order_by: [asc: p.first_name, asc: p.last_name]
    )
    |> with_photo()
    |> Repo.all()
  end

  @doc """
  Returns the ids of the participants selected for an event.
  """
  def list_event_participant_ids(%Event{} = event) do
    from(ep in EventParticipant, where: ep.event_id == ^event.id, select: ep.participant_id)
    |> Repo.all()
  end

  @doc """
  Selects a participant for an event. Idempotent: returns `{:ok, :exists}`
  when the participant is already selected.
  """
  def add_event_participant(%Event{} = event, %Participant{} = participant) do
    if Repo.get_by(EventParticipant, event_id: event.id, participant_id: participant.id) do
      {:ok, :exists}
    else
      %EventParticipant{}
      |> EventParticipant.changeset(%{event_id: event.id, participant_id: participant.id})
      |> Repo.insert()
      |> case do
        {:ok, _event_participant} -> {:ok, :created}
        {:error, changeset} -> {:error, changeset}
      end
    end
  end

  @doc """
  Removes a participant from an event. Idempotent: returns `{:ok, :not_selected}`
  when the participant is not selected.
  """
  def remove_event_participant(%Event{} = event, %Participant{} = participant) do
    case Repo.get_by(EventParticipant, event_id: event.id, participant_id: participant.id) do
      %EventParticipant{} = event_participant -> Repo.delete(event_participant)
      nil -> {:ok, :not_selected}
    end
  end

  @doc """
  True when the participant is selected for the event.
  """
  def event_participant?(%Event{} = event, %Participant{} = participant) do
    Repo.exists?(
      from ep in EventParticipant,
        where: ep.event_id == ^event.id and ep.participant_id == ^participant.id
    )
  end

  @doc """
  Lists the active participants with their selection for the event preloaded
  (`participant.event_participants` is `[]` or has one entry), ordered by first
  name. Used by the event participant picker.

  Pass `only_selected: true` to list just the participants selected for the
  event.
  """
  def list_participants_for_event(%Event{} = event, opts \\ []) do
    from(p in Participant, where: p.active)
    |> only_selected_for_event(event, opts)
    |> event_selection(event)
    |> order_by([p], asc: p.first_name, asc: p.last_name)
    |> with_photo()
    |> Repo.all()
  end

  defp only_selected_for_event(query, %Event{} = event, opts) do
    if Keyword.get(opts, :only_selected, false) do
      from p in query,
        join: ep in assoc(p, :event_participants),
        where: ep.event_id == ^event.id
    else
      query
    end
  end

  @doc """
  Same as `list_participants_for_event/2`, but for a single participant.
  """
  def get_participant_for_event(%Event{} = event, participant_id) do
    from(p in Participant, where: p.id == ^participant_id)
    |> event_selection(event)
    |> with_photo()
    |> Repo.one!()
  end

  defp event_selection(query, %Event{} = event) do
    selection = from ep in EventParticipant, where: ep.event_id == ^event.id

    from(p in query, preload: [event_participants: ^selection])
  end

  alias AttendanceTracker.Tracker.TrainingSession

  @doc """
  Returns the list of training_sessions.

  ## Examples

      iex> list_training_sessions()
      [%TrainingSession{}, ...]

  """
  def list_training_sessions do
    Repo.all(TrainingSession)
  end

  @doc """
  Gets a single training_session.

  Raises `Ecto.NoResultsError` if the Training session does not exist.

  ## Examples

      iex> get_training_session!(123)
      %TrainingSession{}

      iex> get_training_session!(456)
      ** (Ecto.NoResultsError)

  """
  def get_training_session!(id), do: Repo.get!(TrainingSession, id)

  @doc """
  Creates a training_session.

  ## Examples

      iex> create_training_session(%{field: value})
      {:ok, %TrainingSession{}}

      iex> create_training_session(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_training_session(attrs) do
    %TrainingSession{}
    |> TrainingSession.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a training_session.

  ## Examples

      iex> update_training_session(training_session, %{field: new_value})
      {:ok, %TrainingSession{}}

      iex> update_training_session(training_session, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_training_session(%TrainingSession{} = training_session, attrs) do
    training_session
    |> TrainingSession.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a training_session.

  ## Examples

      iex> delete_training_session(training_session)
      {:ok, %TrainingSession{}}

      iex> delete_training_session(training_session)
      {:error, %Ecto.Changeset{}}

  """
  def delete_training_session(%TrainingSession{} = training_session) do
    Repo.delete(training_session)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking training_session changes.

  ## Examples

      iex> change_training_session(training_session)
      %Ecto.Changeset{data: %TrainingSession{}}

  """
  def change_training_session(%TrainingSession{} = training_session, attrs \\ %{}) do
    TrainingSession.changeset(training_session, attrs)
  end

  alias AttendanceTracker.Tracker.CheckIn

  @doc """
  Returns the list of check_ins.

  ## Examples

      iex> list_check_ins()
      [%CheckIn{}, ...]

  """
  def list_check_ins do
    Repo.all(CheckIn)
  end

  @doc """
  Gets a single check_in.

  Raises `Ecto.NoResultsError` if the Check in does not exist.

  ## Examples

      iex> get_check_in!(123)
      %CheckIn{}

      iex> get_check_in!(456)
      ** (Ecto.NoResultsError)

  """
  def get_check_in!(id), do: Repo.get!(CheckIn, id)

  @doc """
  Creates a check_in.

  ## Examples

      iex> create_check_in(%{field: value})
      {:ok, %CheckIn{}}

      iex> create_check_in(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_check_in(attrs) do
    %CheckIn{}
    |> CheckIn.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a check_in.

  ## Examples

      iex> update_check_in(check_in, %{field: new_value})
      {:ok, %CheckIn{}}

      iex> update_check_in(check_in, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_check_in(%CheckIn{} = check_in, attrs) do
    check_in
    |> CheckIn.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a check_in.

  ## Examples

      iex> delete_check_in(check_in)
      {:ok, %CheckIn{}}

      iex> delete_check_in(check_in)
      {:error, %Ecto.Changeset{}}

  """
  def delete_check_in(%CheckIn{} = check_in) do
    Repo.delete(check_in)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking check_in changes.

  ## Examples

      iex> change_check_in(check_in)
      %Ecto.Changeset{data: %CheckIn{}}

  """
  def change_check_in(%CheckIn{} = check_in, attrs \\ %{}) do
    CheckIn.changeset(check_in, attrs)
  end

  ## Settings

  alias AttendanceTracker.Tracker.Setting

  @admin_pin_key "admin_pin"
  @default_admin_pin "1234"

  @doc """
  Returns the admin PIN. Defaults to `"1234"` until changed.
  """
  def admin_pin do
    case Repo.get_by(Setting, key: @admin_pin_key) do
      nil -> @default_admin_pin
      %Setting{value: value} -> value
    end
  end

  @doc """
  Returns true if the given PIN matches the admin PIN.
  """
  def admin_pin_valid?(pin) when is_binary(pin), do: pin == admin_pin()
  def admin_pin_valid?(_pin), do: false

  @doc """
  Returns a changeset for validating an admin PIN change
  (new PIN plus confirmation).
  """
  def change_admin_pin(params \\ %{}) do
    types = %{new_pin: :string, new_pin_confirmation: :string}

    {%{}, types}
    |> Ecto.Changeset.cast(params, [:new_pin, :new_pin_confirmation])
    |> Ecto.Changeset.validate_required([:new_pin])
    |> Ecto.Changeset.validate_format(:new_pin, ~r/^\d{4,12}$/, message: "must be 4 to 12 digits")
    |> Ecto.Changeset.validate_confirmation(:new_pin, message: "does not match")
  end

  @doc """
  Persists a new admin PIN.
  """
  def update_admin_pin(new_pin) when is_binary(new_pin) do
    setting = Repo.get_by(Setting, key: @admin_pin_key) || %Setting{key: @admin_pin_key}

    setting
    |> Setting.changeset(%{value: new_pin})
    |> Repo.insert_or_update()
  end

  @session_pin_key "session_pin"
  @session_expiry_days_key "session_expiry_days"
  @default_session_expiry_days 30

  @doc """
  Returns the kiosk session PIN, or `nil` when no session PIN has been
  configured yet.
  """
  def session_pin do
    case Repo.get_by(Setting, key: @session_pin_key) do
      nil -> nil
      %Setting{value: value} -> value
    end
  end

  @doc """
  Returns true when a kiosk session PIN has been configured. Until then the
  kiosk stays open.
  """
  def session_pin_configured?, do: session_pin() != nil

  @doc """
  Returns true if the given PIN matches the configured session PIN. Always
  returns false when no session PIN is configured.
  """
  def session_pin_valid?(pin) when is_binary(pin) do
    case session_pin() do
      nil -> false
      configured -> Plug.Crypto.secure_compare(pin, configured)
    end
  end

  def session_pin_valid?(_pin), do: false

  @doc """
  Returns a fingerprint of the current session PIN, used to invalidate
  existing kiosk session cookies when the PIN changes.
  """
  def session_pin_fingerprint do
    case session_pin() do
      nil -> nil
      pin -> :crypto.hash(:sha256, pin) |> Base.encode16(case: :lower)
    end
  end

  @doc """
  Returns a changeset for validating a session PIN change
  (new PIN plus confirmation).
  """
  def change_session_pin(params \\ %{}) do
    types = %{new_pin: :string, new_pin_confirmation: :string}

    {%{}, types}
    |> Ecto.Changeset.cast(params, [:new_pin, :new_pin_confirmation])
    |> Ecto.Changeset.validate_required([:new_pin])
    |> Ecto.Changeset.validate_format(:new_pin, ~r/^\d{4,12}$/, message: "must be 4 to 12 digits")
    |> Ecto.Changeset.validate_confirmation(:new_pin, message: "does not match")
  end

  @doc """
  Persists a new kiosk session PIN.
  """
  def update_session_pin(new_pin) when is_binary(new_pin) do
    setting = Repo.get_by(Setting, key: @session_pin_key) || %Setting{key: @session_pin_key}

    setting
    |> Setting.changeset(%{value: new_pin})
    |> Repo.insert_or_update()
  end

  @doc """
  Returns how many days a started kiosk session stays valid. Defaults to
  `#{@default_session_expiry_days}`.
  """
  def session_expiry_days do
    case Repo.get_by(Setting, key: @session_expiry_days_key) do
      %Setting{value: value} ->
        case Integer.parse(value) do
          {days, ""} when days > 0 -> days
          _ -> @default_session_expiry_days
        end

      nil ->
        @default_session_expiry_days
    end
  end

  @doc """
  Returns the kiosk session expiry in seconds.
  """
  def session_expiry_seconds, do: session_expiry_days() * 86_400

  @doc """
  Returns a changeset for validating a session expiry (in days) change.
  """
  def change_session_expiry_days(params \\ %{}) do
    types = %{days: :integer}

    {%{}, types}
    |> Ecto.Changeset.cast(params, [:days])
    |> Ecto.Changeset.validate_required([:days])
    |> Ecto.Changeset.validate_number(:days,
      greater_than: 0,
      less_than_or_equal_to: 3650,
      message: "must be between 1 and 3650 days"
    )
  end

  @doc """
  Persists the kiosk session expiry in days.
  """
  def update_session_expiry_days(days) when is_integer(days) and days > 0 do
    setting =
      Repo.get_by(Setting, key: @session_expiry_days_key) ||
        %Setting{key: @session_expiry_days_key}

    setting
    |> Setting.changeset(%{value: Integer.to_string(days)})
    |> Repo.insert_or_update()
  end

  ## Kiosk / attendance tracking

  alias AttendanceTracker.Tracker.TrainingSession

  @pubsub AttendanceTracker.PubSub

  defp topic(session_id), do: "training_session:#{session_id}"

  @doc """
  Subscribes the caller to check-in updates for a training session.
  """
  def subscribe(%TrainingSession{} = session) do
    Phoenix.PubSub.subscribe(@pubsub, topic(session.id))
  end

  @doc """
  Unsubscribes the caller from check-in updates for a training session.
  """
  def unsubscribe(%TrainingSession{} = session) do
    Phoenix.PubSub.unsubscribe(@pubsub, topic(session.id))
  end

  @doc """
  Returns the current local date (based on the system timezone).
  """
  def local_today do
    {date, _time} = :calendar.local_time()
    Date.from_erl!(date)
  end

  @doc """
  Returns the current local time (based on the system timezone).
  """
  def local_time_now do
    {_date, {hour, minute, second}} = :calendar.local_time()
    Time.new!(hour, minute, second)
  end

  @doc """
  Returns the ad-hoc training session for today (not tied to a training),
  creating it if needed.
  """
  def todays_session do
    today = local_today()

    %TrainingSession{}
    |> TrainingSession.changeset(%{date: today})
    |> Repo.insert(on_conflict: :nothing)

    Repo.one!(
      from s in TrainingSession,
        where: s.date == ^today and is_nil(s.training_id)
    )
  end

  @doc """
  Returns the training session for the given training on the given
  date, creating it if needed.
  """
  def session_for_training(%Training{} = training, %Date{} = date) do
    %TrainingSession{}
    |> TrainingSession.changeset(%{date: date, training_id: training.id})
    |> Repo.insert(on_conflict: :nothing)

    Repo.get_by!(TrainingSession, date: date, training_id: training.id)
  end

  @doc """
  Returns the "current" training for the given local date and time:

    * the training in progress right now, if any
    * otherwise the next training starting later today, if any
    * otherwise the most recently started training

  Returns `nil` when the list is empty.
  """
  def current_training(trainings, date, time)

  def current_training([], _date, _time), do: nil

  def current_training(trainings, %Date{} = date, %Time{} = time) do
    in_progress =
      trainings
      |> Enum.filter(&Training.in_progress?(&1, date, time))
      |> Enum.max_by(& &1.starts_at, Time, fn -> nil end)

    upcoming_today =
      trainings
      |> Enum.filter(
        &(&1.weekday == Date.day_of_week(date) and Time.compare(&1.starts_at, time) == :gt)
      )
      |> Enum.min_by(& &1.starts_at, Time, fn -> nil end)

    in_progress ||
      upcoming_today ||
      Enum.max_by(trainings, &Training.most_recent_start(&1, date, time), NaiveDateTime)
  end

  @doc """
  Lists active participants (alphabetical) with their check-in for the
  given session preloaded (`participant.check_ins` is `[]` or has one entry).

  By default, when the session belongs to a training, only participants who
  are members of that training are returned. Pass `show_all: true` to list
  every active participant regardless of the training.
  """
  def list_participants_with_check_ins(%TrainingSession{} = session, opts \\ []) do
    check_in_query = from c in CheckIn, where: c.training_session_id == ^session.id

    from(p in Participant, as: :participant)
    |> where([p], p.active)
    |> filter_training_members(session, opts)
    |> order_by([p], asc: p.first_name, asc: p.last_name)
    |> preload([p], check_ins: ^check_in_query)
    |> with_photo()
    |> Repo.all()
  end

  @doc """
  Same as `list_participants_with_check_ins/2`, but for a single participant.
  """
  def get_participant_with_check_ins(%TrainingSession{} = session, participant_id) do
    check_in_query = from c in CheckIn, where: c.training_session_id == ^session.id

    from(p in Participant,
      where: p.id == ^participant_id,
      preload: [check_ins: ^check_in_query]
    )
    |> with_photo()
    |> Repo.one!()
  end

  # When the session belongs to a training and `show_all` is not set, keep
  # only participants who are members of that training. `show_all: true`
  # bypasses the filter and lists every active participant.
  defp filter_training_members(query, %TrainingSession{training_id: nil}, _opts), do: query

  defp filter_training_members(query, %TrainingSession{training_id: training_id}, opts) do
    if Keyword.get(opts, :show_all, false) do
      query
    else
      from p in query,
        where:
          exists(
            from tm in TrainingMember,
              where: tm.participant_id == parent_as(:participant).id,
              where: tm.training_id == ^training_id
          )
    end
  end

  # Adds the `attended_trainings` virtual field to participants using a single
  # grouped query (distinct trainings per participant, ordered like the
  # training list).
  defp with_attended_trainings([]), do: []

  defp with_attended_trainings(participants) when is_list(participants) do
    ids = Enum.map(participants, & &1.id)

    trainings_by_participant =
      from(c in CheckIn,
        join: s in assoc(c, :training_session),
        join: t in assoc(s, :training),
        where: c.participant_id in ^ids,
        distinct: true,
        order_by: [asc: t.weekday, asc: t.starts_at],
        select: {c.participant_id, t}
      )
      |> Repo.all()
      |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))

    Enum.map(participants, fn participant ->
      %{participant | attended_trainings: Map.get(trainings_by_participant, participant.id, [])}
    end)
  end

  @doc """
  Checks a participant into a training session. Idempotent: if the
  participant is already checked in, `{:error, :already_checked_in}`
  is returned. Broadcasts `{:checked_in, check_in}` to subscribers.

  When the session belongs to a training, the participant is also added to
  that training's member list (if not already a member).
  """
  def check_in(%Participant{} = participant, %TrainingSession{} = session) do
    result =
      %CheckIn{}
      |> CheckIn.changeset(%{participant_id: participant.id, training_session_id: session.id})
      |> Repo.insert()
      |> case do
        {:ok, check_in} ->
          _ =
            Logs.audit(%{
              action: "check_in",
              participant_id: participant.id,
              participant_name: Participant.full_name(participant),
              training_session_id: session.id
            })

          Phoenix.PubSub.broadcast(@pubsub, topic(session.id), {:checked_in, check_in})
          {:ok, check_in}

        {:error, %Ecto.Changeset{} = changeset} ->
          if unique_violation?(changeset),
            do: {:error, :already_checked_in},
            else: {:error, changeset}
      end

    ensure_training_membership(participant, session)
    result
  end

  defp ensure_training_membership(%Participant{}, %TrainingSession{training_id: nil}), do: :ok

  defp ensure_training_membership(%Participant{} = participant, %TrainingSession{training_id: id}) do
    case Repo.get(Training, id) do
      %Training{} = training -> add_training_member(training, participant)
      nil -> :ok
    end
  end

  @doc """
  Removes a participant's check-in from a training session. Returns
  `{:error, :not_checked_in}` if there is no check-in. Broadcasts
  `{:checked_out, check_in}` to subscribers.
  """
  def check_out(%Participant{} = participant, %TrainingSession{} = session) do
    query =
      from c in CheckIn,
        where: c.participant_id == ^participant.id and c.training_session_id == ^session.id

    case Repo.one(query) do
      nil ->
        {:error, :not_checked_in}

      check_in ->
        {:ok, check_in} = Repo.delete(check_in)

        _ =
          Logs.audit(%{
            action: "check_out",
            participant_id: participant.id,
            participant_name: Participant.full_name(participant),
            training_session_id: session.id
          })

        Phoenix.PubSub.broadcast(@pubsub, topic(session.id), {:checked_out, check_in})
        {:ok, check_in}
    end
  end

  defp unique_violation?(changeset) do
    Enum.any?(changeset.errors, fn
      {:participant_id, {_msg, opts}} -> opts[:constraint] == :unique
      _ -> false
    end)
  end

  @doc """
  Returns the number of check-ins for a training session.
  """
  def check_in_count(%TrainingSession{} = session) do
    Repo.one(from c in CheckIn, where: c.training_session_id == ^session.id, select: count())
  end

  ## Reporting

  @doc """
  Returns all training sessions in the given calendar year (chronological),
  with their training and check-ins (participants, in check-in order)
  preloaded. Used for the CSV report.
  """
  def list_sessions_for_report(year) when is_integer(year) do
    first = Date.new!(year, 1, 1)
    last = Date.new!(year + 1, 1, 1)

    check_in_query = from c in CheckIn, order_by: c.inserted_at, preload: :participant

    Repo.all(
      from s in TrainingSession,
        left_join: t in assoc(s, :training),
        where: s.date >= ^first and s.date < ^last,
        order_by: [asc: s.date, asc: t.starts_at],
        preload: [:training, check_ins: ^check_in_query]
    )
  end

  @doc """
  Returns the years that have training sessions, most recent first.
  Falls back to the current year when there are no sessions yet.
  """
  def list_session_years do
    case Repo.one(from s in TrainingSession, select: {min(s.date), max(s.date)}) do
      {nil, nil} ->
        [local_today().year]

      {%Date{} = min_date, %Date{} = max_date} ->
        Enum.to_list(max(max_date.year, local_today().year)..min_date.year//-1)
    end
  end
end
