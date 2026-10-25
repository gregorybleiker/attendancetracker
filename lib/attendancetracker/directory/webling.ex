defmodule AttendanceTracker.Directory.Webling do
  @moduledoc """
  `AttendanceTracker.Directory.Source` connector for the
  [Webling](https://www.webling.ch) member database API.

  Every member is returned, except those whose configurable `exit_field`
  property is non-empty (former members). The trainings a member is enrolled in
  are read from the configurable `training_field` property (a multi-value list
  or a delimited string) and handed to the importer, which creates any that
  don't exist yet.

  Configuration keys (all strings): `base_url`, `apikey`, `training_field`,
  `exit_field`, `first_name_property`, `last_name_property`, `phone_property`.
  """

  @behaviour AttendanceTracker.Directory.Source

  @default_base_url "https://demo.webling.ch"
  @per_page 200
  @max_pages 50

  @impl true
  def label, do: "Webling"

  @impl true
  def config_fields do
    [
      %{
        key: :base_url,
        label: "Base URL",
        default: @default_base_url,
        secret: false
      },
      %{key: :apikey, label: "API key", default: "", secret: true},
      %{key: :training_field, label: "Training field", default: "Training", secret: false},
      %{key: :exit_field, label: "Exit field", default: "Austritt", secret: false},
      %{key: :first_name_property, label: "First-name field", default: "Vorname", secret: false},
      %{key: :last_name_property, label: "Last-name field", default: "Name", secret: false},
      %{key: :phone_property, label: "Phone field", default: "Telefon", secret: false}
    ]
  end

  @impl true
  def fetch_members(config) do
    if get_config(config, "apikey", "") == "" do
      {:error, :missing_apikey}
    else
      with {:ok, objects} <- fetch_all(config, "/member", format: "full") do
        members =
          objects
          |> Enum.reject(&exited?(&1, config))
          |> Enum.map(&normalise_member(&1, config))
          |> Enum.reject(&is_nil/1)

        {:ok, members}
      end
    end
  end

  defp exited?(%{"properties" => properties}, config) when is_map(properties) do
    field = get_config(config, "exit_field", default("exit_field"))
    properties |> Map.get(field) |> present?()
  end

  defp exited?(_object, _config), do: false

  defp present?(value) when is_binary(value), do: String.trim(value) != ""
  defp present?(value) when is_integer(value), do: value != 0
  defp present?(value) when is_list(value), do: Enum.any?(value, &present?/1)
  defp present?(_value), do: false

  defp training_names(properties, config) do
    field = get_config(config, "training_field", default("training_field"))
    properties |> Map.get(field) |> split_trainings()
  end

  defp split_trainings(value) when is_list(value) do
    value |> Enum.flat_map(&split_trainings/1) |> Enum.uniq()
  end

  defp split_trainings(value) when is_integer(value), do: [Integer.to_string(value)]

  defp split_trainings(value) when is_binary(value) do
    value
    |> String.split([";", ",", "\n"])
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
  end

  defp split_trainings(_value), do: []

  defp fetch_all(config, path, params, page \\ 1, acc \\ []) do
    params = Keyword.merge(params, page: page, per_page: @per_page)

    with {:ok, body} <- request(config, path, params) do
      batch = objects(body)
      acc = acc ++ batch

      if length(batch) == @per_page and page < @max_pages do
        fetch_all(config, path, params, page + 1, acc)
      else
        {:ok, acc}
      end
    end
  end

  defp request(config, path, params) do
    base_url =
      config |> get_config("base_url", @default_base_url) |> String.trim_trailing("/")

    apikey = get_config(config, "apikey", "")
    url = base_url <> "/api/1" <> path

    options =
      Application.get_env(:attendancetracker, :directory_req_options, [])
      |> Keyword.merge(
        params: params,
        headers: [{"apikey", apikey}],
        receive_timeout: 15_000
      )

    case Req.get(url, options) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, {:webling_http_error, status, error_message(body)}}

      {:error, reason} ->
        {:error, {:webling_request_failed, reason}}
    end
  end

  defp objects(%{"objects" => list}) when is_list(list), do: list
  defp objects(list) when is_list(list), do: list
  defp objects(_body), do: []

  defp normalise_member(%{"properties" => properties}, config) when is_map(properties) do
    %{
      first_name: property(properties, config, "first_name_property"),
      last_name: property(properties, config, "last_name_property"),
      phone: property(properties, config, "phone_property"),
      trainings: training_names(properties, config)
    }
  end

  defp normalise_member(_object, _config), do: nil

  defp property(properties, config, key) do
    field = get_config(config, key, default(key))
    value = if field, do: Map.get(properties, field), else: nil

    case value do
      value when is_binary(value) ->
        case String.trim(value) do
          "" -> nil
          trimmed -> trimmed
        end

      value when is_integer(value) ->
        Integer.to_string(value)

      _ ->
        nil
    end
  end

  defp default(key) do
    case Enum.find(config_fields(), fn field -> Atom.to_string(field.key) == key end) do
      %{default: value} -> value
      nil -> nil
    end
  end

  defp error_message(%{"error" => message}) when is_binary(message), do: message
  defp error_message(body) when is_binary(body), do: body
  defp error_message(body), do: inspect(body)

  defp get_config(config, key, default) do
    Map.get(config, key, Map.get(config, String.to_atom(key), default))
  end
end
