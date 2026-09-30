defmodule AttendanceTrackerWeb.ParticipantComponents do
  @moduledoc """
  Function components for displaying participants.
  """
  use AttendanceTrackerWeb, :html

  attr :participant, :map, required: true
  attr :class, :string, default: "size-24 sm:size-28"
  attr :text_class, :string, default: "text-3xl"
  attr :dim, :boolean, default: false, doc: "render the avatar greyed out (not checked in)"

  @doc """
  Renders a participant's photo, or their initials as a fallback.
  """
  def avatar(assigns) do
    ~H"""
    <%= if photo_url(@participant) do %>
      <img
        src={photo_url(@participant)}
        alt={@participant.name}
        class={[@class, "rounded-full object-cover", @dim && "opacity-60 grayscale"]}
      />
    <% else %>
      <div class={[
        @class,
        @text_class,
        "flex items-center justify-center rounded-full bg-base-300 font-bold",
        @dim && "opacity-60 grayscale"
      ]}>
        {initials(@participant.name)}
      </div>
    <% end %>
    """
  end

  @doc """
  Returns the public URL for a participant's photo, or `nil` when they have
  none. The `updated_at` timestamp is part of the URL so the browser cache is
  busted whenever the photo is replaced.
  """
  def photo_url(%{has_photo: true, photo_updated_at: %DateTime{} = updated_at} = participant) do
    ~p"/photos/#{participant.id}/#{DateTime.to_unix(updated_at)}"
  end

  def photo_url(_participant), do: nil

  defp initials(name) do
    name
    |> String.split(~r/\s+/, trim: true)
    |> Enum.take(2)
    |> Enum.map_join(&String.first/1)
    |> String.upcase()
  end
end
