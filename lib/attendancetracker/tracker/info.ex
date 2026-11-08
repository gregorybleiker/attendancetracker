defmodule AttendanceTracker.Tracker.Info do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc """
  A full-screen info slide shown on the kiosk when it has been idle.

  `body` holds rich-text HTML authored with the admin area's WYSIWYG editor.
  `position` orders the slides and `active` toggles whether a slide is shown.
  """

  schema "infos" do
    field :title, :string
    field :body, :string
    field :position, :integer, default: 0
    field :active, :boolean, default: true

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(info, attrs) do
    info
    |> cast(attrs, [:title, :body, :position, :active])
    |> validate_required([:body])
    |> validate_number(:position, greater_than_or_equal_to: 0)
    |> validate_length(:title, max: 200)
  end
end
