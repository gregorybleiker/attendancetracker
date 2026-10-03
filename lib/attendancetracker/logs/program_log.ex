defmodule AttendanceTracker.Logs.ProgramLog do
  @moduledoc """
  A program-log entry recording a background/sync operation (the full call)
  and its result.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "program_logs" do
    field :source, :string
    field :command, :string
    field :status, :string
    field :request, :string
    field :result, :string

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @doc false
  def changeset(log, attrs) do
    log
    |> cast(attrs, [:source, :command, :status, :request, :result])
    |> validate_required([:command, :status])
  end
end
