defmodule AttendanceTracker.Tracker.Participant do
  use Ecto.Schema
  import Ecto.Changeset

  schema "participants" do
    field :first_name, :string
    field :last_name, :string
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

    # Populated by the context's queries (see `Tracker.with_attended_trainings/1`):
    # the distinct trainings this participant has ever attended.
    field :attended_trainings, :any, virtual: true, default: []

    has_one :photo, AttendanceTracker.Tracker.ParticipantPhoto
    has_many :check_ins, AttendanceTracker.Tracker.CheckIn
    has_many :training_members, AttendanceTracker.Tracker.TrainingMember
    has_many :event_participants, AttendanceTracker.Tracker.EventParticipant

    many_to_many :trainings, AttendanceTracker.Tracker.Training,
      join_through: AttendanceTracker.Tracker.TrainingMember

    many_to_many :events, AttendanceTracker.Tracker.Event,
      join_through: AttendanceTracker.Tracker.EventParticipant

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(participant, attrs) do
    participant
    |> cast(attrs, [:first_name, :last_name, :emergency_number, :active])
    |> validate_name()
  end

  # At least one of first/last name must be present.
  defp validate_name(changeset) do
    if blank?(get_field(changeset, :first_name)) and blank?(get_field(changeset, :last_name)) do
      add_error(changeset, :first_name, "can't be blank")
    else
      changeset
    end
  end

  @doc "The participant's display name, e.g. `\"Ada Lovelace\"`."
  def full_name(%__MODULE__{} = participant) do
    [participant.first_name, participant.last_name]
    |> Enum.reject(&blank?/1)
    |> Enum.join(" ")
  end

  defp blank?(value), do: value in [nil, ""]

  @doc "True when the participant was imported from Webling."
  def webling?(%__MODULE__{source: "webling"}), do: true
  def webling?(_participant), do: false

  @doc "True when the participant only exists in AttendanceTracker."
  def local?(participant), do: not webling?(participant)
end
