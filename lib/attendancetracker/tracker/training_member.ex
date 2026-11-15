defmodule AttendanceTracker.Tracker.TrainingMember do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc """
  Links a participant to a training they are a member of, e.g. imported from an
  external user-management system. Distinct from a `CheckIn`, which records
  attendance at a single dated `TrainingSession`.

  A member can be `hidden` from the training: hidden members are left out of the
  training's default kiosk list (see `Tracker.list_participants_with_check_ins/2`)
  but still appear under "show all". Checking a participant in un-hides them.
  """

  schema "training_members" do
    belongs_to :training, AttendanceTracker.Tracker.Training
    belongs_to :participant, AttendanceTracker.Tracker.Participant
    field :hidden, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(training_member, attrs) do
    training_member
    |> cast(attrs, [:training_id, :participant_id, :hidden])
    |> validate_required([:training_id, :participant_id])
    |> unique_constraint([:training_id, :participant_id])
  end
end
