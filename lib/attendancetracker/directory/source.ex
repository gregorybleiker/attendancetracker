defmodule AttendanceTracker.Directory.Source do
  @moduledoc """
  Behaviour for user-management connectors.

  A source knows how to fetch members from *some* external user management —
  a REST API (see `AttendanceTracker.Directory.Webling`), but equally an LDAP
  directory, a CSV export, another database, ... — and normalise them into the
  shape the importer understands.

  New connectors are registered in `AttendanceTracker.Directory.sources/0` and
  only need to implement this behaviour; the admin UI and the import pipeline
  (preview, matching, skipping) are source-agnostic.
  """

  @typedoc """
  A normalised member. `first_name`/`last_name` are required (they make up the
  participant name); `phone` and `training` are optional.
  """
  @type member :: %{
          required(:first_name) => String.t() | nil,
          required(:last_name) => String.t() | nil,
          optional(:phone) => String.t() | nil,
          optional(:training) => String.t() | nil
        }

  @typedoc """
  Description of one configuration field, rendered as an input in the admin
  UI and persisted as a string setting.
  """
  @type config_field :: %{
          key: atom(),
          label: String.t(),
          default: String.t(),
          secret: boolean()
        }

  @doc "Human readable name shown in the admin UI."
  @callback label() :: String.t()

  @doc "The configuration fields the admin UI renders for this source."
  @callback config_fields() :: [config_field()]

  @doc """
  Returns the members belonging to a training whose name matches one of the
  given `training_names` (the aliases of the configured trainings).

  Implementations decide how to match (REST filters, in-memory comparison, ...)
  and must return `{:ok, []}` when `training_names` is empty.
  """
  @callback fetch_members(training_names :: [String.t()], config :: map()) ::
              {:ok, [member()]} | {:error, term()}
end
