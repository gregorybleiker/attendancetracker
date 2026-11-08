defmodule AttendanceTracker.Repo.Migrations.CreateInfos do
  use Ecto.Migration

  def change do
    create table(:infos) do
      add :title, :string
      add :body, :text
      add :position, :integer, default: 0, null: false
      add :active, :boolean, default: true, null: false

      timestamps(type: :utc_datetime)
    end
  end
end
