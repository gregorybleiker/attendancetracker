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
        <div class="flex items-center gap-2">
          <button
            id="event-show-all-toggle"
            type="button"
            phx-click="toggle_show_all"
            class={[
              "flex cursor-pointer items-center gap-1.5 rounded-full border px-4 py-1 text-sm font-semibold transition-colors",
              if(@show_all,
                do: "border-primary bg-primary text-primary-content",
                else: "border-base-300 bg-base-100 hover:border-primary"
              )
            ]}
          >
            <.icon name={if @show_all, do: "hero-user-group", else: "hero-users"} class="size-4" />
            {if @show_all, do: gettext("Show selected"), else: gettext("Show all")}
          </button>
          <div
            id="event-selected-count"
            class="rounded-full bg-base-200 px-4 py-1 text-sm font-semibold"
          >
            {gettext("%{count} selected", count: @selected_count)}
          </div>
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
          <%= if @show_all do %>
            {gettext("No active participants yet.")}
            <.link navigate={~p"/participants/new"} class="link link-primary">{gettext("Add one")}</.link>
          <% else %>
            {gettext("No participants selected yet.")}
            <button
              type="button"
              phx-click="toggle_show_all"
              class="link link-primary cursor-pointer"
            >
              {gettext("Show all")}
            </button>
          <% end %>
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
     |> assign(:show_all, false)
     |> assign(:selected_count, length(Tracker.list_event_participant_ids(event)))
     |> stream(:participants, participants(event, false))}
  end

  @impl true
  def handle_event("toggle_show_all", _params, socket) do
    show_all = not socket.assigns.show_all

    {:noreply,
     socket
     |> assign(:show_all, show_all)
     |> stream(:participants, participants(socket.assigns.event, show_all), reset: true)}
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
     |> stream_participant(participant)}
  end

  defp participants(event, true), do: Tracker.list_participants_for_event(event)

  defp participants(event, false),
    do: Tracker.list_participants_for_event(event, only_selected: true)

  defp stream_participant(socket, participant) do
    if socket.assigns.show_all or participant.event_participants != [] do
      stream_insert(socket, :participants, participant)
    else
      stream_delete(socket, :participants, participant)
    end
  end
end
