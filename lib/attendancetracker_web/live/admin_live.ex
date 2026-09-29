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

      <div :if={@unlocked} id="admin-panel" class="max-w-sm space-y-8">
        <div class="space-y-6">
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

        <div class="space-y-6 border-t border-base-300 pt-8">
          <div>
            <h2 class="text-lg font-semibold">Session PIN</h2>
            <p class="mt-1 text-sm opacity-70">
              Required to start a kiosk session on the check-in screen. It is
              separate from the admin PIN.
              <%= if @session_pin_configured do %>
                A session PIN is configured.
              <% else %>
                No session PIN configured yet — the kiosk is currently open to everyone.
              <% end %>
            </p>
          </div>

          <.form for={@session_pin_form} id="session-pin-form" phx-submit="change_session_pin">
            <.input
              field={@session_pin_form[:new_pin]}
              type="password"
              label="New session PIN"
              inputmode="numeric"
              autocomplete="off"
            />
            <.input
              field={@session_pin_form[:new_pin_confirmation]}
              type="password"
              label="Confirm new session PIN"
              inputmode="numeric"
              autocomplete="off"
            />
            <footer>
              <.button variant="primary" phx-disable-with="Saving...">Save session PIN</.button>
            </footer>
          </.form>
        </div>

        <div class="space-y-6 border-t border-base-300 pt-8">
          <div>
            <h2 class="text-lg font-semibold">Session expiry</h2>
            <p class="mt-1 text-sm opacity-70">
              How long a started kiosk session stays unlocked before the session
              PIN is required again. Defaults to 30 days.
            </p>
          </div>

          <.form for={@expiry_form} id="session-expiry-form" phx-submit="change_session_expiry">
            <.input
              field={@expiry_form[:days]}
              type="number"
              label="Session duration (days)"
              min="1"
              max="3650"
              inputmode="numeric"
            />
            <footer>
              <.button variant="primary" phx-disable-with="Saving...">Save expiry</.button>
            </footer>
          </.form>
        </div>
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
     |> assign(:form, pin_changeset_form())
     |> assign(:session_pin_configured, Tracker.session_pin_configured?())
     |> assign(:session_pin_form, session_pin_changeset_form())
     |> assign(:expiry_form, expiry_changeset_form())}
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

  def handle_event("change_session_pin", %{"session_pin" => params}, socket) do
    changeset = Tracker.change_session_pin(params)

    if changeset.valid? do
      {:ok, _} = Tracker.update_session_pin(Ecto.Changeset.get_field(changeset, :new_pin))

      {:noreply,
       socket
       |> put_flash(:info, "Session PIN updated")
       |> assign(:session_pin_configured, true)
       |> assign(:session_pin_form, session_pin_changeset_form())}
    else
      {:noreply,
       assign(socket, :session_pin_form, to_form(changeset, as: :session_pin, action: :validate))}
    end
  end

  def handle_event("change_session_expiry", %{"session_expiry" => params}, socket) do
    changeset = Tracker.change_session_expiry_days(params)

    if changeset.valid? do
      days = Ecto.Changeset.get_field(changeset, :days)
      {:ok, _} = Tracker.update_session_expiry_days(days)

      {:noreply,
       socket
       |> put_flash(:info, "Session expiry updated")
       |> assign(:expiry_form, expiry_changeset_form())}
    else
      {:noreply,
       assign(socket, :expiry_form, to_form(changeset, as: :session_expiry, action: :validate))}
    end
  end

  defp pin_changeset_form do
    to_form(Tracker.change_admin_pin(), as: :pin)
  end

  defp session_pin_changeset_form do
    to_form(Tracker.change_session_pin(), as: :session_pin)
  end

  defp expiry_changeset_form do
    params = %{days: Tracker.session_expiry_days()}
    to_form(Tracker.change_session_expiry_days(params), as: :session_expiry)
  end
end
