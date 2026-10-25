defmodule AttendanceTrackerWeb.EventLive.Form do
  use AttendanceTrackerWeb, :live_view

  alias AttendanceTracker.Tracker
  alias AttendanceTracker.Tracker.Event

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} admin_mode={@admin_mode}>
      <.header>
        {@page_title}
        <:subtitle>
          {gettext("For example: a competition on 12 September, 09:00 to 17:00.")}
        </:subtitle>
      </.header>

      <.form for={@form} id="event-form" phx-change="validate" phx-submit="save">
        <.input
          field={@form[:name]}
          type="text"
          label={gettext("Name")}
          placeholder={gettext("Club championships")}
        />
        <.input field={@form[:date]} type="date" label={gettext("Date")} />
        <.input field={@form[:starts_at]} type="time" label={gettext("Start")} />
        <.input field={@form[:ends_at]} type="time" label={gettext("End")} />

        <footer>
          <.button phx-disable-with={gettext("Saving...")} variant="primary">
            {gettext("Save event")}
          </.button>
          <.button navigate={~p"/events"}>{gettext("Cancel")}</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    event = Tracker.get_event!(id)

    socket
    |> assign(:page_title, gettext("Edit event"))
    |> assign(:event, event)
    |> assign(:form, to_form(Tracker.change_event(event)))
  end

  defp apply_action(socket, :new, _params) do
    event = %Event{}

    socket
    |> assign(:page_title, gettext("New event"))
    |> assign(:event, event)
    |> assign(:form, to_form(Tracker.change_event(event)))
  end

  @impl true
  def handle_event("validate", %{"event" => event_params}, socket) do
    changeset = Tracker.change_event(socket.assigns.event, event_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"event" => event_params}, socket) do
    save_event(socket, socket.assigns.live_action, event_params)
  end

  defp save_event(socket, :edit, event_params) do
    case Tracker.update_event(socket.assigns.event, event_params) do
      {:ok, _event} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Event updated successfully"))
         |> push_navigate(to: ~p"/events")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_event(socket, :new, event_params) do
    case Tracker.create_event(event_params) do
      {:ok, event} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Event created successfully"))
         |> push_navigate(to: ~p"/events/#{event}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
