defmodule AttendanceTrackerWeb.AssignAdminMode do
  @moduledoc """
  Makes the session admin flag available to every LiveView as `:admin_mode`,
  so the navbar can toggle between the "Admin mode" and "Exit admin mode"
  menu items.
  """

  import Phoenix.Component, only: [assign: 3]

  alias AttendanceTrackerWeb.Locales

  def on_mount(:default, _params, session, socket) do
    Gettext.put_locale(AttendanceTrackerWeb.Gettext, session["locale"] || Locales.default())

    {:cont, assign(socket, :admin_mode, session["admin_pin_ok"] == true)}
  end
end
