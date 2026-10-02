defmodule AttendanceTrackerWeb.TrainingLive.Form do
  use AttendanceTrackerWeb, :live_view

  alias AttendanceTracker.Tracker
  alias AttendanceTracker.Tracker.Training
  alias AttendanceTrackerWeb.TrainingLabels

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} admin_mode={@admin_mode}>
      <.header>
        {@page_title}
        <:subtitle>{gettext("For example: every Monday from 19:00 to 21:30.")}</:subtitle>
      </.header>

      <.form for={@form} id="training-form" phx-change="validate" phx-submit="save">
        <.input
          field={@form[:name]}
          type="text"
          label={gettext("Alias")}
          placeholder={gettext("Kids Judo Monday")}
        />
        <.input
          field={@form[:weekday]}
          type="select"
          label={gettext("Weekday")}
          prompt={gettext("Choose a weekday")}
          options={weekday_options()}
        />
        <.input field={@form[:starts_at]} type="time" label={gettext("Start")} />
        <.input field={@form[:ends_at]} type="time" label={gettext("End")} />

        <footer>
          <.button phx-disable-with={gettext("Saving...")} variant="primary">
            {gettext("Save training")}
          </.button>
          <.button navigate={~p"/training"}>{gettext("Cancel")}</.button>
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
    training = Tracker.get_training!(id)

    socket
    |> assign(:page_title, gettext("Edit training"))
    |> assign(:training, training)
    |> assign(:form, to_form(Tracker.change_training(training)))
  end

  defp apply_action(socket, :new, _params) do
    training = %Training{}

    socket
    |> assign(:page_title, gettext("New training"))
    |> assign(:training, training)
    |> assign(:form, to_form(Tracker.change_training(training)))
  end

  @impl true
  def handle_event("validate", %{"training" => training_params}, socket) do
    changeset = Tracker.change_training(socket.assigns.training, training_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"training" => training_params}, socket) do
    save_training(socket, socket.assigns.live_action, training_params)
  end

  defp save_training(socket, :edit, training_params) do
    case Tracker.update_training(socket.assigns.training, training_params) do
      {:ok, _training} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Training updated successfully"))
         |> push_navigate(to: ~p"/training")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_training(socket, :new, training_params) do
    case Tracker.create_training(training_params) do
      {:ok, _training} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Training created successfully"))
         |> push_navigate(to: ~p"/training")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp weekday_options do
    Enum.map(Training.weekday_options(), fn {_label, weekday} ->
      {TrainingLabels.weekday_label(weekday), weekday}
    end)
  end
end
