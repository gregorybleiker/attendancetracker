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
    <%= if @participant.photo do %>
      <img
        src={@participant.photo}
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

  defp initials(name) do
    name
    |> String.split(~r/\s+/, trim: true)
    |> Enum.take(2)
    |> Enum.map_join(&String.first/1)
    |> String.upcase()
  end
end
