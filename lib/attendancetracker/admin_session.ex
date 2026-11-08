defmodule AttendanceTracker.AdminSession do
  @moduledoc """
  In-memory registry of active admin sessions.

  A successful admin login is issued a random token that is stored in the
  signed session cookie. This registry tracks the last activity time per token
  so an admin session can expire after a configurable period of inactivity (see
  `AttendanceTracker.Tracker.admin_timeout_minutes/0`), defaulting to 10
  minutes.

  Activity is recorded by the HTTP `RequireAdminPin` plug on every request and
  by `AttendanceTrackerWeb.AdminSessionHook` on LiveView mounts, events, and
  live navigation, so idle tabs are logged out shortly after the timeout.

  Because the state lives in memory, restarting the application logs every
  admin out.
  """

  use GenServer

  @name __MODULE__
  @prune_interval_ms 60_000
  # Longer than the maximum configurable timeout (1440 minutes), so pruning can
  # never drop a session that could still be active.
  @max_idle_ms 25 * 60 * 60 * 1000

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: Keyword.get(opts, :name, @name))
  end

  @doc """
  Issues a new admin session token and records it as active.
  """
  def start, do: GenServer.call(@name, :start)

  @doc """
  Refreshes `token` if it is still active for `timeout_seconds`, returning
  whether it was. Expired tokens are dropped.
  """
  def refresh(token, timeout_seconds),
    do: GenServer.call(@name, {:refresh, token, timeout_seconds})

  @doc """
  Returns whether `token` is active for `timeout_seconds` without refreshing it.
  """
  def active?(token, timeout_seconds),
    do: GenServer.call(@name, {:active?, token, timeout_seconds})

  @doc """
  Returns `{:ok, remaining_ms}`, `:expired`, or `:unknown` for `token`.
  """
  def expires_in(token, timeout_seconds),
    do: GenServer.call(@name, {:expires_in, token, timeout_seconds})

  @doc """
  Drops `token` from the registry.
  """
  def forget(token), do: GenServer.call(@name, {:forget, token})

  @doc false
  def backdate(token, age_ms), do: GenServer.call(@name, {:backdate, token, age_ms})

  @impl true
  def init(:ok), do: {:ok, schedule_prune(%{})}

  @impl true
  def handle_call(:start, _from, sessions) do
    token = new_token()
    {:reply, token, Map.put(sessions, token, now())}
  end

  def handle_call({:refresh, token, timeout_seconds}, _from, sessions) do
    case fetch_active(sessions, token, timeout_seconds) do
      {:ok, _last_seen} -> {:reply, true, Map.put(sessions, token, now())}
      :expired -> {:reply, false, Map.delete(sessions, token)}
      :unknown -> {:reply, false, sessions}
    end
  end

  def handle_call({:active?, token, timeout_seconds}, _from, sessions) do
    case fetch_active(sessions, token, timeout_seconds) do
      {:ok, _last_seen} -> {:reply, true, sessions}
      :expired -> {:reply, false, Map.delete(sessions, token)}
      :unknown -> {:reply, false, sessions}
    end
  end

  def handle_call({:expires_in, token, timeout_seconds}, _from, sessions) do
    case fetch_active(sessions, token, timeout_seconds) do
      {:ok, last_seen} ->
        remaining = timeout_seconds * 1000 - (now() - last_seen)
        {:reply, {:ok, max(remaining, 0)}, sessions}

      :expired ->
        {:reply, :expired, Map.delete(sessions, token)}

      :unknown ->
        {:reply, :unknown, sessions}
    end
  end

  def handle_call({:forget, token}, _from, sessions) do
    {:reply, :ok, Map.delete(sessions, token)}
  end

  def handle_call({:backdate, token, age_ms}, _from, sessions) do
    sessions =
      case Map.fetch(sessions, token) do
        {:ok, _last_seen} -> Map.put(sessions, token, now() - age_ms)
        :error -> sessions
      end

    {:reply, :ok, sessions}
  end

  @impl true
  def handle_info(:prune, sessions) do
    cutoff = now() - @max_idle_ms
    sessions = sessions |> Map.reject(fn {_token, last_seen} -> last_seen < cutoff end)
    {:noreply, schedule_prune(sessions)}
  end

  defp fetch_active(sessions, token, timeout_seconds) when is_binary(token) do
    case Map.fetch(sessions, token) do
      {:ok, last_seen} ->
        if now() - last_seen < timeout_seconds * 1000, do: {:ok, last_seen}, else: :expired

      :error ->
        :unknown
    end
  end

  defp fetch_active(_sessions, _token, _timeout_seconds), do: :unknown

  defp new_token, do: :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)

  defp now, do: System.monotonic_time(:millisecond)

  defp schedule_prune(sessions) do
    Process.send_after(self(), :prune, @prune_interval_ms)
    sessions
  end
end
