defmodule AttendanceTrackerWeb.EventCheckInLive do
  use AttendanceTrackerWeb, :live_view

  import AttendanceTrackerWeb.ParticipantComponents

  alias AttendanceTracker.Tracker
  alias AttendanceTracker.Tracker.Event
  alias AttendanceTrackerWeb.DateFormat

  @impl true
  def mount(_params, _lv_session, socket) do
    events = Tracker.list_events()

    {:ok,
     socket
     |> assign(:page_title, gettext("Event check-in"))
     |> assign(:events, events)
     |> assign(:event_options, event_options(events))
     |> assign_event(List.first(events))}
  end

  defp assign_event(socket, event) do
    socket
    |> assign(:event, event)
    |> assign(:event_form, to_form(%{"event_id" => event && event.id}))
    |> assign(:time_range, event && Event.time_range(event))
    |> assign(:selected_count, selected_count(event))
    |> stream(:participants, participants(event), reset: true)
  end

  defp participants(nil), do: []
  defp participants(event), do: Tracker.list_participants_for_event(event)

  defp selected_count(nil), do: 0
  defp selected_count(event), do: length(Tracker.list_event_participant_ids(event))

  defp event_options(events) do
    Enum.map(events, fn event ->
      {"#{event.name} · #{DateFormat.short_date(event.date)}", event.id}
    end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} admin_mode={@admin_mode}>
      <div
        :if={@events == []}
        class="rounded-xl border border-dashed border-base-300 p-8 text-center"
      >
        <p class="opacity-70">{gettext("No events yet.")}</p>
      </div>

      <div :if={@events != []} class="space-y-4">
        <.form for={@event_form} id="event-select" phx-change="select_event" class="max-w-md">
          <.input
            field={@event_form[:event_id]}
            type="select"
            label={gettext("Event")}
            options={@event_options}
          />
        </.form>

        <div class="flex flex-wrap items-end justify-between gap-2">
          <div>
            <h1 class="text-2xl font-bold">{@event.name}</h1>
            <p class="text-sm opacity-70">
              {DateFormat.long_date(@event.date)}
              <%= if @time_range do %>
                · {@time_range}
              <% end %>
            </p>
          </div>
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
          </div>

          <div :for={{id, participant} <- @streams.participants} id={id}>
            <.selectable_card participant={participant} />
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("select_event", %{"event_id" => id}, socket) do
    {:noreply, assign_event(socket, Tracker.get_event!(id))}
  end

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
     |> assign(:selected_count, selected_count(event))
     |> stream_insert(:participants, participant)}
  end
end
