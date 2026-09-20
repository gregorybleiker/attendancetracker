defmodule AttendanceTracker.Tracker.CheckIn do
  use Ecto.Schema
  import Ecto.Changeset

  schema "check_ins" do
    belongs_to :participant, AttendanceTracker.Tracker.Participant
    belongs_to :training_session, AttendanceTracker.Tracker.TrainingSession

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(check_in, attrs) do
    check_in
    |> cast(attrs, [:participant_id, :training_session_id])
    |> validate_required([:participant_id, :training_session_id])
    |> unique_constraint([:participant_id, :training_session_id])
  end
end
