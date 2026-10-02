defmodule AttendanceTracker.Repo.Migrations.AddSourceToParticipants do
  use Ecto.Migration

  def change do
    alter table(:participants) do
      add :source, :string, null: false, default: "local"
    end
  end
end
