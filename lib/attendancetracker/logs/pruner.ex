defmodule AttendanceTracker.Logs.Pruner do
  @moduledoc """
  Periodically trims the audit and program logs to their configured maximum
  size (see `AttendanceTracker.Logs`). The interval is re-read from the settings
  on every run, so changing it in the admin area takes effect on the next cycle.
  """
  use GenServer

  alias AttendanceTracker.Logs

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, schedule()}
  end

  @impl true
  def handle_info(:prune, _state) do
    Logs.prune()
    {:noreply, schedule()}
  end

  defp schedule do
    Process.send_after(self(), :prune, Logs.prune_interval_seconds() * 1000)
  end
end
