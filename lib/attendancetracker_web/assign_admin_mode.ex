defmodule AttendanceTrackerWeb.AssignAdminMode do
  @moduledoc """
  Makes the session admin flag available to every LiveView as `:admin_mode`,
  so the navbar can toggle between the "Admin mode" and "Exit admin mode"
  menu items.
  """

  import Phoenix.Component, only: [assign: 3]

  alias AttendanceTracker.AdminSession
  alias AttendanceTracker.Tracker
  alias AttendanceTrackerWeb.Locales

  def on_mount(:default, _params, session, socket) do
    Gettext.put_locale(AttendanceTrackerWeb.Gettext, session["locale"] || Locales.default())

    admin_mode = AdminSession.active?(session["admin_token"], Tracker.admin_timeout_seconds())

    {:cont, assign(socket, :admin_mode, admin_mode)}
  end
end
