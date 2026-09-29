defmodule AttendanceTracker.Uploads do
  @moduledoc """
  Stores participant photos on disk.

  In a release the `priv/static/uploads` directory is a symlink to a
  persistent volume (`/data/uploads`, see `Dockerfile`). On a fresh volume the
  symlink target does not exist yet, and `File.mkdir_p!/1` fails with
  `:eexist` on a *dangling* symlink, so the target directory is created
  explicitly here before writing.
  """

  @doc """
  Writes binary contents to a new file in the uploads directory and returns
  its public URL path.
  """
  def write_binary(contents, extension) when is_binary(contents) do
    filename = Ecto.UUID.generate() <> extension

    case File.write(Path.join(uploads_dir(), filename), contents) do
      :ok -> {:ok, "/uploads/" <> filename}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Copies an uploaded temp file (a `Plug.Upload`) into the uploads directory
  and returns its public URL path.
  """
  def copy_uploaded(source, client_name) do
    filename = Ecto.UUID.generate() <> Path.extname(client_name)

    case File.cp(source, Path.join(uploads_dir(), filename)) do
      :ok -> {:ok, "/uploads/" <> filename}
      {:error, reason} -> {:error, reason}
    end
  end

  defp uploads_dir do
    dir = Path.join([:code.priv_dir(:attendancetracker), "static", "uploads"])
    ensure_dir!(dir)
    dir
  end

  defp ensure_dir!(dir) do
    cond do
      File.dir?(dir) ->
        :ok

      target = symlink_target(dir) ->
        File.mkdir_p!(target)

      true ->
        File.mkdir_p!(dir)
    end
  end

  defp symlink_target(dir) do
    case File.read_link(dir) do
      {:ok, target} -> target
      {:error, _reason} -> nil
    end
  end
end
