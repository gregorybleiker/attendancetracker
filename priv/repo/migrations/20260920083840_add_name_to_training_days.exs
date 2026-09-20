defmodule AttendanceTracker.Repo.Migrations.AddNameToTrainingDays do
  use Ecto.Migration

  def change do
    alter table(:training_days) do
      add :name, :string
    end
  end
end
