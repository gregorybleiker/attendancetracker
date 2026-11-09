defmodule AttendanceTracker.RateLimit do
  @moduledoc """
  In-memory sliding-window counter backing the PIN brute-force throttle.

  Each key stores the timestamps (monotonic milliseconds) of its recent
  failures, capped at the limit passed to `record/3`. `check/3` prunes
  failures older than the window and reports whether the key has reached the
  limit; `record/3` appends a failure. The window is stored per key so the
  periodic prune can drop keys that have gone quiet.

  State lives in memory on this node only, so restarting the application
  resets every counter. That is acceptable for throttling: the purpose is to
  slow an attacker down, not to persist lockouts.
  """

  use GenServer

  @name __MODULE__
  @prune_interval_ms 60_000

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: Keyword.get(opts, :name, @name))
  end

  @doc """
  Returns `:ok` when `key` has fewer than `limit` failures within the last
  `window_ms`, otherwise `{:error, retry_after_seconds}`.
  """
  def check(key, limit, window_ms), do: GenServer.call(@name, {:check, key, limit, window_ms})

  @doc """
  Records a failure for `key`, retaining only the `limit` most recent ones.
  """
  def record(key, limit, window_ms), do: GenServer.call(@name, {:record, key, limit, window_ms})

  @doc """
  Forgets all recorded failures for `key` (call after a successful attempt).
  """
  def clear(key), do: GenServer.call(@name, {:clear, key})

  @doc """
  Forgets all recorded failures for every key. Used by tests to isolate runs.
  """
  def clear_all, do: GenServer.call(@name, :clear_all)

  @impl true
  def init(:ok), do: {:ok, schedule_prune(%{})}

  @impl true
  def handle_call({:check, key, limit, window_ms}, _from, state) do
    failures = prune(fetch(state, key), window_ms)

    reply =
      if length(failures) >= limit do
        {:error, retry_after(failures, window_ms)}
      else
        :ok
      end

    {:reply, reply, stash(state, key, failures, window_ms)}
  end

  def handle_call({:record, key, limit, window_ms}, _from, state) do
    failures = [now() | prune(fetch(state, key), window_ms)] |> Enum.take(limit)
    {:reply, :ok, stash(state, key, failures, window_ms)}
  end

  def handle_call({:clear, key}, _from, state), do: {:reply, :ok, Map.delete(state, key)}
  def handle_call(:clear_all, _from, _state), do: {:reply, :ok, %{}}

  @impl true
  def handle_info(:prune, state) do
    state =
      Enum.reduce(state, %{}, fn {key, {failures, window_ms}}, acc ->
        case prune(failures, window_ms) do
          [] -> acc
          remaining -> Map.put(acc, key, {remaining, window_ms})
        end
      end)

    {:noreply, schedule_prune(state)}
  end

  defp fetch(state, key) do
    case Map.fetch(state, key) do
      {:ok, {failures, _window_ms}} -> failures
      :error -> []
    end
  end

  defp stash(state, key, [], _window_ms), do: Map.delete(state, key)
  defp stash(state, key, failures, window_ms), do: Map.put(state, key, {failures, window_ms})

  # Failures are kept newest-first, so pruning oldest-first lets us stop early.
  defp prune(failures, window_ms) do
    Enum.take_while(failures, fn timestamp -> now() - timestamp < window_ms end)
  end

  # The key unblocks once its oldest retained failure ages out of the window.
  defp retry_after(failures, window_ms) do
    oldest = List.last(failures)
    remaining_ms = max(oldest + window_ms - now(), 1)
    div(remaining_ms + 999, 1000)
  end

  defp now, do: System.monotonic_time(:millisecond)

  defp schedule_prune(state) do
    Process.send_after(self(), :prune, @prune_interval_ms)
    state
  end
end
