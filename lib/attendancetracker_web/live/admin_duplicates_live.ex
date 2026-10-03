defmodule AttendanceTrackerWeb.AdminDuplicatesLive do
  use AttendanceTrackerWeb, :live_view

  alias AttendanceTracker.Duplicates
  alias AttendanceTracker.Tracker
  alias AttendanceTracker.Tracker.Participant

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} admin_mode={@admin_mode}>
      <.header>
        {gettext("Merge duplicates")}
        <:subtitle>
          {gettext(
            "Participants that only have a first or last name and likely match a participant with a full name."
          )}
        </:subtitle>
        <:actions>
          <.button navigate={~p"/admin"}>
            <.icon name="hero-arrow-left" /> {gettext("Admin")}
          </.button>
        </:actions>
      </.header>

      <p
        :if={@candidates == []}
        id="no-duplicates"
        class="rounded-xl border border-base-300 p-6 text-center text-sm opacity-70"
      >
        {gettext("No likely duplicates found.")}
      </p>

      <div :if={@candidates != []} class="space-y-3">
        <div
          :for={candidate <- @candidates}
          id={"duplicate-#{candidate.duplicate.id}-#{candidate.survivor.id}"}
          class="flex flex-wrap items-center justify-between gap-4 rounded-xl border border-base-300 p-4"
        >
          <div class="text-sm">
            <span class="font-semibold">{Participant.full_name(candidate.survivor)}</span>
            <span class="opacity-60">↔</span>
            <span class="font-semibold">{Participant.full_name(candidate.duplicate)}</span>
          </div>
          <button
            type="button"
            id={"merge-btn-#{candidate.duplicate.id}-#{candidate.survivor.id}"}
            phx-click="select"
            phx-value-survivor={candidate.survivor.id}
            phx-value-duplicate={candidate.duplicate.id}
            class="btn btn-primary btn-sm"
          >
            {gettext("Merge")}
          </button>
        </div>
      </div>

      <div :if={@merge} id="merge-mask" class="rounded-xl border border-base-300 p-4">
        <h2 class="text-lg font-semibold">{gettext("Merge into one participant")}</h2>
        <p class="mt-1 text-sm opacity-70">
          {gettext("Merging %{duplicate} into %{survivor}. Past attendances are moved over.",
            duplicate: Participant.full_name(@merge.duplicate),
            survivor: Participant.full_name(@merge.survivor)
          )}
        </p>

        <.form for={@merge_form} id="merge-form" phx-submit="merge">
          <.input field={@merge_form[:first_name]} type="text" label={gettext("First name")} />
          <.input field={@merge_form[:last_name]} type="text" label={gettext("Last name")} />
          <.input
            field={@merge_form[:emergency_number]}
            type="text"
            label={gettext("Notfallnummer")}
            inputmode="tel"
            autocomplete="off"
          />
          <.input field={@merge_form[:active]} type="checkbox" label={gettext("Active")} />
          <footer>
            <button type="button" id="cancel-merge" phx-click="cancel_merge" class="btn btn-soft">
              {gettext("Cancel")}
            </button>
            <button
              type="submit"
              id="confirm-merge"
              class="btn btn-primary"
              phx-disable-with={gettext("Merging...")}
            >
              {gettext("Merge participants")}
            </button>
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
     |> assign(:page_title, gettext("Merge duplicates"))
     |> assign(:merge, nil)
     |> reload()}
  end

  @impl true
  def handle_event("select", %{"survivor" => survivor_id, "duplicate" => duplicate_id}, socket) do
    survivor = Tracker.get_participant!(survivor_id)
    duplicate = Tracker.get_participant!(duplicate_id)

    params = %{
      "first_name" => survivor.first_name || duplicate.first_name,
      "last_name" => survivor.last_name || duplicate.last_name,
      "emergency_number" => survivor.emergency_number || duplicate.emergency_number
    }

    changeset = Tracker.change_participant(survivor, params)

    {:noreply,
     socket
     |> assign(:merge, %{survivor: survivor, duplicate: duplicate})
     |> assign(:merge_form, to_form(changeset, as: :merge))}
  end

  def handle_event("cancel_merge", _params, socket) do
    {:noreply, assign(socket, :merge, nil)}
  end

  def handle_event("merge", %{"merge" => params}, socket) do
    %{survivor: survivor, duplicate: duplicate} = socket.assigns.merge

    case Duplicates.merge(survivor, duplicate, params) do
      {:ok, _survivor} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Participants merged"))
         |> assign(:merge, nil)
         |> reload()}

      {:error, changeset} ->
        {:noreply, assign(socket, :merge_form, to_form(changeset, as: :merge))}
    end
  end

  defp reload(socket), do: assign(socket, :candidates, Duplicates.list_candidates())
end
