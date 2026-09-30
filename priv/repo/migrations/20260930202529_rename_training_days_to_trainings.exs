defmodule AttendanceTracker.Repo.Migrations.RenameTrainingDaysToTrainings do
  use Ecto.Migration

  @old_index "training_sessions_training_day_id_date_index"
  @new_index "training_sessions_training_id_date_index"

  def up do
    rename table(:training_days), to: table(:trainings)
    rename table(:training_sessions), :training_day_id, to: :training_id

    # SQLite cannot rename an index, so recreate it under Ecto's derived name
    # (which `unique_constraint/2` matches against).
    execute "DROP INDEX IF EXISTS #{@old_index}"
    create unique_index(:training_sessions, [:training_id, :date], name: @new_index)
  end

  def down do
    execute "DROP INDEX IF EXISTS #{@new_index}"
    execute "DROP INDEX IF EXISTS #{@old_index}"

    rename table(:training_sessions), :training_id, to: :training_day_id
    create unique_index(:training_sessions, [:training_day_id, :date], name: @old_index)

    rename table(:trainings), to: table(:training_days)
  end
end
