defmodule AttendanceTracker.Tracker.Setting do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc """
  A generic key-value setting, e.g. the admin PIN.
  """

  schema "settings" do
    field :key, :string
    field :value, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(setting, attrs) do
    setting
    |> cast(attrs, [:key, :value])
    |> validate_required([:key, :value])
    |> unique_constraint(:key)
  end
end
