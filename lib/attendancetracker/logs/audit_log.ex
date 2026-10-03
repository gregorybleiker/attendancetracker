defmodule AttendanceTracker.Logs.AuditLog do
  @moduledoc """
  An audit-log entry recording a user interaction (e.g. a check-in or the
  revert of one).
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "audit_logs" do
    field :action, :string
    field :participant_id, :integer
    field :participant_name, :string
    field :training_session_id, :integer

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @doc false
  def changeset(log, attrs) do
    log
    |> cast(attrs, [:action, :participant_id, :participant_name, :training_session_id])
    |> validate_required([:action])
  end
end
