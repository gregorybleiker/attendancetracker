defmodule AttendanceTrackerWeb.TrainingLabels do
  @moduledoc """
  Translatable labels for the ISO weekday numbers used by trainings.

  Kept in the web layer (and as Gettext string literals) so the weekday names
  are extracted and translated, while the domain schema stays presentation-free.
  """
  use Gettext, backend: AttendanceTrackerWeb.Gettext

  def weekday_label(1), do: gettext("Monday")
  def weekday_label(2), do: gettext("Tuesday")
  def weekday_label(3), do: gettext("Wednesday")
  def weekday_label(4), do: gettext("Thursday")
  def weekday_label(5), do: gettext("Friday")
  def weekday_label(6), do: gettext("Saturday")
  def weekday_label(7), do: gettext("Sunday")
  def weekday_label(_weekday), do: ""
end
