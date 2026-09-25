defmodule AttendanceTrackerWeb.ParticipantLive.Index do
  use AttendanceTrackerWeb, :live_view

  import AttendanceTrackerWeb.ParticipantComponents

  alias AttendanceTracker.Tracker

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} admin_mode={@admin_mode}>
      <.header>
        Listing Participants
        <:actions>
          <.button variant="primary" navigate={~p"/participants/new"}>
            <.icon name="hero-plus" /> New Participant
          </.button>
        </:actions>
      </.header>

      <.table
        id="participants"
        rows={@streams.participants}
        row_click={fn {_id, participant} -> JS.navigate(~p"/participants/#{participant}") end}
      >
        <:col :let={{_id, participant}} label="Photo">
          <.avatar participant={participant} class="size-10" text_class="text-xs" />
        </:col>
        <:col :let={{_id, participant}} label="Name">{participant.name}</:col>
        <:col :let={{_id, participant}} label="Active">{participant.active}</:col>
        <:action :let={{_id, participant}}>
          <div class="sr-only">
            <.link navigate={~p"/participants/#{participant}"}>Show</.link>
          </div>
          <.link navigate={~p"/participants/#{participant}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, participant}}>
          <.link
            phx-click={JS.push("delete", value: %{id: participant.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Listing Participants")
     |> stream(:participants, list_participants())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    participant = Tracker.get_participant!(id)
    {:ok, _} = Tracker.delete_participant(participant)

    {:noreply, stream_delete(socket, :participants, participant)}
  end

  defp list_participants() do
    Tracker.list_participants()
  end
end
