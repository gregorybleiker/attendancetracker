defmodule AttendanceTracker.Repo.Migrations.SplitParticipantNames do
  use Ecto.Migration

  def up do
    alter table(:participants) do
      add :first_name, :string
      add :last_name, :string
    end

    # Backfill from the old single `name`: first word -> first_name, the rest ->
    # last_name.
    execute("""
    UPDATE participants SET
      first_name = CASE
        WHEN name IS NULL THEN NULL
        WHEN instr(name, ' ') > 0 THEN substr(name, 1, instr(name, ' ') - 1)
        ELSE name
      END,
      last_name = CASE
        WHEN name IS NULL THEN NULL
        WHEN instr(name, ' ') > 0 THEN trim(substr(name, instr(name, ' ') + 1))
        ELSE NULL
      END
    """)

    alter table(:participants) do
      remove :name
    end
  end

  def down do
    alter table(:participants) do
      add :name, :string
    end

    execute(
      "UPDATE participants SET name = trim(coalesce(first_name, '') || ' ' || coalesce(last_name, ''))"
    )

    alter table(:participants) do
      remove :first_name
      remove :last_name
    end
  end
end
