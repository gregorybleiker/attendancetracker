defmodule AttendanceTracker.Tracker.ParticipantPhoto do
  use Ecto.Schema
  import Ecto.Changeset

  schema "participant_photos" do
    field :data, :binary
    field :content_type, :string

    belongs_to :participant, AttendanceTracker.Tracker.Participant

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(photo, attrs) do
    photo
    |> cast(attrs, [:data, :content_type])
    |> validate_required([:data, :content_type])
  end
end
