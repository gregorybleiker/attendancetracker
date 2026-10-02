defmodule AttendanceTrackerWeb.SessionUnlockLive do
  use AttendanceTrackerWeb, :live_view

  alias AttendanceTracker.Tracker

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} admin_mode={@admin_mode}>
      <.header>
        {gettext("Start session")}
        <:subtitle>{gettext("Enter the session PIN to unlock the check-in screen.")}</:subtitle>
      </.header>

      <div class="max-w-sm">
        <.form for={@form} id="session-unlock-form" action={~p"/start"} method="post">
          <.input
            field={@form[:pin]}
            type="password"
            label={gettext("Session PIN")}
            inputmode="numeric"
            autocomplete="off"
          />
          <footer>
            <.button variant="primary">{gettext("Start session")}</.button>
          </footer>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if Tracker.session_pin_configured?() do
      {:ok,
       socket
       |> assign(:page_title, gettext("Start session"))
       |> assign(:form, to_form(%{"pin" => ""}))}
    else
      {:ok, redirect(socket, to: ~p"/")}
    end
  end
end
