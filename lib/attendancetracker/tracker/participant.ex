defmodule AttendanceTracker.Tracker.Participant do
  use Ecto.Schema
  import Ecto.Changeset

  schema "participants" do
    field :name, :string
    field :photo, :string
    field :emergency_number, :string
    field :active, :boolean, default: true

    has_many :check_ins, AttendanceTracker.Tracker.CheckIn

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(participant, attrs) do
    participant
    |> cast(attrs, [:name, :photo, :emergency_number, :active])
    |> validate_required([:name])
  end
end
