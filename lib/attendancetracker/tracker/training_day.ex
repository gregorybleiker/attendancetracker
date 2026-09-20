defmodule AttendanceTracker.Tracker.TrainingDay do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc """
  A recurring weekly training, e.g. "every Monday from 19:00 to 21:30".

  `weekday` is the ISO 8601 day of week (1 = Monday, 7 = Sunday), matching
  `Date.day_of_week/1`. Times are local times. `name` is an optional alias
  such as "Kids Judo Monday".
  """

  schema "training_days" do
    field :name, :string
    field :weekday, :integer
    field :starts_at, :time
    field :ends_at, :time

    has_many :training_sessions, AttendanceTracker.Tracker.TrainingSession

    timestamps(type: :utc_datetime)
  end

  @weekday_names ~w(Monday Tuesday Wednesday Thursday Friday Saturday Sunday)

  @doc false
  def changeset(training_day, attrs) do
    training_day
    |> cast(attrs, [:name, :weekday, :starts_at, :ends_at])
    |> validate_required([:weekday, :starts_at, :ends_at])
    |> validate_inclusion(:weekday, 1..7)
    |> validate_ends_after_start()
  end

  defp validate_ends_after_start(changeset) do
    starts_at = get_field(changeset, :starts_at)
    ends_at = get_field(changeset, :ends_at)

    if starts_at && ends_at && Time.compare(ends_at, starts_at) != :gt do
      add_error(changeset, :ends_at, "must be after the start time")
    else
      changeset
    end
  end

  @doc """
  Weekday options for selects, e.g. `[{"Monday", 1}, ...]`.
  """
  def weekday_options do
    Enum.with_index(@weekday_names, 1)
    |> Enum.map(fn {name, weekday} -> {name, weekday} end)
  end

  @doc """
  The weekday name of a training day, e.g. `"Monday"`.
  """
  def weekday_name(%__MODULE__{weekday: weekday}) do
    Enum.at(@weekday_names, weekday - 1)
  end

  @doc """
  A human readable label, e.g. `"Kids Judo Monday · 19:00–21:30"` or, without
  an alias, `"Monday · 19:00–21:30"`.
  """
  def label(%__MODULE__{} = training_day) do
    name =
      case training_day.name do
        nil -> weekday_name(training_day)
        "" -> weekday_name(training_day)
        training_alias -> training_alias
      end

    start_time = Calendar.strftime(training_day.starts_at, "%H:%M")
    end_time = Calendar.strftime(training_day.ends_at, "%H:%M")
    "#{name} · #{start_time}–#{end_time}"
  end

  @doc """
  Returns the date of the most recent occurrence of this training day
  on or before `date`.
  """
  def occurrence_on_or_before(%__MODULE__{weekday: weekday}, %Date{} = date) do
    days_back = rem(Date.day_of_week(date) - weekday + 7, 7)
    Date.add(date, -days_back)
  end

  @doc """
  Returns true if the training is in progress at `time` on `date`
  (same weekday and `starts_at <= time <= ends_at`).
  """
  def in_progress?(%__MODULE__{} = training_day, %Date{} = date, %Time{} = time) do
    Date.day_of_week(date) == training_day.weekday &&
      Time.compare(time, training_day.starts_at) != :lt &&
      Time.compare(time, training_day.ends_at) != :gt
  end

  @doc """
  Returns the most recent start of this training day at or before
  `date`/`time`, as a naive datetime. Useful for ordering training days
  by recency.
  """
  def most_recent_start(%__MODULE__{} = training_day, %Date{} = date, %Time{} = time) do
    occurrence = occurrence_on_or_before(training_day, date)
    start = NaiveDateTime.new!(occurrence, training_day.starts_at)
    now = NaiveDateTime.new!(date, Time.truncate(time, :second))

    if NaiveDateTime.compare(start, now) == :gt do
      # Today's occurrence has not started yet, take last week's.
      NaiveDateTime.add(start, -7, :day)
    else
      start
    end
  end
end
