defmodule AttendanceTrackerWeb.Gettext do
  @moduledoc """
  Gettext backend for AttendanceTracker (English + German).
  """
  use Gettext.Backend, otp_app: :attendancetracker
end
