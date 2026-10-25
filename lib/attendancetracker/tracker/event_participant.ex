defmodule AttendanceTracker.Tracker.EventParticipant do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc """
  Links a participant to an event they take part in. The event equivalent of
  `TrainingMember`.
  """

  schema "event_participants" do
    belongs_to :event, AttendanceTracker.Tracker.Event
    belongs_to :participant, AttendanceTracker.Tracker.Participant

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(event_participant, attrs) do
    event_participant
    |> cast(attrs, [:event_id, :participant_id])
    |> validate_required([:event_id, :participant_id])
    |> unique_constraint([:event_id, :participant_id])
  end
end
