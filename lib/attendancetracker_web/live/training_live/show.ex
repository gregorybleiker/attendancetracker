defmodule AttendanceTrackerWeb.TrainingLive.Show do
  use AttendanceTrackerWeb, :live_view

  import AttendanceTrackerWeb.ParticipantComponents

  alias AttendanceTracker.Tracker
  alias AttendanceTrackerWeb.TrainingLabels

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} admin_mode={@admin_mode}>
      <.header>
        {@training.name || TrainingLabels.weekday_label(@training.weekday)}
        <:subtitle>
          {gettext("Members of this training.")}
        </:subtitle>
        <:actions>
          <.button navigate={~p"/training"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/training/#{@training}/edit"}>
            <.icon name="hero-pencil-square" /> {gettext("Edit training")}
          </.button>
        </:actions>
      </.header>

      <.table :if={@members != []} id="training-members" rows={@members}>
        <:col :let={participant} label={gettext("Photo")}>
          <.avatar participant={participant} class="size-10" text_class="text-xs" />
        </:col>
        <:col :let={participant} label={gettext("Name")}>
          {AttendanceTracker.Tracker.Participant.full_name(participant)}
        </:col>
        <:col :let={participant} label={gettext("Notfallnummer")}>
          {participant.emergency_number}
        </:col>
        <:col :let={participant} label={gettext("Source")}>
          <.source_badge participant={participant} />
        </:col>
        <:action :let={participant}>
          <.link navigate={~p"/participants/#{participant}"}>{gettext("Show")}</.link>
        </:action>
      </.table>

      <p :if={@members == []} class="text-sm opacity-70">
        {gettext("No members yet.")}
      </p>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    training = Tracker.get_training!(id)

    {:ok,
     socket
     |> assign(:page_title, gettext("Training"))
     |> assign(:training, training)
     |> assign(:members, Tracker.list_training_members(training))}
  end
end
