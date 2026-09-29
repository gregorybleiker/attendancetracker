defmodule AttendanceTracker.Tracker do
  @moduledoc """
  The Tracker context.
  """

  import Ecto.Query, warn: false
  alias AttendanceTracker.Repo

  alias AttendanceTracker.Tracker.Participant

  @doc """
  Returns the list of participants.

  ## Examples

      iex> list_participants()
      [%Participant{}, ...]

  """
  def list_participants do
    Repo.all(Participant)
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
  def get_participant!(id), do: Repo.get!(Participant, id)

  @doc """
  Creates a participant.

  ## Examples

      iex> create_participant(%{field: value})
      {:ok, %Participant{}}

      iex> create_participant(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_participant(attrs) do
    %Participant{}
    |> Participant.changeset(attrs)
    |> Repo.insert()
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

  alias AttendanceTracker.Tracker.TrainingDay

  @doc """
  Returns the list of training days, ordered by weekday and start time.

  ## Examples

      iex> list_training_days()
      [%TrainingDay{}, ...]

  """
  def list_training_days do
    Repo.all(from t in TrainingDay, order_by: [asc: t.weekday, asc: t.starts_at])
  end

  @doc """
  Gets a single training day.

  Raises `Ecto.NoResultsError` if the Training day does not exist.

  ## Examples

      iex> get_training_day!(123)
      %TrainingDay{}

      iex> get_training_day!(456)
      ** (Ecto.NoResultsError)

  """
  def get_training_day!(id), do: Repo.get!(TrainingDay, id)

  @doc """
  Creates a training day.

  ## Examples

      iex> create_training_day(%{field: value})
      {:ok, %TrainingDay{}}

      iex> create_training_day(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_training_day(attrs) do
    %TrainingDay{}
    |> TrainingDay.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a training day.

  ## Examples

      iex> update_training_day(training_day, %{field: new_value})
      {:ok, %TrainingDay{}}

      iex> update_training_day(training_day, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_training_day(%TrainingDay{} = training_day, attrs) do
    training_day
    |> TrainingDay.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a training day.

  ## Examples

      iex> delete_training_day(training_day)
      {:ok, %TrainingDay{}}

      iex> delete_training_day(training_day)
      {:error, %Ecto.Changeset{}}

  """
  def delete_training_day(%TrainingDay{} = training_day) do
    Repo.delete(training_day)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking training day changes.

  ## Examples

      iex> change_training_day(training_day)
      %Ecto.Changeset{data: %TrainingDay{}}

  """
  def change_training_day(%TrainingDay{} = training_day, attrs \\ %{}) do
    TrainingDay.changeset(training_day, attrs)
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
  Returns the ad-hoc training session for today (not tied to a training
  day), creating it if needed.
  """
  def todays_session do
    today = local_today()

    %TrainingSession{}
    |> TrainingSession.changeset(%{date: today})
    |> Repo.insert(on_conflict: :nothing)

    Repo.one!(
      from s in TrainingSession,
        where: s.date == ^today and is_nil(s.training_day_id)
    )
  end

  @doc """
  Returns the training session for the given training day on the given
  date, creating it if needed.
  """
  def session_for_training_day(%TrainingDay{} = training_day, %Date{} = date) do
    %TrainingSession{}
    |> TrainingSession.changeset(%{date: date, training_day_id: training_day.id})
    |> Repo.insert(on_conflict: :nothing)

    Repo.get_by!(TrainingSession, date: date, training_day_id: training_day.id)
  end

  @doc """
  Returns the "current" training day for the given local date and time:

    * the training day in progress right now, if any
    * otherwise the next training day starting later today, if any
    * otherwise the most recently started training day

  Returns `nil` when the list is empty.
  """
  def current_training_day(training_days, date, time)

  def current_training_day([], _date, _time), do: nil

  def current_training_day(training_days, %Date{} = date, %Time{} = time) do
    in_progress =
      training_days
      |> Enum.filter(&TrainingDay.in_progress?(&1, date, time))
      |> Enum.max_by(& &1.starts_at, Time, fn -> nil end)

    upcoming_today =
      training_days
      |> Enum.filter(
        &(&1.weekday == Date.day_of_week(date) and Time.compare(&1.starts_at, time) == :gt)
      )
      |> Enum.min_by(& &1.starts_at, Time, fn -> nil end)

    in_progress ||
      upcoming_today ||
      Enum.max_by(training_days, &TrainingDay.most_recent_start(&1, date, time), NaiveDateTime)
  end

  @doc """
  Lists active participants (alphabetical) with their check-in for the
  given session preloaded (`participant.check_ins` is `[]` or has one entry).
  """
  def list_participants_with_check_ins(%TrainingSession{} = session) do
    check_in_query = from c in CheckIn, where: c.training_session_id == ^session.id

    Repo.all(
      from p in Participant,
        where: p.active,
        order_by: p.name,
        preload: [check_ins: ^check_in_query]
    )
  end

  @doc """
  Same as `list_participants_with_check_ins/1`, but for a single participant.
  """
  def get_participant_with_check_ins(%TrainingSession{} = session, participant_id) do
    check_in_query = from c in CheckIn, where: c.training_session_id == ^session.id

    Repo.one!(
      from p in Participant,
        where: p.id == ^participant_id,
        preload: [check_ins: ^check_in_query]
    )
  end

  @doc """
  Checks a participant into a training session. Idempotent: if the
  participant is already checked in, `{:error, :already_checked_in}`
  is returned. Broadcasts `{:checked_in, check_in}` to subscribers.
  """
  def check_in(%Participant{} = participant, %TrainingSession{} = session) do
    %CheckIn{}
    |> CheckIn.changeset(%{participant_id: participant.id, training_session_id: session.id})
    |> Repo.insert()
    |> case do
      {:ok, check_in} ->
        Phoenix.PubSub.broadcast(@pubsub, topic(session.id), {:checked_in, check_in})
        {:ok, check_in}

      {:error, %Ecto.Changeset{} = changeset} ->
        if unique_violation?(changeset),
          do: {:error, :already_checked_in},
          else: {:error, changeset}
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
  with their training day and check-ins (participants, in check-in order)
  preloaded. Used for the CSV report.
  """
  def list_sessions_for_report(year) when is_integer(year) do
    first = Date.new!(year, 1, 1)
    last = Date.new!(year + 1, 1, 1)

    check_in_query = from c in CheckIn, order_by: c.inserted_at, preload: :participant

    Repo.all(
      from s in TrainingSession,
        left_join: td in assoc(s, :training_day),
        where: s.date >= ^first and s.date < ^last,
        order_by: [asc: s.date, asc: td.starts_at],
        preload: [:training_day, check_ins: ^check_in_query]
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
