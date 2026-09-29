defmodule AttendanceTrackerWeb.ParticipantLive.Form do
  use AttendanceTrackerWeb, :live_view

  alias AttendanceTracker.Tracker
  alias AttendanceTracker.Tracker.Participant

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} admin_mode={@admin_mode}>
      <.header>
        {@page_title}
        <:subtitle>Participants with a photo are easier to spot on the check-in screen.</:subtitle>
      </.header>

      <.form for={@form} id="participant-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:name]} type="text" label="Name" />
        <.input
          field={@form[:emergency_number]}
          type="text"
          label="Notfallnummer"
          inputmode="tel"
          autocomplete="off"
        />
        <.input field={@form[:active]} type="checkbox" label="Active" />

        <div>
          <span class="label mb-1 block">Photo</span>
          <div class="mt-2 flex flex-wrap items-center gap-4">
            <div
              :for={entry <- @uploads.photo.entries}
              class="relative size-24 shrink-0"
            >
              <.live_img_preview entry={entry} class="size-24 rounded-full object-cover" />
              <button
                type="button"
                phx-click="cancel-upload"
                phx-value-ref={entry.ref}
                class="absolute -top-1 -right-1 rounded-full bg-base-300 p-1"
                aria-label="Remove photo"
              >
                <.icon name="hero-x-mark" class="size-3" />
              </button>
              <p :for={err <- upload_errors(@uploads.photo, entry)} class="text-error text-xs">
                {upload_error_to_string(err)}
              </p>
            </div>
            <img
              :if={@uploads.photo.entries == [] && @participant.photo}
              src={@participant.photo}
              class="size-24 rounded-full object-cover"
            />
            <.live_file_input
              upload={@uploads.photo}
              class="file-input file-input-bordered w-full max-w-xs"
            />
          </div>
          <p :for={err <- upload_errors(@uploads.photo)} class="text-error mt-1 text-xs">
            {upload_error_to_string(err)}
          </p>
        </div>

        <footer>
          <.button phx-disable-with="Saving..." variant="primary">Save Participant</.button>
          <.button navigate={return_path(@return_to, @participant)}>Cancel</.button>
        </footer>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> allow_upload(:photo,
       accept: ~w(.jpg .jpeg .png .webp),
       max_entries: 1,
       max_file_size: 5_000_000
     )
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    participant = Tracker.get_participant!(id)

    socket
    |> assign(:page_title, "Edit Participant")
    |> assign(:participant, participant)
    |> assign(:form, to_form(Tracker.change_participant(participant)))
  end

  defp apply_action(socket, :new, _params) do
    participant = %Participant{}

    socket
    |> assign(:page_title, "New Participant")
    |> assign(:participant, participant)
    |> assign(:form, to_form(Tracker.change_participant(participant)))
  end

  @impl true
  def handle_event("validate", %{"participant" => participant_params}, socket) do
    changeset = Tracker.change_participant(socket.assigns.participant, participant_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :photo, ref)}
  end

  def handle_event("save", %{"participant" => participant_params}, socket) do
    save_participant(socket, socket.assigns.live_action, participant_params)
  end

  defp save_participant(socket, :edit, participant_params) do
    case Tracker.update_participant(
           socket.assigns.participant,
           put_photo_path(socket, participant_params)
         ) do
      {:ok, participant} ->
        {:noreply,
         socket
         |> put_flash(:info, "Participant updated successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, participant))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_participant(socket, :new, participant_params) do
    case Tracker.create_participant(put_photo_path(socket, participant_params)) do
      {:ok, participant} ->
        {:noreply,
         socket
         |> put_flash(:info, "Participant created successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, participant))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp put_photo_path(socket, params) do
    case consume_uploaded_entries(socket, :photo, &store_upload/2) do
      [path | _] -> Map.put(params, "photo", path)
      [] -> params
    end
  end

  defp store_upload(%{path: path}, entry) do
    filename = entry.uuid <> Path.extname(entry.client_name)
    dest = Path.join([:code.priv_dir(:attendancetracker), "static", "uploads", filename])
    File.cp!(path, dest)
    {:ok, "/uploads/" <> filename}
  end

  defp upload_error_to_string(:too_large), do: "Photo is too large (max 5 MB)"
  defp upload_error_to_string(:not_accepted), do: "Only JPG, PNG or WebP photos are allowed"
  defp upload_error_to_string(:too_many_files), do: "Only one photo allowed"
  defp upload_error_to_string(err), do: "Upload error: #{inspect(err)}"

  defp return_path("index", _participant), do: ~p"/participants"
  defp return_path("show", participant), do: ~p"/participants/#{participant}"
end
