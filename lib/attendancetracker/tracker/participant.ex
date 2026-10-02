defmodule AttendanceTracker.Tracker.Participant do
  use Ecto.Schema
  import Ecto.Changeset

  schema "participants" do
    field :name, :string
    field :emergency_number, :string
    field :active, :boolean, default: true

    # Where the participant came from: "local" (created here) or "webling"
    # (imported/flagged by the user-management import). Never cast from user
    # input; only the import sets it.
    field :source, :string, default: "local"

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

  @doc "True when the participant was imported from Webling."
  def webling?(%__MODULE__{source: "webling"}), do: true
  def webling?(_participant), do: false

  @doc "True when the participant only exists in AttendanceTracker."
  def local?(participant), do: not webling?(participant)
end
