defmodule AttendanceTracker.Repo.Migrations.CreateCheckIns do
  use Ecto.Migration

  def change do
    create table(:check_ins) do
      add :participant_id, references(:participants, on_delete: :delete_all), null: false

      add :training_session_id, references(:training_sessions, on_delete: :delete_all),
        null: false

      timestamps(type: :utc_datetime)
    end

    create index(:check_ins, [:training_session_id])
    create unique_index(:check_ins, [:participant_id, :training_session_id])
  end
end
