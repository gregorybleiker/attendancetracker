defmodule AttendanceTracker.Tracker.TrainingMember do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc """
  Links a participant to a training they are a member of, e.g. imported from an
  external user-management system. Distinct from a `CheckIn`, which records
  attendance at a single dated `TrainingSession`.
  """

  schema "training_members" do
    belongs_to :training, AttendanceTracker.Tracker.Training
    belongs_to :participant, AttendanceTracker.Tracker.Participant

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(training_member, attrs) do
    training_member
    |> cast(attrs, [:training_id, :participant_id])
    |> validate_required([:training_id, :participant_id])
    |> unique_constraint([:training_id, :participant_id])
  end
end
