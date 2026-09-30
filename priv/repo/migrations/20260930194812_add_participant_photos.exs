defmodule AttendanceTracker.Repo.Migrations.AddParticipantPhotos do
  use Ecto.Migration

  def up do
    create table(:participant_photos) do
      add :participant_id, references(:participants, on_delete: :delete_all), null: false
      add :data, :binary, null: false
      add :content_type, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:participant_photos, [:participant_id])

    flush()

    import_photos_from_disk()

    alter table(:participants) do
      remove :photo, :string
    end
  end

  def down do
    alter table(:participants) do
      add :photo, :string
    end

    drop table(:participant_photos)
  end

  # Photos used to live on disk with their URL path stored in
  # `participants.photo`. Copy any that can still be found into the new
  # table so an existing deployment does not lose them.
  defp import_photos_from_disk do
    directories = upload_directories()
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    result = Ecto.Adapters.SQL.query!(repo(), "SELECT id, photo FROM participants")

    for [id, path] <- result.rows, is_binary(path) and path != "" do
      filename = Path.basename(path)

      data =
        Enum.find_value(directories, fn directory ->
          case File.read(Path.join(directory, filename)) do
            {:ok, data} -> data
            {:error, _reason} -> nil
          end
        end)

      if data do
        repo().insert_all("participant_photos", [
          %{
            participant_id: id,
            data: data,
            content_type: content_type(filename),
            inserted_at: now,
            updated_at: now
          }
        ])
      end
    end
  end

  defp upload_directories do
    [
      Path.join([:code.priv_dir(:attendancetracker), "static", "uploads"]),
      "/data/uploads"
    ]
  end

  defp content_type(filename) do
    case filename |> Path.extname() |> String.downcase() do
      ".png" -> "image/png"
      ".webp" -> "image/webp"
      _ -> "image/jpeg"
    end
  end
end
