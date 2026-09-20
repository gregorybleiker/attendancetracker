defmodule AttendanceTracker.Repo.Migrations.CreateTrainingDays do
  use Ecto.Migration

  def change do
    create table(:training_days) do
      # ISO 8601 day of week: 1 = Monday, 7 = Sunday
      add :weekday, :integer, null: false
      add :starts_at, :time, null: false
      add :ends_at, :time, null: false

      timestamps(type: :utc_datetime)
    end

    alter table(:training_sessions) do
      add :training_day_id, references(:training_days, on_delete: :nilify_all)
    end

    drop unique_index(:training_sessions, [:date])

    create unique_index(:training_sessions, [:training_day_id, :date])

    # Sessions without a training day (ad-hoc "today" sessions) stay unique per date.
    create unique_index(:training_sessions, [:date],
             where: "training_day_id IS NULL",
             name: :training_sessions_date_index
           )
  end
end
