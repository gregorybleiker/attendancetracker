defmodule AttendanceTrackerWeb.ParticipantLive.Form do
  use AttendanceTrackerWeb, :live_view

  import AttendanceTrackerWeb.ParticipantComponents

  require Logger

  alias AttendanceTracker.Tracker
  alias AttendanceTracker.Tracker.Participant

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} admin_mode={@admin_mode}>
      <.header>
        {@page_title}
        <:subtitle>
          {gettext("Participants with a photo are easier to spot on the check-in screen.")}
        </:subtitle>
      </.header>

      <.form for={@form} id="participant-form" phx-change="validate" phx-submit="save">
        <.input field={@form[:name]} type="text" label={gettext("Name")} />
        <.input
          field={@form[:emergency_number]}
          type="text"
          label={gettext("Notfallnummer")}
          inputmode="tel"
          autocomplete="off"
        />
        <.input field={@form[:active]} type="checkbox" label={gettext("Active")} />

        <div>
          <span class="label mb-1 block">{gettext("Photo")}</span>
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
                aria-label={gettext("Remove photo")}
              >
                <.icon name="hero-x-mark" class="size-3" />
              </button>
              <p :for={err <- upload_errors(@uploads.photo, entry)} class="text-error text-xs">
                {upload_error_to_string(err)}
              </p>
            </div>
            <img
              :if={@uploads.photo.entries == [] && photo_url(@participant)}
              src={photo_url(@participant)}
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
          <.button phx-disable-with={gettext("Saving...")} variant="primary">
            {gettext("Save Participant")}
          </.button>
          <.button navigate={return_path(@return_to, @participant)}>{gettext("Cancel")}</.button>
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
    |> assign(:page_title, gettext("Edit Participant"))
    |> assign(:participant, participant)
    |> assign(:form, to_form(Tracker.change_participant(participant)))
  end

  defp apply_action(socket, :new, _params) do
    participant = %Participant{}

    socket
    |> assign(:page_title, gettext("New Participant"))
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
    case Tracker.update_participant(socket.assigns.participant, participant_params) do
      {:ok, participant} ->
        store_photo(participant, consume_photo(socket))

        {:noreply,
         socket
         |> put_flash(:info, gettext("Participant updated successfully"))
         |> push_navigate(to: return_path(socket.assigns.return_to, participant))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_participant(socket, :new, participant_params) do
    case Tracker.create_participant(participant_params) do
      {:ok, participant} ->
        store_photo(participant, consume_photo(socket))

        {:noreply,
         socket
         |> put_flash(:info, gettext("Participant created successfully"))
         |> push_navigate(to: return_path(socket.assigns.return_to, participant))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  # Reads the pending upload (if any) into memory. Returns `nil` when no new
  # photo was picked.
  defp consume_photo(socket) do
    case consume_uploaded_entries(socket, :photo, &read_upload/2) do
      [{data, content_type} | _] -> {data, content_type}
      _ -> nil
    end
  end

  defp read_upload(%{path: path}, entry) do
    case File.read(path) do
      {:ok, data} ->
        {:ok, {data, content_type(entry.client_name)}}

      {:error, reason} ->
        Logger.warning("Could not read uploaded photo: #{inspect(reason)}")
        {:postpone, :error}
    end
  end

  defp content_type(client_name) do
    case client_name |> Path.extname() |> String.downcase() do
      ".png" -> "image/png"
      ".webp" -> "image/webp"
      _ -> "image/jpeg"
    end
  end

  defp store_photo(_participant, nil), do: :ok

  defp store_photo(participant, {data, content_type}) do
    case Tracker.put_participant_photo(participant, data, content_type) do
      {:ok, _photo} ->
        :ok

      {:error, reason} ->
        Logger.warning(
          "Could not store photo for participant #{participant.id}: #{inspect(reason)}"
        )
    end
  end

  defp upload_error_to_string(:too_large), do: gettext("Photo is too large (max 5 MB)")

  defp upload_error_to_string(:not_accepted),
    do: gettext("Only JPG, PNG or WebP photos are allowed")

  defp upload_error_to_string(:too_many_files), do: gettext("Only one photo allowed")

  defp upload_error_to_string(err),
    do: gettext("Upload error: %{error}", error: inspect(err))

  defp return_path("index", _participant), do: ~p"/participants"
  defp return_path("show", participant), do: ~p"/participants/#{participant}"
end
