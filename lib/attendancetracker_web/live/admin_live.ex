defmodule AttendanceTrackerWeb.AdminLive do
  use AttendanceTrackerWeb, :live_view

  alias AttendanceTracker.Directory
  alias AttendanceTracker.Logs
  alias AttendanceTracker.Tracker

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} admin_mode={@admin_mode}>
      <.header>
        {gettext("Admin")}
        <:subtitle>{gettext("Restricted area — enter the admin PIN to continue.")}</:subtitle>
        <:actions>
          <.button navigate={~p"/admin/logs"}>
            <.icon name="hero-document-text" /> {gettext("View logs")}
          </.button>
        </:actions>
      </.header>

      <div :if={not @unlocked} class="max-w-sm">
        <.form for={@pin_form} id="admin-unlock-form" phx-submit="unlock">
          <.input
            field={@pin_form[:pin]}
            type="password"
            label={gettext("Admin PIN")}
            inputmode="numeric"
            autocomplete="off"
          />
          <footer>
            <.button variant="primary" phx-disable-with={gettext("Unlocking...")}>
              {gettext("Unlock")}
            </.button>
          </footer>
        </.form>
      </div>

      <div :if={@unlocked} id="admin-panel" class="max-w-sm space-y-8">
        <div class="space-y-6">
          <div>
            <h2 class="text-lg font-semibold">{gettext("Change admin PIN")}</h2>
            <p class="mt-1 text-sm opacity-70">
              {gettext("The PIN is required to undo check-ins and to enter this area.")}
            </p>
          </div>

          <.form for={@form} id="admin-pin-form" phx-submit="change_pin">
            <.input
              field={@form[:new_pin]}
              type="password"
              label={gettext("New PIN")}
              inputmode="numeric"
              autocomplete="off"
            />
            <.input
              field={@form[:new_pin_confirmation]}
              type="password"
              label={gettext("Confirm new PIN")}
              inputmode="numeric"
              autocomplete="off"
            />
            <footer>
              <.button variant="primary" phx-disable-with={gettext("Saving...")}>
                {gettext("Save PIN")}
              </.button>
            </footer>
          </.form>
        </div>

        <div class="space-y-6 border-t border-base-300 pt-8">
          <div>
            <h2 class="text-lg font-semibold">{gettext("Session PIN")}</h2>
            <p class="mt-1 text-sm opacity-70">
              {gettext(
                "Required to start a kiosk session on the check-in screen. It is separate from the admin PIN."
              )}
              <%= if @session_pin_configured do %>
                {gettext("A session PIN is configured.")}
              <% else %>
                {gettext("No session PIN configured yet — the kiosk is currently open to everyone.")}
              <% end %>
            </p>
          </div>

          <.form for={@session_pin_form} id="session-pin-form" phx-submit="change_session_pin">
            <.input
              field={@session_pin_form[:new_pin]}
              type="password"
              label={gettext("New session PIN")}
              inputmode="numeric"
              autocomplete="off"
            />
            <.input
              field={@session_pin_form[:new_pin_confirmation]}
              type="password"
              label={gettext("Confirm new session PIN")}
              inputmode="numeric"
              autocomplete="off"
            />
            <footer>
              <.button variant="primary" phx-disable-with={gettext("Saving...")}>
                {gettext("Save session PIN")}
              </.button>
            </footer>
          </.form>
        </div>

        <div class="space-y-6 border-t border-base-300 pt-8">
          <div>
            <h2 class="text-lg font-semibold">{gettext("Session expiry")}</h2>
            <p class="mt-1 text-sm opacity-70">
              {gettext(
                "How long a started kiosk session stays unlocked before the session PIN is required again. Defaults to 30 days."
              )}
            </p>
          </div>

          <.form for={@expiry_form} id="session-expiry-form" phx-submit="change_session_expiry">
            <.input
              field={@expiry_form[:days]}
              type="number"
              label={gettext("Session duration (days)")}
              min="1"
              max="3650"
              inputmode="numeric"
            />
            <footer>
              <.button variant="primary" phx-disable-with={gettext("Saving...")}>
                {gettext("Save expiry")}
              </.button>
            </footer>
          </.form>
        </div>

        <div class="space-y-6 border-t border-base-300 pt-8">
          <div>
            <h2 class="text-lg font-semibold">{gettext("Logs")}</h2>
            <p class="mt-1 text-sm opacity-70">
              {gettext(
                "The audit log records check-ins and reverts; the program log records sync calls and their results. Both are capped and the oldest entries are pruned periodically."
              )}
            </p>
          </div>

          <.form for={@log_form} id="logs-settings-form" phx-submit="save_log_settings">
            <.input
              field={@log_form[:max_entries]}
              type="number"
              label={gettext("Maximum entries per log")}
              min="1"
              max="1000000"
              inputmode="numeric"
            />
            <.input
              field={@log_form[:prune_interval_minutes]}
              type="number"
              label={gettext("Prune interval (minutes)")}
              min="1"
              max="100800"
              inputmode="numeric"
            />
            <footer>
              <.button variant="primary" phx-disable-with={gettext("Saving...")}>
                {gettext("Save log settings")}
              </.button>
            </footer>
          </.form>
        </div>

        <div class="space-y-6 border-t border-base-300 pt-8">
          <div>
            <h2 class="text-lg font-semibold">{gettext("User management import")}</h2>
            <p class="mt-1 text-sm opacity-70">
              {gettext(
                "Fetch members from an external user management system and create participants for members enrolled in a training whose name equals a training's alias."
              )}
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
              label={gettext("Connector")}
              options={@directory_source_options}
            />
            <.input
              :for={field <- @directory_fields}
              field={@directory_form[field.key]}
              type={if(field.secret, do: "password", else: "text")}
              label={directory_field_label(field)}
              autocomplete="off"
            />
            <footer>
              <.button variant="primary" phx-disable-with={gettext("Saving...")}>
                {gettext("Save connection")}
              </.button>
            </footer>
          </.form>

          <div class="flex flex-wrap items-center gap-2">
            <.button
              id="directory-preview-btn"
              type="button"
              phx-click="preview_directory"
              phx-disable-with={gettext("Fetching...")}
            >
              {gettext("Fetch members")}
            </.button>
            <.button
              :if={@import_preview && @import_preview.new != []}
              id="directory-import-btn"
              type="button"
              variant="primary"
              phx-click="import_directory"
              phx-disable-with={gettext("Importing...")}
            >
              {gettext("Import %{count} participants", count: length(@import_preview.new))}
            </.button>
          </div>

          <div
            :if={@import_preview}
            id="directory-preview"
            class="space-y-3 rounded-xl border border-base-300 p-4 text-sm"
          >
            <p>
              {gettext(
                "%{new} new, %{existing} matched to existing participants (%{total} in matching trainings).",
                new: length(@import_preview.new),
                existing: length(@import_preview.existing),
                total: @import_preview.total
              )}
            </p>
            <ul :if={@import_preview.new != []} class="divide-y divide-base-200">
              <li
                :for={candidate <- @import_preview.new}
                class="flex items-center justify-between gap-4 py-1"
              >
                <span class="font-medium">{candidate.name}</span>
                <span class="opacity-70">{candidate.phone || gettext("no number")}</span>
              </li>
            </ul>
            <p :if={@import_preview.new == []} class="opacity-70">
              {gettext("Everyone is already a participant.")}
            </p>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, session, socket) do
    {:ok,
     socket
     |> assign(:page_title, gettext("Admin"))
     |> assign(:unlocked, session["admin_pin_ok"] == true)
     |> assign(:pin_form, to_form(%{"pin" => ""}))
     |> assign(:form, pin_changeset_form())
     |> assign(:session_pin_configured, Tracker.session_pin_configured?())
     |> assign(:session_pin_form, session_pin_changeset_form())
     |> assign(:expiry_form, expiry_changeset_form())
     |> assign(:log_form, log_changeset_form())
     |> assign_directory(Directory.source())}
  end

  @impl true
  def handle_event("unlock", %{"pin" => pin}, socket) do
    if Tracker.admin_pin_valid?(pin) do
      {:noreply, assign(socket, :unlocked, true)}
    else
      {:noreply, assign(socket, :pin_form, to_form(%{"pin" => ""}, errors: wrong_pin_error()))}
    end
  end

  def handle_event("change_pin", %{"pin" => params}, socket) do
    changeset = Tracker.change_admin_pin(params)

    if changeset.valid? do
      {:ok, _} = Tracker.update_admin_pin(Ecto.Changeset.get_field(changeset, :new_pin))

      {:noreply,
       socket
       |> put_flash(:info, gettext("Admin PIN updated"))
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
       |> put_flash(:info, gettext("Session PIN updated"))
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
       |> put_flash(:info, gettext("Session expiry updated"))
       |> assign(:expiry_form, expiry_changeset_form())}
    else
      {:noreply,
       assign(socket, :expiry_form, to_form(changeset, as: :session_expiry, action: :validate))}
    end
  end

  def handle_event("save_log_settings", %{"logs" => params}, socket) do
    changeset = Logs.change_settings(params)

    if changeset.valid? do
      max_entries = Ecto.Changeset.get_field(changeset, :max_entries)
      interval = Ecto.Changeset.get_field(changeset, :prune_interval_minutes)
      :ok = Logs.update_settings(max_entries, interval)

      {:noreply,
       socket
       |> put_flash(:info, gettext("Log settings updated"))
       |> assign(:log_form, log_changeset_form())}
    else
      {:noreply, assign(socket, :log_form, to_form(changeset, as: :logs, action: :validate))}
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
       |> put_flash(:info, gettext("User management connection saved"))
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
      %{new: _} = preview ->
        {:ok, %{created: created, linked: linked}} = Directory.import_members(preview)

        {:noreply,
         socket
         |> put_flash(
           :info,
           gettext("Imported %{created} participants (%{linked} linked to Webling)",
             created: created,
             linked: linked
           )
         )
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

  defp log_changeset_form do
    params = %{
      max_entries: Logs.max_entries(),
      prune_interval_minutes: Logs.prune_interval_minutes()
    }

    to_form(Logs.change_settings(params), as: :logs)
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

  defp directory_field_label(%{key: :base_url}), do: gettext("Base URL")
  defp directory_field_label(%{key: :apikey}), do: gettext("API key")
  defp directory_field_label(%{key: :training_field}), do: gettext("Training field")
  defp directory_field_label(%{key: :first_name_property}), do: gettext("First-name field")
  defp directory_field_label(%{key: :last_name_property}), do: gettext("Last-name field")
  defp directory_field_label(%{key: :phone_property}), do: gettext("Phone field")
  defp directory_field_label(%{label: label}), do: label

  defp wrong_pin_error, do: [pin: {gettext("Wrong PIN"), []}]

  defp directory_error(:no_named_trainings) do
    gettext("No training has an alias yet. Set an alias on a training first.")
  end

  defp directory_error(:missing_apikey), do: gettext("Add the user management API key first.")

  defp directory_error({:webling_http_error, 401, _message}) do
    gettext("The user management rejected the API key (401).")
  end

  defp directory_error({:webling_http_error, status, message}) do
    gettext("The user management returned an error (%{status}): %{message}",
      status: status,
      message: message
    )
  end

  defp directory_error({:webling_request_failed, reason}) do
    gettext("Could not reach the user management: %{reason}", reason: inspect(reason))
  end

  defp directory_error(reason), do: gettext("Fetch failed: %{reason}", reason: inspect(reason))
end
