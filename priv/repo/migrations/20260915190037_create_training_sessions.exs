defmodule AttendanceTracker.Repo.Migrations.CreateTrainingSessions do
  use Ecto.Migration

  def change do
    create table(:training_sessions) do
      add :date, :date

      timestamps(type: :utc_datetime)
    end

    create unique_index(:training_sessions, [:date])
  end
end
