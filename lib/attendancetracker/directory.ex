defmodule AttendanceTracker.Directory do
  @moduledoc """
  Context for importing participants from an external user-management system.

  The selected connector (see `AttendanceTracker.Directory.Source`) and its
  configuration are stored in the settings table, so the connection can be
  configured from the admin area without a redeploy.

  The import is a two-step, source-agnostic flow: `preview/0` fetches the
  members and reports which would be created, then `import_members/1` creates
  the missing participants.
  """

  import Ecto.Changeset

  alias AttendanceTracker.Directory.Webling
  alias AttendanceTracker.Repo
  alias AttendanceTracker.Tracker
  alias AttendanceTracker.Tracker.Participant
  alias AttendanceTracker.Tracker.Setting

  @default_sources %{"webling" => Webling}

  @source_key "directory_source"
  @config_key "directory_config"
  @default_source "webling"

  @doc """
  All registered connectors, as a map of `id => module`.

  Extra connectors can be registered (e.g. in `config/config.exs`) via
  `config :attendancetracker, :directory_sources, %{"csv" => MyCsvSource}`.
  """
  def sources do
    Map.merge(@default_sources, Application.get_env(:attendancetracker, :directory_sources, %{}))
  end

  @doc "The ids of all registered connectors."
  def source_ids, do: Map.keys(sources())

  @doc "The id of the selected connector (falls back to the default)."
  def source do
    case Repo.get_by(Setting, key: @source_key) do
      %Setting{value: value} ->
        if Map.has_key?(sources(), value), do: value, else: @default_source

      nil ->
        @default_source
    end
  end

  @doc "The module implementing the given connector id."
  def source_module(id \\ source()), do: Map.fetch!(sources(), id)

  @doc "The configuration fields declared by a connector."
  def config_fields(id \\ source()), do: source_module(id).config_fields()

  @doc "The stored configuration of a connector, as a string-keyed map."
  def config(id \\ source()) do
    load_all_config() |> Map.get(id, %{})
  end

  @doc """
  A schemaless changeset for the admin settings form: the connector choice
  plus its configuration fields, pre-filled with stored values or defaults.
  """
  def change_settings(source_id \\ source(), params \\ %{}) do
    fields = config_fields(source_id)
    types = fields |> config_types() |> Map.put(:source, :string)
    data = fields |> config_defaults(source_id) |> Map.put(:source, source_id)

    {data, types}
    |> cast(params, Map.keys(types))
    |> validate_inclusion(:source, source_ids())
  end

  @doc """
  Persists the selected connector and its configuration.

  `params` is the string-keyed form payload; only the fields declared by the
  connector are stored.
  """
  def save_settings(source_id, params) do
    if Map.has_key?(sources(), source_id) do
      config_map =
        Map.new(config_fields(source_id), fn field ->
          key = Atom.to_string(field.key)
          {key, Map.get(params, key, field.default)}
        end)

      all = Map.put(load_all_config(), source_id, config_map)

      with {:ok, _} <- upsert(@config_key, Jason.encode!(all)),
           {:ok, _} <- upsert(@source_key, source_id) do
        {:ok, source_id}
      end
    else
      {:error, :unknown_source}
    end
  end

  @doc """
  Fetches members for the trainings that have an alias and splits them into
  those that would be created (`new`) and those matching an existing
  participant (`existing`, which the import flags as Webling members).

  Returns `{:ok, %{new: [candidate], existing: [candidate], total: integer}}`,
  `{:error, :no_named_trainings}` when no training has an alias, or
  `{:error, reason}` when the connector fails.
  """
  def preview do
    case named_trainings() do
      [] ->
        {:error, :no_named_trainings}

      names ->
        source_id = source()
        module = source_module(source_id)

        with {:ok, members} <- module.fetch_members(names, config(source_id)) do
          candidates =
            members
            |> Enum.map(&to_candidate/1)
            |> Enum.reject(&is_nil/1)
            |> Enum.uniq_by(&normalise_name(&1.name))

          by_name = participants_by_name()

          {existing, new} =
            Enum.split_with(candidates, &Map.has_key?(by_name, normalise_name(&1.name)))

          {:ok, %{new: new, existing: existing, total: length(candidates)}}
        end
    end
  end

  @doc """
  Creates a participant (source `"webling"`) for every new candidate and flags
  the name-matched existing participants as Webling members.

  Takes the result of `preview/0` and returns
  `{:ok, %{created: integer, linked: integer}}`.
  """
  def import_members(%{new: new, existing: existing}) do
    {created, _seen} =
      Enum.reduce(new, {0, participants_by_name() |> Map.keys() |> MapSet.new()}, fn candidate,
                                                                                     {created,
                                                                                      seen} ->
        key = normalise_name(candidate.name)

        if MapSet.member?(seen, key) do
          {created, seen}
        else
          case Tracker.create_participant(
                 %{name: candidate.name, emergency_number: candidate.phone, active: true},
                 "webling"
               ) do
            {:ok, _participant} -> {created + 1, MapSet.put(seen, key)}
            {:error, _changeset} -> {created, seen}
          end
        end
      end)

    linked =
      Enum.reduce(existing, 0, fn candidate, linked ->
        case Map.get(participants_by_name(), normalise_name(candidate.name)) do
          %Participant{} = participant ->
            if Participant.webling?(participant) do
              linked
            else
              case Tracker.set_participant_source(participant, "webling") do
                {:ok, _} -> linked + 1
                {:error, _} -> linked
              end
            end

          nil ->
            linked
        end
      end)

    {:ok, %{created: created, linked: linked}}
  end

  defp named_trainings do
    Tracker.list_trainings()
    |> Enum.map(& &1.name)
    |> Enum.map(&if(is_binary(&1), do: String.trim(&1), else: ""))
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
  end

  defp to_candidate(member) do
    first = clean(member[:first_name])
    last = clean(member[:last_name])
    name = [first, last] |> Enum.reject(&is_nil/1) |> Enum.join(" ")

    if name == "" do
      nil
    else
      %{name: name, first_name: first, last_name: last, phone: clean(member[:phone])}
    end
  end

  defp clean(nil), do: nil

  defp clean(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      trimmed -> trimmed
    end
  end

  defp clean(_value), do: nil

  defp participants_by_name do
    Tracker.list_participants()
    |> Enum.reduce(%{}, fn participant, acc ->
      Map.put_new(acc, normalise_name(participant.name), participant)
    end)
  end

  defp normalise_name(name) when is_binary(name) do
    name |> String.trim() |> String.replace(~r/\s+/, " ") |> String.downcase()
  end

  defp normalise_name(_name), do: ""

  defp config_types(fields) do
    Map.new(fields, fn field -> {field.key, :string} end)
  end

  defp config_defaults(fields, source_id) do
    stored = config(source_id)

    Map.new(fields, fn field ->
      key = Atom.to_string(field.key)
      {field.key, Map.get(stored, key, field.default)}
    end)
  end

  defp load_all_config do
    case Repo.get_by(Setting, key: @config_key) do
      %Setting{value: value} when is_binary(value) ->
        case Jason.decode(value) do
          {:ok, map} when is_map(map) -> map
          _ -> %{}
        end

      _ ->
        %{}
    end
  end

  defp upsert(key, value) do
    setting = Repo.get_by(Setting, key: key) || %Setting{key: key}

    setting
    |> Setting.changeset(%{value: value})
    |> Repo.insert_or_update()
  end
end
