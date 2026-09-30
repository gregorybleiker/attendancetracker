defmodule AttendanceTrackerWeb.AdminLive do
  use AttendanceTrackerWeb, :live_view

  alias AttendanceTracker.Directory
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

        <div class="space-y-6 border-t border-base-300 pt-8">
          <div>
            <h2 class="text-lg font-semibold">User management import</h2>
            <p class="mt-1 text-sm opacity-70">
              Fetch members from an external user management system and create
              participants for members enrolled in a training whose name equals a
              training's alias.
            </p>
          </div>

          <.form
            for={@directory_form}
            id="directory-settings-form"
            phx-change="validate_directory"
            phx-submit="save_directory"
          >
            <.input
              field={@directory_form[:source]}
              type="select"
              label="Connector"
              options={@directory_source_options}
            />
            <.input
              :for={field <- @directory_fields}
              field={@directory_form[field.key]}
              type={if(field.secret, do: "password", else: "text")}
              label={field.label}
              autocomplete="off"
            />
            <footer>
              <.button variant="primary" phx-disable-with="Saving...">Save connection</.button>
            </footer>
          </.form>

          <div class="flex flex-wrap items-center gap-2">
            <.button
              id="directory-preview-btn"
              type="button"
              phx-click="preview_directory"
              phx-disable-with="Fetching..."
            >
              Fetch members
            </.button>
            <.button
              :if={@import_preview && @import_preview.new != []}
              id="directory-import-btn"
              type="button"
              variant="primary"
              phx-click="import_directory"
              phx-disable-with="Importing..."
            >
              Import {length(@import_preview.new)} participants
            </.button>
          </div>

          <div
            :if={@import_preview}
            id="directory-preview"
            class="space-y-3 rounded-xl border border-base-300 p-4 text-sm"
          >
            <p>
              {length(@import_preview.new)} new, {@import_preview.skipped} already present
              ({@import_preview.total} in matching trainings).
            </p>
            <ul :if={@import_preview.new != []} class="divide-y divide-base-200">
              <li
                :for={candidate <- @import_preview.new}
                class="flex items-center justify-between gap-4 py-1"
              >
                <span class="font-medium">{candidate.name}</span>
                <span class="opacity-70">{candidate.phone || "no number"}</span>
              </li>
            </ul>
            <p :if={@import_preview.new == []} class="opacity-70">
              Everyone is already a participant.
            </p>
          </div>
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
     |> assign(:expiry_form, expiry_changeset_form())
     |> assign_directory(Directory.source())}
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

  def handle_event("validate_directory", %{"directory" => params}, socket) do
    source_id = directory_source(params, socket)
    changeset = Directory.change_settings(source_id, params)

    {:noreply,
     socket
     |> assign(:directory_source, source_id)
     |> assign(:directory_fields, Directory.config_fields(source_id))
     |> assign(:directory_form, to_form(changeset, as: :directory, action: :validate))
     |> assign(:import_preview, nil)}
  end

  def handle_event("save_directory", %{"directory" => params}, socket) do
    source_id = directory_source(params, socket)
    changeset = Directory.change_settings(source_id, params)

    if changeset.valid? do
      {:ok, saved} = Directory.save_settings(source_id, params)

      {:noreply,
       socket
       |> put_flash(:info, "User management connection saved")
       |> assign(:directory_source, saved)
       |> assign(:directory_fields, Directory.config_fields(saved))
       |> assign(:directory_form, to_form(Directory.change_settings(saved), as: :directory))
       |> assign(:import_preview, nil)}
    else
      {:noreply,
       assign(socket, :directory_form, to_form(changeset, as: :directory, action: :validate))}
    end
  end

  def handle_event("preview_directory", _params, socket) do
    case Directory.preview() do
      {:ok, preview} ->
        {:noreply, assign(socket, :import_preview, preview)}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, directory_error(reason))}
    end
  end

  def handle_event("import_directory", _params, socket) do
    case socket.assigns.import_preview do
      %{new: candidates} ->
        {:ok, %{created: created, skipped: skipped}} = Directory.import_members(candidates)

        {:noreply,
         socket
         |> put_flash(:info, "Imported #{created} participants (#{skipped} skipped)")
         |> assign(:import_preview, nil)}

      _ ->
        {:noreply, socket}
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

  defp assign_directory(socket, source_id) do
    socket
    |> assign(:directory_source, source_id)
    |> assign(:directory_source_options, directory_source_options())
    |> assign(:directory_fields, Directory.config_fields(source_id))
    |> assign(:directory_form, to_form(Directory.change_settings(source_id), as: :directory))
    |> assign(:import_preview, nil)
  end

  defp directory_source_options do
    Directory.sources()
    |> Enum.map(fn {id, module} -> {module.label(), id} end)
    |> Enum.sort_by(&elem(&1, 0))
  end

  defp directory_source(params, socket) do
    source_id = params["source"] || socket.assigns.directory_source

    if Map.has_key?(Directory.sources(), source_id) do
      source_id
    else
      socket.assigns.directory_source
    end
  end

  defp directory_error(:no_named_trainings) do
    "No training has an alias yet. Set an alias on a training first."
  end

  defp directory_error(:missing_apikey), do: "Add the user management API key first."

  defp directory_error({:webling_http_error, 401, _message}) do
    "The user management rejected the API key (401)."
  end

  defp directory_error({:webling_http_error, status, message}) do
    "The user management returned an error (#{status}): #{message}"
  end

  defp directory_error({:webling_request_failed, reason}) do
    "Could not reach the user management: #{inspect(reason)}"
  end

  defp directory_error(reason), do: "Fetch failed: #{inspect(reason)}"
end
