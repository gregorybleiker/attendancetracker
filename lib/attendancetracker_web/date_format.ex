defmodule AttendanceTrackerWeb.DateFormat do
  @moduledoc """
  Locale-aware date rendering for the UI.

  `Calendar.strftime/2` always uses English names, so month and weekday names
  are routed through Gettext and the day/month order is a translatable format
  string (`%{weekday}, %{month} %{day}` → `%{weekday}, %{day}. %{month}`).
  """
  use Gettext, backend: AttendanceTrackerWeb.Gettext

  alias AttendanceTrackerWeb.TrainingLabels

  @doc ~S(Renders a long date, e.g. "Monday, October 2" / "Montag, 2. Oktober".)
  def long_date(%Date{} = date) do
    gettext("%{weekday}, %{month} %{day}",
      weekday: TrainingLabels.weekday_label(Date.day_of_week(date)),
      month: month_name(date.month),
      day: date.day
    )
  end

  @doc ~S(Renders a short date, e.g. "Oct 2" / "2. Okt.".)
  def short_date(%Date{} = date) do
    gettext("%{month} %{day}", month: month_abbr(date.month), day: date.day)
  end

  defp month_name(1), do: gettext("January")
  defp month_name(2), do: gettext("February")
  defp month_name(3), do: gettext("March")
  defp month_name(4), do: gettext("April")
  defp month_name(5), do: gettext("May")
  defp month_name(6), do: gettext("June")
  defp month_name(7), do: gettext("July")
  defp month_name(8), do: gettext("August")
  defp month_name(9), do: gettext("September")
  defp month_name(10), do: gettext("October")
  defp month_name(11), do: gettext("November")
  defp month_name(12), do: gettext("December")

  defp month_abbr(1), do: gettext("Jan")
  defp month_abbr(2), do: gettext("Feb")
  defp month_abbr(3), do: gettext("Mar")
  defp month_abbr(4), do: gettext("Apr")
  defp month_abbr(5), do: gettext("May")
  defp month_abbr(6), do: gettext("Jun")
  defp month_abbr(7), do: gettext("Jul")
  defp month_abbr(8), do: gettext("Aug")
  defp month_abbr(9), do: gettext("Sep")
  defp month_abbr(10), do: gettext("Oct")
  defp month_abbr(11), do: gettext("Nov")
  defp month_abbr(12), do: gettext("Dec")
end
