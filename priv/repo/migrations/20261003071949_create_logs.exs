defmodule AttendanceTracker.Repo.Migrations.CreateLogs do
  use Ecto.Migration

  def change do
    create table(:audit_logs) do
      add :action, :string, null: false
      add :participant_id, :integer
      add :participant_name, :string
      add :training_session_id, :integer

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create table(:program_logs) do
      add :source, :string
      add :command, :string, null: false
      add :status, :string, null: false
      add :request, :string
      add :result, :string

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:audit_logs, [:inserted_at])
    create index(:program_logs, [:inserted_at])
  end
end
