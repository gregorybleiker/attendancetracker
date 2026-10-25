defmodule AttendanceTrackerWeb.EventLive.Show do
  use AttendanceTrackerWeb, :live_view

  import AttendanceTrackerWeb.ParticipantComponents

  alias AttendanceTracker.Tracker
  alias AttendanceTracker.Tracker.Event
  alias AttendanceTrackerWeb.DateFormat

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} admin_mode={@admin_mode}>
      <.header>
        {@event.name}
        <:subtitle>
          {DateFormat.long_date(@event.date)}
          <%= if @time_range do %>
            · {@time_range}
          <% end %>
        </:subtitle>
        <:actions>
          <.button navigate={~p"/events"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/events/#{@event}/edit"}>
            <.icon name="hero-pencil-square" /> {gettext("Edit event")}
          </.button>
        </:actions>
      </.header>

      <div class="flex flex-wrap items-end justify-between gap-2">
        <h2 class="text-lg font-semibold">{gettext("Select participants")}</h2>
        <div
          id="event-selected-count"
          class="rounded-full bg-base-200 px-4 py-1 text-sm font-semibold"
        >
          {gettext("%{count} selected", count: @selected_count)}
        </div>
      </div>

      <div
        id="event-participants"
        phx-update="stream"
        class="grid grid-cols-2 gap-4 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5"
      >
        <div
          id="event-participants-empty"
          class="hidden only:block rounded-xl border border-dashed border-base-300 p-8 text-center"
        >
          {gettext("No active participants yet.")}
          <.link navigate={~p"/participants/new"} class="link link-primary">{gettext("Add one")}</.link>
        </div>

        <div :for={{id, participant} <- @streams.participants} id={id}>
          <.selectable_card participant={participant} />
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    event = Tracker.get_event!(id)

    {:ok,
     socket
     |> assign(:page_title, event.name)
     |> assign(:event, event)
     |> assign(:time_range, Event.time_range(event))
     |> assign(:selected_count, length(Tracker.list_event_participant_ids(event)))
     |> stream(:participants, Tracker.list_participants_for_event(event))}
  end

  @impl true
  def handle_event("toggle", %{"id" => id}, socket) do
    event = socket.assigns.event
    participant = Tracker.get_participant!(id)

    if Tracker.event_participant?(event, participant) do
      {:ok, _} = Tracker.remove_event_participant(event, participant)
    else
      {:ok, _} = Tracker.add_event_participant(event, participant)
    end

    participant = Tracker.get_participant_for_event(event, participant.id)

    {:noreply,
     socket
     |> assign(:selected_count, length(Tracker.list_event_participant_ids(event)))
     |> stream_insert(:participants, participant)}
  end
end
