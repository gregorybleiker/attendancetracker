defmodule AttendanceTracker.Directory do
  @moduledoc """
  Context for importing participants from an external user-management system.

  The selected connector (see `AttendanceTracker.Directory.Source`) and its
  configuration are stored in the settings table, so the connection can be
  configured from the admin area without a redeploy.

  The import is a two-step, source-agnostic flow: `preview/0` fetches the
  members and reports which would be created and which trainings are missing,
  then `import_members/1` creates the missing trainings and participants.
  """

  import Ecto.Changeset

  alias AttendanceTracker.Directory.Webling
  alias AttendanceTracker.Logs
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
  Fetches all importable members and splits them into those that would be
  created (`new`) and those matching an existing participant (`existing`, which
  the import flags as Webling members).

  Also reports the `new_trainings` — the trainings the fetched members are
  enrolled in that don't exist yet — which `import_members/1` creates.

  Returns `{:ok, %{new: [candidate], existing: [candidate], total: integer,
  new_trainings: [String.t()]}}` or `{:error, reason}` when the connector fails.
  """
  def preview do
    source_id = source()
    module = source_module(source_id)
    config = config(source_id)

    case module.fetch_members(config) do
      {:ok, members} ->
        candidates =
          members
          |> Enum.map(&to_candidate/1)
          |> Enum.reject(&is_nil/1)
          |> Enum.uniq_by(&normalise_name(&1.name))

        by_name = participants_by_name()

        {existing, new} =
          Enum.split_with(candidates, &Map.has_key?(by_name, normalise_name(&1.name)))

        log_fetch(source_id, config, {:ok, length(members)})

        {:ok,
         %{
           new: new,
           existing: existing,
           total: length(candidates),
           new_trainings: missing_trainings(members)
         }}

      {:error, reason} = error ->
        log_fetch(source_id, config, {:error, reason})
        error
    end
  end

  @doc """
  Creates any missing trainings the members are enrolled in, then creates a
  participant (source `"webling"`) for every new candidate and flags the
  name-matched existing participants as Webling members.

  Member-training relationships are **additive**: a membership is added when the
  remote data lists the member in a training, but no membership is ever removed
  — memberships that exist locally but are not in the remote data are left
  untouched (see `link_memberships/1`).

  Takes the result of `preview/0` and returns `{:ok, %{created: integer,
  linked: integer, trainings_created: integer, memberships: integer}}`.
  """
  def import_members(%{new: new, existing: existing} = preview) do
    trainings_created = ensure_trainings(Map.get(preview, :new_trainings, []))

    {created, _seen} =
      Enum.reduce(new, {0, participants_by_name() |> Map.keys() |> MapSet.new()}, fn candidate,
                                                                                     {created,
                                                                                      seen} ->
        key = normalise_name(candidate.name)

        if MapSet.member?(seen, key) do
          {created, seen}
        else
          case Tracker.create_participant(
                 %{
                   first_name: candidate.first_name,
                   last_name: candidate.last_name,
                   emergency_number: candidate.phone,
                   active: true
                 },
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

    memberships = link_memberships(new ++ existing)

    Logs.program(%{
      source: source(),
      command: "import",
      status: "ok",
      request: "import #{length(new) + length(existing)} candidate(s)",
      result:
        "created #{created}, linked #{linked}, trainings #{length(trainings_created)}, " <>
          "memberships #{memberships}"
    })

    {:ok,
     %{
       created: created,
       linked: linked,
       trainings_created: length(trainings_created),
       memberships: memberships
     }}
  end

  @training_defaults %{weekday: 1, starts_at: ~T[19:00:00], ends_at: ~T[21:30:00]}

  defp ensure_trainings(names) do
    Enum.reduce(names, [], fn name, created ->
      case Tracker.create_training(Map.put(@training_defaults, :name, name)) do
        {:ok, training} -> [training | created]
        {:error, _changeset} -> created
      end
    end)
    |> Enum.reverse()
  end

  # Links every candidate to the trainings named in their training field,
  # resolving names to the trainings created or reused during the import.
  defp link_memberships(candidates) do
    by_participant = participants_by_name()
    by_training = trainings_by_name()

    Enum.reduce(candidates, 0, fn candidate, count ->
      case Map.get(by_participant, normalise_name(candidate.name)) do
        %Participant{} = participant ->
          candidate
          |> Map.get(:trainings, [])
          |> Enum.reduce(count, fn name, acc ->
            link_membership(participant, name, by_training, acc)
          end)

        nil ->
          count
      end
    end)
  end

  defp link_membership(participant, name, by_training, count) do
    case Map.get(by_training, normalise_name(name)) do
      %{id: id} = training when not is_nil(id) ->
        case Tracker.add_training_member(training, participant) do
          {:ok, :created} -> count + 1
          _ -> count
        end

      _ ->
        count
    end
  end

  defp trainings_by_name do
    Tracker.list_trainings()
    |> Enum.reduce(%{}, fn training, acc ->
      key = normalise_name(training.name)
      if key == "", do: acc, else: Map.put_new(acc, key, training)
    end)
  end

  defp missing_trainings(members) do
    existing =
      Tracker.list_trainings()
      |> Enum.map(&normalise_name(&1.name))
      |> MapSet.new()

    members
    |> Enum.flat_map(&Map.get(&1, :trainings, []))
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq_by(&normalise_name/1)
    |> Enum.reject(&MapSet.member?(existing, normalise_name(&1)))
  end

  defp log_fetch(source_id, config, result) do
    {status, text} =
      case result do
        {:ok, count} -> {"ok", "#{count} member(s) fetched"}
        {:error, reason} -> {"error", inspect(reason)}
      end

    Logs.program(%{
      source: source_id,
      command: "fetch_members",
      status: status,
      request: "#{source_id} #{Map.get(config, "base_url", "")}",
      result: text
    })
  end

  defp to_candidate(member) do
    first = clean(member[:first_name])
    last = clean(member[:last_name])
    name = [first, last] |> Enum.reject(&is_nil/1) |> Enum.join(" ")

    if name == "" do
      nil
    else
      %{
        name: name,
        first_name: first,
        last_name: last,
        phone: clean(member[:phone]),
        trainings: member_trainings(member)
      }
    end
  end

  defp member_trainings(member) do
    member
    |> Map.get(:trainings, [])
    |> List.wrap()
    |> Enum.map(&clean/1)
    |> Enum.reject(&is_nil/1)
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
      Map.put_new(acc, normalise_name(Participant.full_name(participant)), participant)
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
