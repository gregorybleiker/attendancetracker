defmodule AttendanceTrackerWeb.CheckInLive do
  use AttendanceTrackerWeb, :live_view

  import AttendanceTrackerWeb.InfoComponents
  import AttendanceTrackerWeb.ParticipantComponents

  alias AttendanceTracker.AdminSession
  alias AttendanceTracker.PinThrottle
  alias AttendanceTracker.Tracker
  alias AttendanceTracker.Tracker.Participant
  alias AttendanceTracker.Tracker.Training
  alias AttendanceTrackerWeb.ClientIP
  alias AttendanceTrackerWeb.TrainingLabels

  @impl true
  def mount(_params, lv_session, socket) do
    admin_unlocked =
      AdminSession.active?(lv_session["admin_token"], Tracker.admin_timeout_seconds())

    trainings = Tracker.list_trainings()
    {training, date} = resolve_selection(trainings)
    session = session_for(training, date)
    participants = Tracker.list_participants_with_check_ins(session)

    if connected?(socket), do: Tracker.subscribe(session)

    {:ok,
     socket
     |> assign(:client_ip, ClientIP.from_socket(socket))
     |> assign(:page_title, gettext("Check in"))
     |> assign(:session, session)
     |> assign(:trainings, trainings)
     |> assign(:training_options, training_options(trainings, date))
     |> assign(:selected_training_id, training && training.id)
     |> assign(:selected_date, date)
     |> assign(:session_form, session_form(training && training.id, date))
     |> assign(:admin_unlocked, admin_unlocked)
     |> assign(:show_all, false)
     |> assign(:toggle_participant, nil)
     |> assign(:pin_form, to_form(%{"pin" => ""}))
     |> assign(:camera_participant, nil)
     |> assign(:camera_error, nil)
     |> assign(:checked_in_count, Tracker.check_in_count(session))
     |> assign(:participant_count, length(participants))
     |> assign(:infos, Tracker.list_active_infos())
     |> assign(:idle_timeout_ms, Tracker.idle_timeout_ms())
     |> assign(:rotation_ms, Tracker.info_rotation_ms())
     |> stream(:participants, participants)}
  end

  # Without configured trainings, fall back to a single session per day.
  defp resolve_selection([]), do: {nil, Tracker.local_today()}

  defp resolve_selection(trainings) do
    today = Tracker.local_today()
    now = Tracker.local_time_now()

    training = Tracker.current_training(trainings, today, now)
    {training, Training.occurrence_on_or_before(training, today)}
  end

  defp session_for(nil, date), do: Tracker.session_for_date(date)

  defp session_for(%Training{} = training, date),
    do: Tracker.session_for_training(training, date)

  defp session_form(training_id, date) do
    to_form(%{
      "date" => Date.to_iso8601(date),
      "training_id" => training_id
    })
  end

  # The dropdown lists only the trainings that run on the selected date's
  # weekday, so a date always maps to a training that actually occurs on it.
  defp training_options(trainings, date) do
    weekday = Date.day_of_week(date)

    for training <- trainings, training.weekday == weekday do
      {training_label(training), training.id}
    end
  end

  # Keeps the selected training only when it runs on `date`'s weekday,
  # otherwise falls back to the first training scheduled that day.
  defp selected_training(training_id, date, trainings) do
    weekday = Date.day_of_week(date)

    case training_id do
      id when id in [nil, ""] ->
        first_training_on(trainings, weekday)

      id ->
        training = Tracker.get_training!(id)

        if training.weekday == weekday do
          training
        else
          first_training_on(trainings, weekday)
        end
    end
  end

  defp first_training_on(trainings, weekday) do
    Enum.find(trainings, &(&1.weekday == weekday))
  end

  # Like `Training.label/1`, but with the weekday translated in the web layer.
  defp training_label(training) do
    name =
      case training.name do
        nil -> TrainingLabels.weekday_label(training.weekday)
        "" -> TrainingLabels.weekday_label(training.weekday)
        training_alias -> training_alias
      end

    start_time = Calendar.strftime(training.starts_at, "%H:%M")
    end_time = Calendar.strftime(training.ends_at, "%H:%M")
    "#{name} · #{start_time}–#{end_time}"
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} admin_mode={@admin_mode}>
      <:header>
        <.form
          for={@session_form}
          id="session-select"
          phx-change="select_session"
          class="flex flex-wrap items-center gap-2 [&>div]:mb-0"
        >
          <.input
            field={@session_form[:date]}
            type="date"
            id="session-date"
            class="input input-sm w-auto"
          />
          <.input
            :if={@training_options != []}
            field={@session_form[:training_id]}
            type="select"
            id="session-training"
            options={@training_options}
            class="select select-sm w-auto"
          />
        </.form>

        <button
          :if={@session.training_id}
          id="show-all-toggle"
          type="button"
          phx-click="toggle_show_all"
          class={[
            "flex cursor-pointer items-center gap-1.5 rounded-full border px-3 py-1 text-sm font-semibold transition-colors",
            if(@show_all,
              do: "border-primary bg-primary text-primary-content",
              else: "border-base-300 bg-base-100 hover:border-primary"
            )
          ]}
        >
          <.icon name={if @show_all, do: "hero-user-group", else: "hero-users"} class="size-4" />
          {if @show_all, do: gettext("Show only members"), else: gettext("Show all")}
        </button>

        <div
          id="attendance-count"
          class="rounded-full bg-base-200 px-3 py-1 text-sm font-semibold"
        >
          {gettext("%{checked} / %{total} present",
            checked: @checked_in_count,
            total: @participant_count
          )}
        </div>
      </:header>

      <:menu>
        <Layouts.drawer_button
          :if={@infos != []}
          id="show-info-mode-btn"
          click={JS.dispatch("info-mode:show", to: "#info-mode")}
          icon="hero-presentation-chart-bar"
        >
          {gettext("Show info")}
        </Layouts.drawer_button>
      </:menu>

      <div
        id="participants"
        phx-update="stream"
        class="grid grid-cols-2 gap-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6"
      >
        <div
          id="participants-empty"
          class="hidden only:block rounded-xl border border-dashed border-base-300 p-8 text-center"
        >
          <%= if @show_all or is_nil(@session.training_id) do %>
            {gettext("No active participants yet.")}
            <.link navigate={~p"/participants/new"} class="link link-primary">{gettext("Add one")}</.link>
          <% else %>
            {gettext("No members in this training yet.")}
            <button
              type="button"
              phx-click="toggle_show_all"
              class="link link-primary cursor-pointer"
            >
              {gettext("Show all")}
            </button>
          <% end %>
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
          <h2 class="text-lg font-bold">
            {gettext("Undo check-in for %{name}?", name: Participant.full_name(@toggle_participant))}
          </h2>
          <p class="mt-1 text-sm opacity-70">
            {gettext("Enter the admin PIN to remove this check-in.")}
          </p>

          <.form for={@pin_form} id="pin-form" phx-submit="submit_pin" class="mt-4">
            <.input
              field={@pin_form[:pin]}
              type="password"
              label={gettext("Admin PIN")}
              inputmode="numeric"
              autocomplete="off"
            />
            <div class="mt-4 flex justify-end gap-2">
              <.button type="button" phx-click="cancel_check_out">{gettext("Cancel")}</.button>
              <.button variant="primary" phx-disable-with={gettext("Checking...")}>
                {gettext("Undo check-in")}
              </.button>
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
          <h2 class="text-lg font-bold">
            {gettext("Take a photo of %{name}", name: Participant.full_name(@camera_participant))}
          </h2>
          <p class="mt-1 text-sm opacity-70">
            {gettext(
              "Center the face in the preview, then capture. The photo is used on the check-in tile."
            )}
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
              <.icon name="hero-camera" class="size-5" /> {gettext("Capture photo")}
            </button>
          </div>

          <p :if={@camera_error} id="camera-error" class="text-error mt-2 text-sm">
            {@camera_error}
          </p>

          <div class="mt-2 flex justify-end">
            <.button type="button" phx-click="close_camera">{gettext("Cancel")}</.button>
          </div>
        </div>
      </div>

      <.info_mode
        infos={@infos}
        idle_timeout_ms={@idle_timeout_ms}
        rotation_ms={@rotation_ms}
      />

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
        title={if(checked_in, do: gettext("Tap to undo the check-in"))}
        class={[
          "group relative flex w-full cursor-pointer flex-col items-center gap-1 rounded-2xl border-2 p-2 transition-all duration-200",
          if(checked_in,
            do:
              "border-emerald-500 bg-emerald-50 hover:-translate-y-0.5 hover:border-amber-400 hover:shadow-lg active:scale-95 dark:bg-emerald-950/30",
            else:
              "border-base-300 bg-base-100 hover:-translate-y-0.5 hover:border-primary hover:shadow-lg active:scale-95"
          )
        ]}
      >
        <div class="relative">
          <.avatar
            participant={@participant}
            class="size-12 sm:size-16"
            text_class="text-xl"
            dim={is_nil(checked_in)}
          />

          <div :if={@admin_mode} class="absolute -top-1 -left-1">
            <.source_badge participant={@participant} />
          </div>

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

        <span class="text-center text-xs leading-tight font-semibold">{Participant.full_name(
          @participant
        )}</span>

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
        title={gettext("Take a photo")}
        class="absolute top-2 right-2 cursor-pointer rounded-full bg-base-100/80 p-1.5 opacity-40 shadow-sm transition-opacity hover:opacity-100"
      >
        <.icon name="hero-camera" class="size-4" />
      </button>
    </div>
    """
  end

  @impl true
  def handle_event("select_session", params, socket) do
    date = parse_date(params["date"]) || socket.assigns.selected_date
    training = selected_training(params["training_id"], date, socket.assigns.trainings)
    session = session_for(training, date)

    if connected?(socket) do
      Tracker.unsubscribe(socket.assigns.session)
      Tracker.subscribe(session)
    end

    participants =
      Tracker.list_participants_with_check_ins(session, show_all: socket.assigns.show_all)

    {:noreply,
     socket
     |> assign(:session, session)
     |> assign(:selected_date, date)
     |> assign(:training_options, training_options(socket.assigns.trainings, date))
     |> assign(:selected_training_id, training && training.id)
     |> assign(:session_form, session_form(training && training.id, date))
     |> assign(:checked_in_count, Tracker.check_in_count(session))
     |> assign(:participant_count, length(participants))
     |> stream(:participants, participants, reset: true)}
  end

  def handle_event("info_mode_dismissed", _params, socket) do
    # Already on the check-in screen; nothing to navigate to.
    {:noreply, socket}
  end

  def handle_event("toggle_show_all", _params, socket) do
    show_all = not socket.assigns.show_all

    participants =
      Tracker.list_participants_with_check_ins(socket.assigns.session, show_all: show_all)

    {:noreply,
     socket
     |> assign(:show_all, show_all)
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
    ip = socket.assigns.client_ip

    case PinThrottle.check_admin(ip) do
      :ok ->
        if Tracker.admin_pin_valid?(pin) do
          PinThrottle.clear_admin(ip)
          unlock_and_check_out(socket)
        else
          PinThrottle.record_admin_failure(ip)
          {:noreply, assign(socket, :pin_form, pin_form_with_error())}
        end

      {:error, retry_after} ->
        {:noreply, assign(socket, :pin_form, pin_form_with_throttle_error(retry_after))}
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
    {:noreply,
     assign(
       socket,
       :camera_error,
       gettext("Could not access the camera: %{message}", message: message)
     )}
  end

  def handle_event("captured_photo", %{"data" => data_url}, socket) do
    participant = socket.assigns.camera_participant

    case decode_jpeg(data_url) do
      {:ok, binary} ->
        {:ok, _photo} = Tracker.put_participant_photo(participant, binary, "image/jpeg")

        participant =
          Tracker.get_participant_with_check_ins(socket.assigns.session, participant.id)

        {:noreply,
         socket
         |> assign(:camera_participant, nil)
         |> stream_insert(:participants, participant)}

      {:error, _reason} ->
        {:noreply,
         assign(socket, :camera_error, gettext("Could not save the photo, please try again."))}
    end
  end

  defp decode_jpeg("data:image/jpeg;base64," <> base64) do
    case Base.decode64(base64) do
      {:ok, binary} -> {:ok, binary}
      :error -> {:error, :invalid_data}
    end
  end

  defp decode_jpeg(_invalid_data), do: {:error, :invalid_data}

  defp check_out_participant(socket, id) do
    participant = Tracker.get_participant!(id)
    _ = Tracker.check_out(participant, socket.assigns.session)
    {:noreply, socket}
  end

  defp unlock_and_check_out(socket) do
    participant_id = socket.assigns.toggle_participant.id

    # Unlocking reveals the admin-only UI inside the streamed cards
    # (camera buttons, phone numbers), so the stream must be reset for
    # the toggled assign to take effect on already rendered items.
    participants =
      Tracker.list_participants_with_check_ins(socket.assigns.session,
        show_all: socket.assigns.show_all
      )

    socket
    |> assign(:admin_unlocked, true)
    |> assign(:toggle_participant, nil)
    |> stream(:participants, participants, reset: true)
    |> check_out_participant(participant_id)
  end

  defp pin_form_with_error do
    to_form(%{"pin" => ""}, errors: [pin: {gettext("Wrong PIN"), []}])
  end

  defp pin_form_with_throttle_error(retry_after) do
    to_form(%{"pin" => ""},
      errors: [
        pin:
          {gettext("Too many attempts. Try again in %{seconds} seconds.", seconds: retry_after),
           []}
      ]
    )
  end

  defp parse_date(value) when is_binary(value) do
    case Date.from_iso8601(value) do
      {:ok, date} -> date
      _ -> nil
    end
  end

  defp parse_date(_value), do: nil

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
