defmodule AttendanceTracker.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  def change do
    create table(:events) do
      add :name, :string, null: false
      add :date, :date, null: false
      add :starts_at, :time
      add :ends_at, :time

      timestamps(type: :utc_datetime)
    end
  end
end
