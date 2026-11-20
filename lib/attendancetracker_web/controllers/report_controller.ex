defmodule AttendanceTrackerWeb.ReportController do
  use AttendanceTrackerWeb, :controller

  alias AttendanceTracker.Tracker
  alias AttendanceTracker.Tracker.Event
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

  def export_event(conn, %{"id" => id}) do
    event = Tracker.get_event!(id)

    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header(
      "content-disposition",
      ~s(attachment; filename="#{event_filename(event)}")
    )
    |> send_resp(200, event_csv(event))
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

  defp event_csv(%Event{} = event) do
    rows =
      for %Participant{} = participant <- Tracker.list_event_participants(event) do
        [
          participant.first_name,
          participant.last_name,
          participant.birthday,
          participant.gender,
          participant.emergency_number
        ]
      end

    lines =
      Enum.map_join(
        [["first_name", "last_name", "birthday", "gender", "emergency_number"] | rows],
        "\r\n",
        fn row ->
          Enum.map_join(row, ",", &csv_escape/1)
        end
      )

    @bom <> lines <> "\r\n"
  end

  defp event_filename(%Event{} = event) do
    slug =
      event.name
      |> to_string()
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9]+/, "-")
      |> String.trim("-")

    base = if slug == "", do: "event-#{event.id}", else: slug
    "#{base}.csv"
  end

  defp csv_escape(value) do
    value = to_string(value)

    if String.contains?(value, [",", "\"", "\r", "\n"]) do
      "\"" <> String.replace(value, "\"", "\"\"") <> "\""
    else
      value
    end
  end
end
