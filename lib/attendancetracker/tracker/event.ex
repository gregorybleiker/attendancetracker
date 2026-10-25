defmodule AttendanceTracker.Tracker.Event do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc """
  A one-off event on a single day, e.g. a competition, a workshop or a
  demonstration. Like a `Training` but tied to a concrete date instead of a
  weekly schedule. Participants are selected for it explicitly.
  """

  schema "events" do
    field :name, :string
    field :date, :date
    field :starts_at, :time
    field :ends_at, :time

    has_many :event_participants, AttendanceTracker.Tracker.EventParticipant

    many_to_many :participants, AttendanceTracker.Tracker.Participant,
      join_through: AttendanceTracker.Tracker.EventParticipant

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [:name, :date, :starts_at, :ends_at])
    |> validate_required([:name, :date])
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
  A human readable time range, e.g. `"19:00–21:30"`, or `nil` when no times
  are set.
  """
  def time_range(%__MODULE__{} = event) do
    case {event.starts_at, event.ends_at} do
      {%Time{} = starts_at, %Time{} = ends_at} ->
        "#{Calendar.strftime(starts_at, "%H:%M")}–#{Calendar.strftime(ends_at, "%H:%M")}"

      {%Time{} = starts_at, nil} ->
        Calendar.strftime(starts_at, "%H:%M")

      _ ->
        nil
    end
  end
end
