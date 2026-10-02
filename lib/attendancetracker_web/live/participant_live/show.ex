defmodule AttendanceTrackerWeb.ParticipantLive.Show do
  use AttendanceTrackerWeb, :live_view

  import AttendanceTrackerWeb.ParticipantComponents

  alias AttendanceTracker.Tracker

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} admin_mode={@admin_mode}>
      <.header>
        {gettext("Participant %{id}", id: @participant.id)}
        <:subtitle>{gettext("This is a participant record from your database.")}</:subtitle>
        <:actions>
          <.button navigate={~p"/participants"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/participants/#{@participant}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> {gettext("Edit participant")}
          </.button>
        </:actions>
      </.header>

      <.avatar participant={@participant} />

      <.list>
        <:item title={gettext("Name")}>{@participant.name}</:item>
        <:item title={gettext("Notfallnummer")}>{@participant.emergency_number}</:item>
        <:item title={gettext("Active")}>{@participant.active}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, gettext("Show Participant"))
     |> assign(:participant, Tracker.get_participant!(id))}
  end
end
