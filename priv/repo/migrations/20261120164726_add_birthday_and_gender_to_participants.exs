defmodule AttendanceTracker.Repo.Migrations.AddBirthdayAndGenderToParticipants do
  use Ecto.Migration

  def change do
    alter table(:participants) do
      add :birthday, :date
      add :gender, :string
    end
  end
end
