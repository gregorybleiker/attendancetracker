defmodule AttendanceTracker.Repo do
  use Ecto.Repo,
    otp_app: :attendancetracker,
    adapter: Ecto.Adapters.SQLite3
end
