defmodule AttendanceTracker.Repo.Migrations.CreateEventParticipants do
  use Ecto.Migration

  def change do
    create table(:event_participants) do
      add :event_id, references(:events, on_delete: :delete_all), null: false
      add :participant_id, references(:participants, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:event_participants, [:event_id, :participant_id])
    create index(:event_participants, [:participant_id])
  end
end
