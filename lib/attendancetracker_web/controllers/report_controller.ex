defmodule AttendanceTrackerWeb.ReportController do
  use AttendanceTrackerWeb, :controller

  alias AttendanceTracker.Tracker
  alias AttendanceTracker.Tracker.Participant
  alias AttendanceTracker.Tracker.Training
  alias AttendanceTracker.Tracker.TrainingSession

  # UTF-8 BOM, so spreadsheet tools pick the right encoding
  @bom <<0xEF, 0xBB, 0xBF>>

  def download(conn, %{"year" => year_param}) do
    case parse_year(year_param) do
      {:ok, year} ->
        csv = csv_report(Tracker.list_sessions_for_report(year))

        conn
        |> put_resp_content_type("text/csv")
        |> put_resp_header(
          "content-disposition",
          ~s(attachment; filename="attendance-#{year}.csv")
        )
        |> send_resp(200, csv)

      :error ->
        conn
        |> put_flash(:error, "Please select a valid year.")
        |> redirect(to: ~p"/reporting")
    end
  end

  defp parse_year(param) when is_binary(param) do
    with {year, ""} <- Integer.parse(param),
         {:ok, _date} <- Date.new(year, 1, 1) do
      {:ok, year}
    else
      _ -> :error
    end
  end

  defp parse_year(_param), do: :error

  defp csv_report(sessions) do
    rows =
      for %TrainingSession{} = session <- sessions do
        [
          training_name(session),
          Date.to_string(session.date),
          Enum.map_join(session.check_ins, "; ", &Participant.full_name(&1.participant))
        ]
      end

    lines =
      Enum.map_join([["training", "date", "participants"] | rows], "\r\n", fn row ->
        Enum.map_join(row, ",", &csv_escape/1)
      end)

    @bom <> lines <> "\r\n"
  end

  defp training_name(%TrainingSession{training: %Training{} = training}) do
    Training.label(training)
  end

  defp training_name(%TrainingSession{}), do: gettext("Ad-hoc training")

  defp csv_escape(value) do
    value = to_string(value)

    if String.contains?(value, [",", "\"", "\r", "\n"]) do
      "\"" <> String.replace(value, "\"", "\"\"") <> "\""
    else
      value
    end
  end
end
