defmodule AttendanceTracker.Repo.Migrations.CreateTrainingMembers do
  use Ecto.Migration

  def change do
    create table(:training_members) do
      add :training_id, references(:trainings, on_delete: :delete_all), null: false
      add :participant_id, references(:participants, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:training_members, [:training_id, :participant_id])
    create index(:training_members, [:participant_id])
  end
end
