defmodule AttendanceTrackerWeb.ReportLive do
  use AttendanceTrackerWeb, :live_view

  alias AttendanceTracker.Tracker
  alias AttendanceTracker.Tracker.Participant
  alias AttendanceTracker.Tracker.Training

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} admin_mode={@admin_mode}>
      <.header>
        {gettext("Reporting")}
        <:subtitle>
          {gettext("Download the attendance report for a full year as a CSV file.")}
        </:subtitle>
      </.header>

      <div class="max-w-sm">
        <.form for={@form} id="report-form" action={~p"/reporting/download"} method="get">
          <.input field={@form[:year]} type="select" label={gettext("Year")} options={@years} />
          <footer>
            <.button variant="primary">
              <.icon name="hero-arrow-down-tray" class="size-5" /> {gettext("Download CSV")}
            </.button>
          </footer>
        </.form>
      </div>

      <section class="mt-12">
        <.header>
          {gettext("Not in Webling")}
          <:subtitle>
            {gettext("Participants who are not in Webling but have attended a training.")}
          </:subtitle>
        </.header>

        <p :if={@local_attenders == []} id="non-webling-attenders-empty" class="text-sm opacity-70">
          {gettext("Nobody yet.")}
        </p>

        <table
          :if={@local_attenders != []}
          id="non-webling-attenders"
          class="table table-sm max-w-2xl"
        >
          <thead>
            <tr>
              <th>{gettext("Name")}</th>
              <th>{gettext("Trainings attended")}</th>
            </tr>
          </thead>
          <tbody>
            <tr :for={participant <- @local_attenders} id={"non-webling-#{participant.id}"}>
              <td>
                <.link navigate={~p"/participants/#{participant.id}"} class="link link-primary">
                  {Participant.full_name(participant)}
                </.link>
              </td>
              <td class="opacity-80">
                {Enum.map_join(participant.attended_trainings, ", ", &Training.label/1)}
              </td>
            </tr>
          </tbody>
        </table>
      </section>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    years = Tracker.list_session_years()

    {:ok,
     socket
     |> assign(:page_title, gettext("Reporting"))
     |> assign(:years, years)
     |> assign(:form, to_form(%{"year" => hd(years)}))
     |> assign(:local_attenders, Tracker.list_local_participants_with_attendance())}
  end
end
