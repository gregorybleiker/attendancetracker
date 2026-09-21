defmodule AttendanceTracker.Repo.Migrations.AddEmergencyNumberToParticipants do
  use Ecto.Migration

  def change do
    alter table(:participants) do
      add :emergency_number, :string
    end
  end
end
