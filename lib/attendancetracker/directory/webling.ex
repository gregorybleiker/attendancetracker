defmodule AttendanceTracker.Directory.Webling do
  @moduledoc """
  `AttendanceTracker.Directory.Source` connector for the
  [Webling](https://www.webling.ch) member database API.

  Members are matched by the title of the membergroup ("Training") they belong
  to: a member is returned when at least one of its parent groups has a title
  equal to one of the configured training aliases.

  Configuration keys (all strings): `base_url`, `apikey`,
  `first_name_property`, `last_name_property`, `phone_property`.
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
      %{key: :first_name_property, label: "First-name field", default: "Vorname", secret: false},
      %{key: :last_name_property, label: "Last-name field", default: "Name", secret: false},
      %{key: :phone_property, label: "Phone field", default: "Telefon", secret: false}
    ]
  end

  @impl true
  def fetch_members(training_names, config) do
    names = normalise_names(training_names)

    cond do
      names == [] ->
        {:ok, []}

      get_config(config, "apikey", "") == "" ->
        {:error, :missing_apikey}

      true ->
        with {:ok, objects} <- fetch_all(config, "/member", filter: filter(names), format: "full") do
          members =
            objects
            |> Enum.map(&normalise_member(&1, config))
            |> Enum.reject(&is_nil/1)

          {:ok, members}
        end
    end
  end

  defp normalise_names(names) do
    names
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
  end

  defp filter(names) do
    names
    |> Enum.map_join(" OR ", fn name -> ~s($parents.title = "#{escape(name)}") end)
  end

  defp escape(name), do: String.replace(name, "\"", "\\\"")

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
      phone: property(properties, config, "phone_property")
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
