defmodule AttendanceTrackerWeb.AdminInfosLive do
  use AttendanceTrackerWeb, :live_view

  import AttendanceTrackerWeb.InfoComponents

  alias AttendanceTracker.Tracker
  alias AttendanceTracker.Tracker.Info

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} admin_mode={@admin_mode}>
      <.header>
        {gettext("Info screen")}
        <:subtitle>
          {gettext(
            "Slides shown full-screen on the kiosk after it has been idle. They rotate automatically; tapping the screen returns to check-in."
          )}
        </:subtitle>
        <:actions>
          <.button navigate={~p"/admin"}>
            <.icon name="hero-arrow-left" /> {gettext("Admin")}
          </.button>
          <.button id="new-info-btn" phx-click="new" variant="primary">
            <.icon name="hero-plus" /> {gettext("New slide")}
          </.button>
        </:actions>
      </.header>

      <p
        :if={@infos == [] and is_nil(@info)}
        id="no-infos"
        class="rounded-xl border border-dashed border-base-300 p-8 text-center text-sm opacity-70"
      >
        {gettext("No info slides yet. Add one to show it on the idle kiosk.")}
      </p>

      <div :if={@infos != []} id="infos-list" class="space-y-3">
        <div
          :for={info <- @infos}
          id={"info-#{info.id}"}
          class="flex flex-wrap items-center justify-between gap-3 rounded-xl border border-base-300 p-4"
        >
          <div class="min-w-0">
            <p class="font-semibold">
              {info.title || gettext("Untitled")}
              <span :if={!info.active} class="badge badge-ghost ml-2">{gettext("Hidden")}</span>
            </p>
            <p class="truncate text-sm opacity-60">{plain_text(info.body)}</p>
          </div>
          <div class="flex items-center gap-2">
            <button
              type="button"
              id={"edit-info-#{info.id}"}
              phx-click="edit"
              phx-value-id={info.id}
              class="btn btn-sm"
            >
              <.icon name="hero-pencil" class="size-4" /> {gettext("Edit")}
            </button>
            <button
              type="button"
              id={"delete-info-#{info.id}"}
              phx-click="delete"
              phx-value-id={info.id}
              data-confirm={gettext("Delete this slide?")}
              class="btn btn-sm btn-error"
            >
              <.icon name="hero-trash" class="size-4" />
            </button>
          </div>
        </div>
      </div>

      <div :if={@info} id="info-editor" class="mt-6 rounded-xl border border-base-300 p-6">
        <h2 class="mb-4 text-lg font-semibold">
          {if @info.id, do: gettext("Edit slide"), else: gettext("New slide")}
        </h2>

        <.form for={@form} id="info-form" phx-submit="save">
          <.input field={@form[:title]} type="text" label={gettext("Title (optional)")} />
          <.input
            field={@form[:position]}
            type="number"
            label={gettext("Position")}
            min="0"
            inputmode="numeric"
          />
          <.input field={@form[:active]} type="checkbox" label={gettext("Show in rotation")} />

          <div class="mt-4">
            <span class="label mb-1 block">{gettext("Content")}</span>
            <.wysiwyg
              id="info-body"
              name={@form[:body].name}
              value={@form[:body].value || ""}
            />
            <p :if={@form[:body].errors != []} class="mt-1 text-sm text-error">
              {Enum.map_join(@form[:body].errors, " ", &translate_error/1)}
            </p>
          </div>

          <footer class="mt-4">
            <.button variant="primary" phx-disable-with={gettext("Saving...")}>
              {gettext("Save slide")}
            </.button>
            <.button type="button" phx-click="cancel">{gettext("Cancel")}</.button>
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
     |> assign(:infos, Tracker.list_infos())
     |> assign(:info, nil)
     |> assign(:form, nil)}
  end

  @impl true
  def handle_event("new", _params, socket) do
    {:noreply, assign_form(socket, %Info{})}
  end

  def handle_event("edit", %{"id" => id}, socket) do
    {:noreply, assign_form(socket, Tracker.get_info!(id))}
  end

  def handle_event("cancel", _params, socket) do
    {:noreply, assign(socket, info: nil, form: nil)}
  end

  def handle_event("save", %{"info" => params}, socket) do
    case save_info(socket.assigns.info, params) do
      {:ok, _info} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Slide saved"))
         |> assign(:infos, Tracker.list_infos())
         |> assign(info: nil, form: nil)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, as: :info))}
    end
  end

  def handle_event("delete", %{"id" => id}, socket) do
    {:ok, _info} = Tracker.delete_info(Tracker.get_info!(id))

    {:noreply,
     socket
     |> put_flash(:info, gettext("Slide deleted"))
     |> assign(:infos, Tracker.list_infos())
     |> assign(info: nil, form: nil)}
  end

  defp save_info(%Info{id: nil}, params), do: Tracker.create_info(params)
  defp save_info(%Info{} = info, params), do: Tracker.update_info(info, params)

  defp assign_form(socket, %Info{} = info) do
    socket
    |> assign(:info, info)
    |> assign(:form, to_form(Tracker.change_info(info), as: :info))
  end

  defp plain_text(nil), do: ""

  defp plain_text(html) do
    html
    |> String.replace(~r/<[^>]*>/, " ")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end
end
