defmodule AttendanceTracker.Tracker.TrainingSession do
  use Ecto.Schema
  import Ecto.Changeset

  schema "training_sessions" do
    field :date, :date

    belongs_to :training, AttendanceTracker.Tracker.Training
    has_many :check_ins, AttendanceTracker.Tracker.CheckIn

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(training_session, attrs) do
    training_session
    |> cast(attrs, [:date, :training_id])
    |> validate_required([:date])
    |> unique_constraint(:date)
    |> unique_constraint([:training_id, :date])
  end
end
