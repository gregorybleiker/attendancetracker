defmodule AttendanceTrackerWeb.AdminLogsLive do
  use AttendanceTrackerWeb, :live_view

  alias AttendanceTracker.Logs

  @limit 500

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} admin_mode={@admin_mode}>
      <.header>
        {gettext("Logs")}
        <:subtitle>
          {gettext("Audit log: check-ins and reverts. Program log: sync calls and their results.")}
        </:subtitle>
        <:actions>
          <.button navigate={~p"/admin"}>
            <.icon name="hero-arrow-left" /> {gettext("Admin")}
          </.button>
          <.button type="button" phx-click="refresh">
            <.icon name="hero-arrow-path" /> {gettext("Refresh")}
          </.button>
        </:actions>
      </.header>

      <div class="flex flex-wrap gap-2">
        <button
          type="button"
          id="show-audit-log"
          phx-click="select_log"
          phx-value-type="audit"
          class={[
            "btn",
            @log_type == "audit" && "btn-primary",
            @log_type != "audit" && "btn-soft"
          ]}
        >
          {gettext("Audit log")}
        </button>
        <button
          type="button"
          id="show-program-log"
          phx-click="select_log"
          phx-value-type="program"
          class={[
            "btn",
            @log_type == "program" && "btn-primary",
            @log_type != "program" && "btn-soft"
          ]}
        >
          {gettext("Program log")}
        </button>
      </div>

      <div
        id="log-view"
        class="max-h-[70vh] overflow-y-auto overscroll-contain rounded-xl border border-base-300"
      >
        <table :if={@log_type == "audit"} id="audit-log-table" class="table table-zebra table-sm">
          <thead class="sticky top-0 bg-base-100">
            <tr>
              <th>{gettext("Time")}</th>
              <th>{gettext("Action")}</th>
              <th>{gettext("Participant")}</th>
              <th>{gettext("Session")}</th>
            </tr>
          </thead>
          <tbody>
            <tr :for={log <- @audit_logs} id={"audit-log-#{log.id}"}>
              <td class="whitespace-nowrap">{format_time(log.inserted_at)}</td>
              <td>{action_label(log.action)}</td>
              <td>{log.participant_name}</td>
              <td>{log.training_session_id}</td>
            </tr>
          </tbody>
        </table>

        <table :if={@log_type == "program"} id="program-log-table" class="table table-zebra table-sm">
          <thead class="sticky top-0 bg-base-100">
            <tr>
              <th>{gettext("Time")}</th>
              <th>{gettext("Command")}</th>
              <th>{gettext("Status")}</th>
              <th>{gettext("Request")}</th>
              <th>{gettext("Result")}</th>
            </tr>
          </thead>
          <tbody>
            <tr :for={log <- @program_logs} id={"program-log-#{log.id}"}>
              <td class="whitespace-nowrap">{format_time(log.inserted_at)}</td>
              <td>{log.command}</td>
              <td>{log.status}</td>
              <td class="max-w-xs whitespace-normal">{log.request}</td>
              <td class="max-w-xs whitespace-normal">{log.result}</td>
            </tr>
          </tbody>
        </table>

        <p
          :if={empty?(@log_type, @audit_logs, @program_logs)}
          class="p-6 text-center text-sm opacity-70"
        >
          {gettext("No log entries yet.")}
        </p>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, gettext("Logs"))
     |> assign(:log_type, "audit")
     |> reload()}
  end

  @impl true
  def handle_event("select_log", %{"type" => type}, socket) when type in ["audit", "program"] do
    {:noreply, assign(socket, :log_type, type)}
  end

  def handle_event("refresh", _params, socket), do: {:noreply, reload(socket)}

  defp reload(socket) do
    socket
    |> assign(:audit_logs, Logs.list_audit_logs(@limit))
    |> assign(:program_logs, Logs.list_program_logs(@limit))
  end

  defp empty?("audit", audit_logs, _program_logs), do: audit_logs == []
  defp empty?("program", _audit_logs, program_logs), do: program_logs == []

  defp action_label("check_in"), do: gettext("check_in")
  defp action_label("check_out"), do: gettext("check_out")
  defp action_label(other), do: other

  defp format_time(datetime), do: Calendar.strftime(datetime, "%Y-%m-%d %H:%M:%S")
end
