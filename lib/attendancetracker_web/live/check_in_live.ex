defmodule AttendanceTrackerWeb.CheckInLive do
  use AttendanceTrackerWeb, :live_view

  import AttendanceTrackerWeb.ParticipantComponents

  alias AttendanceTracker.Tracker
  alias AttendanceTracker.Tracker.TrainingDay

  @impl true
  def mount(_params, lv_session, socket) do
    admin_unlocked = lv_session["admin_pin_ok"] == true
    training_days = Tracker.list_training_days()
    {session, selected_id} = resolve_session(training_days)
    participants = Tracker.list_participants_with_check_ins(session)

    if connected?(socket), do: Tracker.subscribe(session)

    {:ok,
     socket
     |> assign(:page_title, "Check in")
     |> assign(:session, session)
     |> assign(:training_days, training_days)
     |> assign(:training_day_options, training_day_options(training_days))
     |> assign(:training_day_form, to_form(%{"training_day_id" => selected_id}))
     |> assign(:admin_unlocked, admin_unlocked)
     |> assign(:toggle_participant, nil)
     |> assign(:pin_form, to_form(%{"pin" => ""}))
     |> assign(:camera_participant, nil)
     |> assign(:camera_error, nil)
     |> assign(:checked_in_count, Tracker.check_in_count(session))
     |> assign(:participant_count, length(participants))
     |> stream(:participants, participants)}
  end

  # Without configured training days, fall back to a single session per day.
  defp resolve_session([]), do: {Tracker.todays_session(), nil}

  defp resolve_session(training_days) do
    today = Tracker.local_today()
    now = Tracker.local_time_now()

    training_day = Tracker.current_training_day(training_days, today, now)
    date = TrainingDay.occurrence_on_or_before(training_day, today)

    {Tracker.session_for_training_day(training_day, date), training_day.id}
  end

  defp training_day_options(training_days) do
    today = Tracker.local_today()

    for training_day <- training_days do
      date = TrainingDay.occurrence_on_or_before(training_day, today)
      label = TrainingDay.label(training_day)
      {"#{label} · #{Calendar.strftime(date, "%b %-d")}", training_day.id}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} admin_mode={@admin_mode}>
      <.form
        :if={@training_days != []}
        for={@training_day_form}
        id="training-day-select"
        phx-change="select_training_day"
        class="max-w-md"
      >
        <.input
          field={@training_day_form[:training_day_id]}
          type="select"
          label="Training day"
          options={@training_day_options}
        />
      </.form>

      <div class="flex flex-wrap items-end justify-between gap-2">
        <div>
          <h1 class="text-2xl font-bold">Tap your photo to check in</h1>
          <p class="text-sm opacity-70">{Calendar.strftime(@session.date, "%A, %B %-d")}</p>
        </div>
        <div id="attendance-count" class="rounded-full bg-base-200 px-4 py-1 text-sm font-semibold">
          {@checked_in_count} / {@participant_count} present
        </div>
      </div>

      <div
        id="participants"
        phx-update="stream"
        class="grid grid-cols-2 gap-4 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5"
      >
        <div
          id="participants-empty"
          class="hidden only:block rounded-xl border border-dashed border-base-300 p-8 text-center"
        >
          No active participants yet.
          <.link navigate={~p"/participants/new"} class="link link-primary">Add one</.link>
        </div>

        <div :for={{id, participant} <- @streams.participants} id={id}>
          <.participant_card participant={participant} admin_mode={@admin_unlocked} />
        </div>
      </div>

      <div
        :if={@toggle_participant}
        id="check-out-modal"
        class="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4"
      >
        <div class="w-full max-w-sm rounded-2xl bg-base-100 p-6 shadow-xl">
          <h2 class="text-lg font-bold">Undo check-in for {@toggle_participant.name}?</h2>
          <p class="mt-1 text-sm opacity-70">Enter the admin PIN to remove this check-in.</p>

          <.form for={@pin_form} id="pin-form" phx-submit="submit_pin" class="mt-4">
            <.input
              field={@pin_form[:pin]}
              type="password"
              label="Admin PIN"
              inputmode="numeric"
              autocomplete="off"
            />
            <div class="mt-4 flex justify-end gap-2">
              <.button type="button" phx-click="cancel_check_out">Cancel</.button>
              <.button variant="primary" phx-disable-with="Checking...">Undo check-in</.button>
            </div>
          </.form>
        </div>
      </div>

      <div
        :if={@camera_participant}
        id="camera-modal"
        class="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4"
      >
        <div class="w-full max-w-md rounded-2xl bg-base-100 p-6 shadow-xl">
          <h2 class="text-lg font-bold">Take a photo of {@camera_participant.name}</h2>
          <p class="mt-1 text-sm opacity-70">
            Center the face in the preview, then capture. The photo is used on the check-in tile.
          </p>

          <div
            id="camera-capture"
            phx-hook=".CameraCapture"
            phx-update="ignore"
            class="mt-4"
          >
            <video
              autoplay
              playsinline
              muted
              class="aspect-video w-full -scale-x-100 rounded-xl bg-black object-cover"
            ></video>
            <button
              type="button"
              data-capture
              class="btn btn-primary mt-4 w-full cursor-pointer rounded-lg px-4 py-2"
            >
              <.icon name="hero-camera" class="size-5" /> Capture photo
            </button>
          </div>

          <p :if={@camera_error} id="camera-error" class="text-error mt-2 text-sm">
            {@camera_error}
          </p>

          <div class="mt-2 flex justify-end">
            <.button type="button" phx-click="close_camera">Cancel</.button>
          </div>
        </div>
      </div>

      <script :type={Phoenix.LiveView.ColocatedHook} name=".CameraCapture">
        export default {
          async mounted() {
            this.video = this.el.querySelector("video")

            try {
              this.stream = await navigator.mediaDevices.getUserMedia({
                video: { facingMode: { ideal: "user" } },
                audio: false
              })
              this.video.srcObject = this.stream
              await this.video.play()
            } catch (err) {
              this.pushEvent("camera_error", { message: err.message })
              return
            }

            this.el.querySelector("[data-capture]").addEventListener("click", () => {
              const maxSize = 640
              const scale = Math.min(
                1,
                maxSize / Math.max(this.video.videoWidth, this.video.videoHeight)
              )
              const canvas = document.createElement("canvas")
              canvas.width = Math.round(this.video.videoWidth * scale)
              canvas.height = Math.round(this.video.videoHeight * scale)
              canvas.getContext("2d").drawImage(this.video, 0, 0, canvas.width, canvas.height)
              this.pushEvent("captured_photo", { data: canvas.toDataURL("image/jpeg", 0.85) })
            })
          },

          destroyed() {
            if (this.stream) {
              this.stream.getTracks().forEach(track => track.stop())
            }
          }
        }
      </script>
    </Layouts.app>
    """
  end

  attr :participant, :map, required: true
  attr :admin_mode, :boolean, required: true

  defp participant_card(assigns) do
    ~H"""
    <% checked_in = List.first(@participant.check_ins) %>
    <div class="relative">
      <button
        id={"check-in-btn-#{@participant.id}"}
        phx-click={if(checked_in, do: "prompt_check_out", else: "check_in")}
        phx-value-id={@participant.id}
        title={if(checked_in, do: "Tap to undo the check-in")}
        class={[
          "group relative flex w-full cursor-pointer flex-col items-center gap-2 rounded-2xl border-2 p-4 transition-all duration-200",
          if(checked_in,
            do:
              "border-emerald-500 bg-emerald-50 hover:-translate-y-0.5 hover:border-amber-400 hover:shadow-lg active:scale-95 dark:bg-emerald-950/30",
            else:
              "border-base-300 bg-base-100 hover:-translate-y-0.5 hover:border-primary hover:shadow-lg active:scale-95"
          )
        ]}
      >
        <div class="relative">
          <.avatar participant={@participant} dim={is_nil(checked_in)} />

          <div
            :if={checked_in}
            id={"checked-in-badge-#{@participant.id}"}
            class="absolute -right-1 -bottom-1"
          >
            <div class="rounded-full bg-emerald-500 p-1 text-white group-hover:hidden">
              <.icon name="hero-check" class="size-4" />
            </div>
            <div class="hidden rounded-full bg-amber-500 p-1 text-white group-hover:block">
              <.icon name="hero-arrow-uturn-left" class="size-4" />
            </div>
          </div>
        </div>

        <span class="text-center text-sm leading-tight font-semibold">{@participant.name}</span>

        <span
          :if={@admin_mode && @participant.emergency_number}
          id={"emergency-number-#{@participant.id}"}
          class="flex items-center gap-1 text-xs opacity-60"
        >
          <.icon name="hero-phone" class="size-3" /> {@participant.emergency_number}
        </span>

        <span :if={checked_in} class="text-xs font-medium text-emerald-600 dark:text-emerald-400">
          {Calendar.strftime(checked_in.inserted_at, "%H:%M")}
        </span>
      </button>

      <button
        :if={@admin_mode}
        id={"camera-btn-#{@participant.id}"}
        phx-click="open_camera"
        phx-value-id={@participant.id}
        title="Take a photo"
        class="absolute top-2 right-2 cursor-pointer rounded-full bg-base-100/80 p-1.5 opacity-40 shadow-sm transition-opacity hover:opacity-100"
      >
        <.icon name="hero-camera" class="size-4" />
      </button>
    </div>
    """
  end

  @impl true
  def handle_event("select_training_day", %{"training_day_id" => id}, socket) do
    training_day = Tracker.get_training_day!(id)
    date = TrainingDay.occurrence_on_or_before(training_day, Tracker.local_today())
    session = Tracker.session_for_training_day(training_day, date)

    if connected?(socket) do
      Tracker.unsubscribe(socket.assigns.session)
      Tracker.subscribe(session)
    end

    participants = Tracker.list_participants_with_check_ins(session)

    {:noreply,
     socket
     |> assign(:session, session)
     |> assign(:training_day_form, to_form(%{"training_day_id" => training_day.id}))
     |> assign(:checked_in_count, Tracker.check_in_count(session))
     |> assign(:participant_count, length(participants))
     |> stream(:participants, participants, reset: true)}
  end

  def handle_event("check_in", %{"id" => id}, socket) do
    participant = Tracker.get_participant!(id)
    _ = Tracker.check_in(participant, socket.assigns.session)
    {:noreply, socket}
  end

  def handle_event("prompt_check_out", %{"id" => id}, socket) do
    if socket.assigns.admin_unlocked do
      check_out_participant(socket, id)
    else
      {:noreply,
       socket
       |> assign(:toggle_participant, Tracker.get_participant!(id))
       |> assign(:pin_form, to_form(%{"pin" => ""}))}
    end
  end

  def handle_event("submit_pin", %{"pin" => pin}, socket) do
    if Tracker.admin_pin_valid?(pin) do
      participant_id = socket.assigns.toggle_participant.id

      # Unlocking reveals the admin-only UI inside the streamed cards
      # (camera buttons, phone numbers), so the stream must be reset for
      # the toggled assign to take effect on already rendered items.
      participants = Tracker.list_participants_with_check_ins(socket.assigns.session)

      socket
      |> assign(:admin_unlocked, true)
      |> assign(:toggle_participant, nil)
      |> stream(:participants, participants, reset: true)
      |> check_out_participant(participant_id)
    else
      {:noreply, assign(socket, :pin_form, pin_form_with_error())}
    end
  end

  def handle_event("cancel_check_out", _params, socket) do
    {:noreply, assign(socket, :toggle_participant, nil)}
  end

  def handle_event("open_camera", %{"id" => id}, socket) do
    if socket.assigns.admin_unlocked do
      {:noreply,
       socket
       |> assign(:camera_participant, Tracker.get_participant!(id))
       |> assign(:camera_error, nil)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("close_camera", _params, socket) do
    {:noreply, assign(socket, :camera_participant, nil)}
  end

  def handle_event("camera_error", %{"message" => message}, socket) do
    {:noreply, assign(socket, :camera_error, "Could not access the camera: #{message}")}
  end

  def handle_event("captured_photo", %{"data" => data_url}, socket) do
    participant = socket.assigns.camera_participant

    case store_captured_photo(data_url) do
      {:ok, path} ->
        {:ok, _} = Tracker.update_participant(participant, %{photo: path})

        participant =
          Tracker.get_participant_with_check_ins(socket.assigns.session, participant.id)

        {:noreply,
         socket
         |> assign(:camera_participant, nil)
         |> stream_insert(:participants, participant)}

      {:error, _reason} ->
        {:noreply, assign(socket, :camera_error, "Could not save the photo, please try again.")}
    end
  end

  defp store_captured_photo("data:image/jpeg;base64," <> base64) do
    with {:ok, binary} <- Base.decode64(base64) do
      filename = Ecto.UUID.generate() <> ".jpg"
      dest = Path.join([:code.priv_dir(:attendancetracker), "static", "uploads", filename])
      File.mkdir_p!(Path.dirname(dest))

      case File.write(dest, binary) do
        :ok -> {:ok, "/uploads/" <> filename}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  defp store_captured_photo(_invalid_data), do: {:error, :invalid_data}

  defp check_out_participant(socket, id) do
    participant = Tracker.get_participant!(id)
    _ = Tracker.check_out(participant, socket.assigns.session)
    {:noreply, socket}
  end

  defp pin_form_with_error do
    to_form(%{"pin" => ""}, errors: [pin: {"Wrong PIN", []}])
  end

  @impl true
  def handle_info({:checked_in, check_in}, socket) do
    participant =
      Tracker.get_participant_with_check_ins(socket.assigns.session, check_in.participant_id)

    {:noreply,
     socket
     |> assign(:checked_in_count, socket.assigns.checked_in_count + 1)
     |> stream_insert(:participants, participant)}
  end

  def handle_info({:checked_out, check_in}, socket) do
    participant =
      Tracker.get_participant_with_check_ins(socket.assigns.session, check_in.participant_id)

    {:noreply,
     socket
     |> assign(:checked_in_count, max(socket.assigns.checked_in_count - 1, 0))
     |> stream_insert(:participants, participant)}
  end
end
