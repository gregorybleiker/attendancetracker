defmodule AttendanceTrackerWeb.LoginLive do
  use AttendanceTrackerWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} admin_mode={@admin_mode}>
      <.header>
        AttendanceTracker
        <:subtitle>{gettext("Enter the admin PIN to continue.")}</:subtitle>
      </.header>

      <div class="max-w-sm">
        <.form for={@form} id="login-form" action={~p"/login"} method="post">
          <.input
            field={@form[:pin]}
            type="password"
            label={gettext("Admin PIN")}
            inputmode="numeric"
            autocomplete="off"
          />
          <footer>
            <.button variant="primary">{gettext("Log in")}</.button>
          </footer>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, session, socket) do
    if session["admin_pin_ok"] do
      {:ok, redirect(socket, to: ~p"/")}
    else
      {:ok,
       socket
       |> assign(:page_title, gettext("Log in"))
       |> assign(:form, to_form(%{"pin" => ""}))}
    end
  end
end
