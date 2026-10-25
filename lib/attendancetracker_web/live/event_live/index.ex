defmodule AttendanceTrackerWeb.EventLive.Index do
  use AttendanceTrackerWeb, :live_view

  alias AttendanceTracker.Tracker
  alias AttendanceTracker.Tracker.Event
  alias AttendanceTrackerWeb.DateFormat

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} admin_mode={@admin_mode}>
      <.header>
        {gettext("Events")}
        <:subtitle>
          {gettext(
            "One-off events on a single day, e.g. a competition or a workshop, each with its own participant list."
          )}
        </:subtitle>
        <:actions>
          <.button variant="primary" navigate={~p"/events/new"}>
            <.icon name="hero-plus" /> {gettext("New event")}
          </.button>
        </:actions>
      </.header>

      <.table id="events" rows={@streams.events}>
        <:col :let={{_id, event}} label={gettext("Name")}>{event.name}</:col>
        <:col :let={{_id, event}} label={gettext("Date")}>
          {DateFormat.long_date(event.date)}
        </:col>
        <:col :let={{_id, event}} label={gettext("Time")}>
          {Event.time_range(event) || "–"}
        </:col>
        <:action :let={{_id, event}}>
          <.link navigate={~p"/events/#{event}"}>{gettext("Participants")}</.link>
        </:action>
        <:action :let={{_id, event}}>
          <.link navigate={~p"/events/#{event}/edit"}>{gettext("Edit")}</.link>
        </:action>
        <:action :let={{id, event}}>
          <.link
            phx-click={JS.push("delete", value: %{id: event.id}) |> hide("##{id}")}
            data-confirm={gettext("Are you sure?")}
          >
            {gettext("Delete")}
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
     |> assign(:page_title, gettext("Events"))
     |> stream(:events, Tracker.list_events())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    event = Tracker.get_event!(id)
    {:ok, _} = Tracker.delete_event(event)

    {:noreply,
     socket
     |> put_flash(:info, gettext("Event deleted successfully"))
     |> stream_delete(:events, event)}
  end
end
