defmodule AttendanceTrackerWeb.AdminLive do
  use AttendanceTrackerWeb, :live_view

  alias AttendanceTracker.Tracker

  @wrong_pin_error [pin: {"Wrong PIN", []}]

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} admin_mode={@admin_mode}>
      <.header>
        Admin
        <:subtitle>Restricted area — enter the admin PIN to continue.</:subtitle>
      </.header>

      <div :if={not @unlocked} class="max-w-sm">
        <.form for={@pin_form} id="admin-unlock-form" phx-submit="unlock">
          <.input
            field={@pin_form[:pin]}
            type="password"
            label="Admin PIN"
            inputmode="numeric"
            autocomplete="off"
          />
          <footer>
            <.button variant="primary" phx-disable-with="Unlocking...">Unlock</.button>
          </footer>
        </.form>
      </div>

      <div :if={@unlocked} id="admin-panel" class="max-w-sm space-y-6">
        <div>
          <h2 class="text-lg font-semibold">Change admin PIN</h2>
          <p class="mt-1 text-sm opacity-70">
            The PIN is required to undo check-ins and to enter this area.
          </p>
        </div>

        <.form for={@form} id="admin-pin-form" phx-submit="change_pin">
          <.input
            field={@form[:new_pin]}
            type="password"
            label="New PIN"
            inputmode="numeric"
            autocomplete="off"
          />
          <.input
            field={@form[:new_pin_confirmation]}
            type="password"
            label="Confirm new PIN"
            inputmode="numeric"
            autocomplete="off"
          />
          <footer>
            <.button variant="primary" phx-disable-with="Saving...">Save PIN</.button>
          </footer>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Admin")
     |> assign(:unlocked, false)
     |> assign(:pin_form, to_form(%{"pin" => ""}))
     |> assign(:form, pin_changeset_form())}
  end

  @impl true
  def handle_event("unlock", %{"pin" => pin}, socket) do
    if Tracker.admin_pin_valid?(pin) do
      {:noreply, assign(socket, :unlocked, true)}
    else
      {:noreply, assign(socket, :pin_form, to_form(%{"pin" => ""}, errors: @wrong_pin_error))}
    end
  end

  def handle_event("change_pin", %{"pin" => params}, socket) do
    changeset = Tracker.change_admin_pin(params)

    if changeset.valid? do
      {:ok, _} = Tracker.update_admin_pin(Ecto.Changeset.get_field(changeset, :new_pin))

      {:noreply,
       socket
       |> put_flash(:info, "Admin PIN updated")
       |> assign(:form, pin_changeset_form())}
    else
      {:noreply, assign(socket, :form, to_form(changeset, as: :pin, action: :validate))}
    end
  end

  defp pin_changeset_form do
    to_form(Tracker.change_admin_pin(), as: :pin)
  end
end
