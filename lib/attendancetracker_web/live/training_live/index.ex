defmodule AttendanceTrackerWeb.TrainingLive.Index do
  use AttendanceTrackerWeb, :live_view

  alias AttendanceTracker.Tracker
  alias AttendanceTracker.Tracker.Training

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} admin_mode={@admin_mode}>
      <.header>
        Training
        <:subtitle>
          Configure the weekly training schedule, e.g. every Monday from 19:00 to 21:30.
          The check-in screen pre-selects the current training based on date and time.
        </:subtitle>
        <:actions>
          <.button variant="primary" navigate={~p"/training/new"}>
            <.icon name="hero-plus" /> New training
          </.button>
        </:actions>
      </.header>

      <.table id="trainings" rows={@streams.trainings}>
        <:col :let={{_id, training}} label="Alias">
          {training.name || "–"}
        </:col>
        <:col :let={{_id, training}} label="Weekday">
          {Training.weekday_name(training)}
        </:col>
        <:col :let={{_id, training}} label="Time">
          {Calendar.strftime(training.starts_at, "%H:%M")}–{Calendar.strftime(
            training.ends_at,
            "%H:%M"
          )}
        </:col>
        <:action :let={{_id, training}}>
          <.link navigate={~p"/training/#{training}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, training}}>
          <.link
            phx-click={JS.push("delete", value: %{id: training.id}) |> hide("##{id}")}
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
     |> assign(:page_title, "Training")
     |> stream(:trainings, Tracker.list_trainings())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    training = Tracker.get_training!(id)
    {:ok, _} = Tracker.delete_training(training)

    {:noreply, stream_delete(socket, :trainings, training)}
  end
end
