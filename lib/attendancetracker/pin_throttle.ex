defmodule AttendanceTracker.PinThrottle do
  @moduledoc """
  Brute-force policy for the admin and session PINs, built on
  `AttendanceTracker.RateLimit`.

  Failures are counted per client IP *and* in aggregate. The per-IP cap slows
  a single source down; the (higher) aggregate cap stops a distributed attack
  from many addresses from searching the small PIN space in a practical time.
  A successful verification clears only the per-IP counter, so an attacker
  cannot reset the aggregate by interleaving guesses.

  Every PIN verification (the `/login` and `/start` POSTs and the LiveView
  unlock/check-out prompts) must go through `check_*` before verifying and
  `record_*_failure/1` on a miss.
  """

  alias AttendanceTracker.RateLimit

  # Caps chosen so a 4-digit PIN cannot be searched quickly while leaving
  # generous headroom for legitimate mistypes.
  @window_ms 5 * 60_000
  @admin_limit 5
  @admin_global_limit 30
  @session_limit 10
  @session_global_limit 60

  @doc "Returns `:ok` or `{:error, retry_after_seconds}` for an admin PIN attempt from `ip`."
  def check_admin(ip), do: check(admin_keys(ip))

  @doc "Records a failed admin PIN attempt from `ip`."
  def record_admin_failure(ip), do: record(admin_keys(ip))

  @doc "Clears the per-IP admin failures, typically after a successful login."
  def clear_admin(ip), do: RateLimit.clear({:admin, ip})

  @doc "Returns `:ok` or `{:error, retry_after_seconds}` for a session PIN attempt from `ip`."
  def check_session(ip), do: check(session_keys(ip))

  @doc "Records a failed session PIN attempt from `ip`."
  def record_session_failure(ip), do: record(session_keys(ip))

  @doc "Clears the per-IP session failures, typically after a successful unlock."
  def clear_session(ip), do: RateLimit.clear({:session, ip})

  defp admin_keys(ip),
    do: [{{:admin, ip}, @admin_limit}, {{:admin, :global}, @admin_global_limit}]

  defp session_keys(ip),
    do: [{{:session, ip}, @session_limit}, {{:session, :global}, @session_global_limit}]

  defp check(keys) do
    Enum.reduce_while(keys, :ok, fn {key, limit}, _acc ->
      case RateLimit.check(key, limit, @window_ms) do
        :ok -> {:cont, :ok}
        {:error, _seconds} = error -> {:halt, error}
      end
    end)
  end

  defp record(keys) do
    Enum.each(keys, fn {key, limit} -> RateLimit.record(key, limit, @window_ms) end)
    :ok
  end
end
