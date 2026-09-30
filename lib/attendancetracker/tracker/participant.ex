defmodule AttendanceTracker.Tracker.Participant do
  use Ecto.Schema
  import Ecto.Changeset

  schema "participants" do
    field :name, :string
    field :emergency_number, :string
    field :active, :boolean, default: true

    # Populated by the context's queries (see `Tracker.with_photo/1`), never
    # stored: the photo bytes themselves live in `participant_photos`.
    field :has_photo, :boolean, virtual: true, default: false
    field :photo_updated_at, :utc_datetime, virtual: true

    has_one :photo, AttendanceTracker.Tracker.ParticipantPhoto
    has_many :check_ins, AttendanceTracker.Tracker.CheckIn

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(participant, attrs) do
    participant
    |> cast(attrs, [:name, :emergency_number, :active])
    |> validate_required([:name])
  end
end
