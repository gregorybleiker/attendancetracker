defmodule AttendanceTrackerWeb.ReportLive do
  use AttendanceTrackerWeb, :live_view

  alias AttendanceTracker.Tracker

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Reporting
        <:subtitle>Download the attendance report for a full year as a CSV file.</:subtitle>
      </.header>

      <div class="max-w-sm">
        <.form for={@form} id="report-form" action={~p"/reporting/download"} method="get">
          <.input field={@form[:year]} type="select" label="Year" options={@years} />
          <footer>
            <.button variant="primary">
              <.icon name="hero-arrow-down-tray" class="size-5" /> Download CSV
            </.button>
          </footer>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    years = Tracker.list_session_years()

    {:ok,
     socket
     |> assign(:page_title, "Reporting")
     |> assign(:years, years)
     |> assign(:form, to_form(%{"year" => hd(years)}))}
  end
end
