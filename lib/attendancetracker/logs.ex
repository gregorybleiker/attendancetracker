defmodule AttendanceTracker.Logs do
  @moduledoc """
  Context for the two application log streams:

    * `audit/1` — user interactions (check-in / revert of a check-in).
    * `program/1` — sync operations (the full call and its result).

  Both streams are capped at a configurable number of entries (default
  #{10_000}): every insert opportunistically trims the oldest rows and `prune/0`
  is also run periodically by `AttendanceTracker.Logs.Pruner`.
  """

  import Ecto.Query

  alias AttendanceTracker.Logs.AuditLog
  alias AttendanceTracker.Logs.ProgramLog
  alias AttendanceTracker.Repo
  alias AttendanceTracker.Tracker.Setting

  @max_entries_key "log_max_entries"
  @prune_interval_key "log_prune_interval_minutes"
  @default_max_entries 10_000
  @default_prune_interval_minutes 60

  ## Writing

  @doc "Records an audit-log entry and trims the log to its maximum size."
  def audit(attrs) do
    %AuditLog{}
    |> AuditLog.changeset(attrs)
    |> Repo.insert()
    |> tap(fn _ -> prune_table(AuditLog) end)
  end

  @doc "Records a program-log entry and trims the log to its maximum size."
  def program(attrs) do
    %ProgramLog{}
    |> ProgramLog.changeset(attrs)
    |> Repo.insert()
    |> tap(fn _ -> prune_table(ProgramLog) end)
  end

  ## Reading

  @doc "Returns the newest audit-log entries, newest first."
  def list_audit_logs(limit \\ 100) do
    Repo.all(from l in AuditLog, order_by: [desc: l.id], limit: ^limit)
  end

  @doc "Returns the newest program-log entries, newest first."
  def list_program_logs(limit \\ 100) do
    Repo.all(from l in ProgramLog, order_by: [desc: l.id], limit: ^limit)
  end

  ## Pruning

  @doc "Trims both logs down to the configured maximum number of entries."
  def prune do
    prune_table(AuditLog)
    prune_table(ProgramLog)
  end

  defp prune_table(schema) do
    max = max_entries()

    threshold =
      Repo.one(from l in schema, order_by: [desc: l.id], offset: ^max, limit: 1, select: l.id)

    if threshold, do: Repo.delete_all(from l in schema, where: l.id <= ^threshold)
  end

  ## Settings

  @doc "Maximum number of entries kept per log (default #{@default_max_entries})."
  def max_entries do
    parse_int(setting(@max_entries_key), @default_max_entries)
  end

  @doc "How often the logs are pruned, in minutes (default 60)."
  def prune_interval_minutes do
    parse_int(setting(@prune_interval_key), @default_prune_interval_minutes)
  end

  @doc "How often the logs are pruned, in seconds."
  def prune_interval_seconds, do: prune_interval_minutes() * 60

  @doc "A changeset for the log settings form."
  def change_settings(params \\ %{}) do
    types = %{max_entries: :integer, prune_interval_minutes: :integer}

    {%{}, types}
    |> Ecto.Changeset.cast(params, [:max_entries, :prune_interval_minutes])
    |> Ecto.Changeset.validate_required([:max_entries, :prune_interval_minutes])
    |> Ecto.Changeset.validate_number(:max_entries,
      greater_than: 0,
      less_than_or_equal_to: 1_000_000
    )
    |> Ecto.Changeset.validate_number(:prune_interval_minutes,
      greater_than: 0,
      less_than_or_equal_to: 100_800
    )
  end

  @doc "Persists the log settings."
  def update_settings(max_entries, prune_interval_minutes) do
    with {:ok, _} <- upsert(@max_entries_key, Integer.to_string(max_entries)),
         {:ok, _} <- upsert(@prune_interval_key, Integer.to_string(prune_interval_minutes)) do
      :ok
    end
  end

  ## Helpers

  defp setting(key) do
    case Repo.get_by(Setting, key: key) do
      %Setting{value: value} -> value
      nil -> nil
    end
  end

  defp parse_int(nil, default), do: default

  defp parse_int(value, default) do
    case Integer.parse(value) do
      {int, ""} when int > 0 -> int
      _ -> default
    end
  end

  defp upsert(key, value) do
    setting = Repo.get_by(Setting, key: key) || %Setting{key: key}

    setting
    |> Setting.changeset(%{value: value})
    |> Repo.insert_or_update()
  end
end
