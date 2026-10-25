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
  A normalised member. `first_name`/`last_name` make up the participant name
  (at least one is required); `phone` and `trainings` are optional. `trainings`
  lists the trainings the member is enrolled in, so the importer can create any
  that don't exist yet.
  """
  @type member :: %{
          required(:first_name) => String.t() | nil,
          required(:last_name) => String.t() | nil,
          optional(:phone) => String.t() | nil,
          optional(:trainings) => [String.t()]
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
  Returns the members to import.

  Implementations return one normalised map per member that should become a
  participant, excluding former members (e.g. via a configurable exit field).
  The importer creates a participant for each and creates any missing trainings
  named in `:trainings`.
  """
  @callback fetch_members(config :: map()) :: {:ok, [member()]} | {:error, term()}
end
