defmodule AttendanceTrackerWeb.TrainingDayLive.Form do
  use AttendanceTrackerWeb, :live_view

  alias AttendanceTracker.Tracker
  alias AttendanceTracker.Tracker.TrainingDay

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} admin_mode={@admin_mode}>
      <.header>
        {@page_title}
        <:subtitle>For example: every Monday from 19:00 to 21:30.</:subtitle>
      </.header>

      <.form for={@form} id="training-day-form" phx-change="validate" phx-submit="save">
        <.input
          field={@form[:name]}
          type="text"
          label="Alias"
          placeholder="Kids Judo Monday"
        />
        <.input
          field={@form[:weekday]}
          type="select"
          label="Weekday"
          prompt="Choose a weekday"
          options={TrainingDay.weekday_options()}
        />
        <.input field={@form[:starts_at]} type="time" label="Start" />
        <.input field={@form[:ends_at]} type="time" label="End" />

        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Training day</.button>
          <.button navigate={~p"/training_days"}>Cancel</.button>
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
    training_day = Tracker.get_training_day!(id)

    socket
    |> assign(:page_title, "Edit Training day")
    |> assign(:training_day, training_day)
    |> assign(:form, to_form(Tracker.change_training_day(training_day)))
  end

  defp apply_action(socket, :new, _params) do
    training_day = %TrainingDay{}

    socket
    |> assign(:page_title, "New Training day")
    |> assign(:training_day, training_day)
    |> assign(:form, to_form(Tracker.change_training_day(training_day)))
  end

  @impl true
  def handle_event("validate", %{"training_day" => training_day_params}, socket) do
    changeset = Tracker.change_training_day(socket.assigns.training_day, training_day_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"training_day" => training_day_params}, socket) do
    save_training_day(socket, socket.assigns.live_action, training_day_params)
  end

  defp save_training_day(socket, :edit, training_day_params) do
    case Tracker.update_training_day(socket.assigns.training_day, training_day_params) do
      {:ok, _training_day} ->
        {:noreply,
         socket
         |> put_flash(:info, "Training day updated successfully")
         |> push_navigate(to: ~p"/training_days")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_training_day(socket, :new, training_day_params) do
    case Tracker.create_training_day(training_day_params) do
      {:ok, _training_day} ->
        {:noreply,
         socket
         |> put_flash(:info, "Training day created successfully")
         |> push_navigate(to: ~p"/training_days")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
