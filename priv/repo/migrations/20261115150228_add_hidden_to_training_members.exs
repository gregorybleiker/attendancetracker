defmodule AttendanceTracker.Repo.Migrations.AddHiddenToTrainingMembers do
  use Ecto.Migration

  def change do
    alter table(:training_members) do
      # When true, the member is hidden from the training's default kiosk list
      # but still appears under "show all". Set back to false by a check-in.
      add :hidden, :boolean, default: false, null: false
    end
  end
end
