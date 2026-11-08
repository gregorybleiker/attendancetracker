defmodule AttendanceTrackerWeb.AdminSessionHook do
  @moduledoc """
  `on_mount` hook enforcing the admin session's idle timeout for the
  authenticated LiveViews.

  Full page loads are checked by `Plugs.RequireAdminPin`; this hook covers
  WebSocket connects and LiveView live navigation (which skip plugs). It
  refreshes the session on activity (events and params) and schedules a check
  so an idle tab is redirected to the login page once the configured timeout
  (see `AttendanceTracker.Tracker.admin_timeout_minutes/0`) elapses.
  """

  use AttendanceTrackerWeb, :verified_routes

  import Phoenix.LiveView, only: [attach_hook: 4, redirect: 2]

  alias AttendanceTracker.AdminSession
  alias AttendanceTracker.Tracker

  def on_mount(:default, _params, session, socket) do
    token = session["admin_token"]

    if AdminSession.refresh(token, Tracker.admin_timeout_seconds()) do
      socket =
        socket
        |> attach_hook(:admin_refresh_event, :handle_event, fn _event, _params, socket ->
          AdminSession.refresh(token, Tracker.admin_timeout_seconds())
          {:cont, socket}
        end)
        |> attach_hook(:admin_refresh_params, :handle_params, fn _params, _uri, socket ->
          AdminSession.refresh(token, Tracker.admin_timeout_seconds())
          {:cont, socket}
        end)
        |> attach_hook(:admin_timeout, :handle_info, fn
          :admin_session_check, socket ->
            case AdminSession.expires_in(token, Tracker.admin_timeout_seconds()) do
              {:ok, remaining_ms} ->
                Process.send_after(self(), :admin_session_check, remaining_ms)
                {:halt, socket}

              _ ->
                AdminSession.forget(token)
                {:halt, redirect(socket, to: ~p"/login")}
            end

          _message, socket ->
            {:cont, socket}
        end)

      schedule_check(token)
      {:cont, socket}
    else
      {:halt, redirect(socket, to: ~p"/login")}
    end
  end

  defp schedule_check(token) do
    case AdminSession.expires_in(token, Tracker.admin_timeout_seconds()) do
      {:ok, remaining_ms} -> Process.send_after(self(), :admin_session_check, remaining_ms)
      _ -> send(self(), :admin_session_check)
    end
  end
end
