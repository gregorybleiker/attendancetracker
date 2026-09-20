defmodule AttendanceTrackerWeb.TrainingDayLive.Index do
  use AttendanceTrackerWeb, :live_view

  alias AttendanceTracker.Tracker
  alias AttendanceTracker.Tracker.TrainingDay

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Training days
        <:subtitle>
          Configure the weekly training schedule, e.g. every Monday from 19:00 to 21:30.
          The check-in screen pre-selects the current training based on date and time.
        </:subtitle>
        <:actions>
          <.button variant="primary" navigate={~p"/training_days/new"}>
            <.icon name="hero-plus" /> New training day
          </.button>
        </:actions>
      </.header>

      <.table id="training-days" rows={@streams.training_days}>
        <:col :let={{_id, training_day}} label="Alias">
          {training_day.name || "–"}
        </:col>
        <:col :let={{_id, training_day}} label="Weekday">
          {TrainingDay.weekday_name(training_day)}
        </:col>
        <:col :let={{_id, training_day}} label="Time">
          {Calendar.strftime(training_day.starts_at, "%H:%M")}–{Calendar.strftime(
            training_day.ends_at,
            "%H:%M"
          )}
        </:col>
        <:action :let={{_id, training_day}}>
          <.link navigate={~p"/training_days/#{training_day}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, training_day}}>
          <.link
            phx-click={JS.push("delete", value: %{id: training_day.id}) |> hide("##{id}")}
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
     |> assign(:page_title, "Training days")
     |> stream(:training_days, Tracker.list_training_days())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    training_day = Tracker.get_training_day!(id)
    {:ok, _} = Tracker.delete_training_day(training_day)

    {:noreply, stream_delete(socket, :training_days, training_day)}
  end
end
