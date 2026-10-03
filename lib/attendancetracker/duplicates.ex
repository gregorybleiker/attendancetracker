defmodule AttendanceTracker.Duplicates do
  @moduledoc """
  Finds likely duplicate participants and merges them.

  A candidate is a participant that has *only* a first name or *only* a last
  name whose single name matches — case-insensitively, exact or substring — the
  first or last name of a participant that has both names.

  Merging keeps the full-name participant, moves the other's check-ins (and
  photo) over, and deletes the duplicate.
  """

  import Ecto.Query

  alias AttendanceTracker.Logs
  alias AttendanceTracker.Repo
  alias AttendanceTracker.Tracker
  alias AttendanceTracker.Tracker.CheckIn
  alias AttendanceTracker.Tracker.Participant
  alias AttendanceTracker.Tracker.ParticipantPhoto

  @doc """
  Returns the likely duplicate pairs as `%{survivor: participant, duplicate:
  participant}` (the survivor is the one with both names).
  """
  def list_candidates do
    participants = Tracker.list_participants()

    incomplete = Enum.filter(participants, &single_name/1)
    complete = Enum.filter(participants, &full_name?/1)

    for duplicate <- incomplete, survivor <- complete, matches?(duplicate, survivor) do
      %{survivor: survivor, duplicate: duplicate}
    end
  end

  @doc """
  Merges `duplicate` into `survivor`, applying `attrs` (first name, last name,
  emergency number, active) to the survivor.

    * check-ins are moved; on a session both attended, the survivor's wins and
      the duplicate's is dropped;
    * the duplicate's photo is moved only when the survivor has none;
    * the duplicate is deleted.

  Returns `{:ok, survivor}` or `{:error, changeset}`.
  """
  def merge(%Participant{} = survivor, %Participant{} = duplicate, attrs) do
    changeset = Tracker.change_participant(survivor, attrs)

    if changeset.valid? do
      {:ok, merged} =
        Repo.transaction(fn ->
          source = merged_source(survivor, duplicate)

          {:ok, survivor} = Repo.update(changeset)
          {:ok, survivor} = Tracker.set_participant_source(survivor, source)

          move_check_ins(survivor, duplicate)
          move_photo(survivor, duplicate)

          {:ok, _} = Repo.delete(duplicate)

          Logs.audit(%{
            action: "merge",
            participant_id: survivor.id,
            participant_name: Participant.full_name(survivor)
          })

          survivor
        end)

      {:ok, merged}
    else
      {:error, changeset}
    end
  end

  ## Detection

  defp single_name(%Participant{first_name: first, last_name: last}) do
    first_present = present(first)
    last_present = present(last)

    cond do
      first_present && !last_present -> first
      last_present && !first_present -> last
      true -> nil
    end
  end

  defp full_name?(%Participant{first_name: first, last_name: last}),
    do: present(first) && present(last)

  defp matches?(duplicate, survivor) do
    value = normalise(single_name(duplicate))

    value != "" and
      (fuzzy?(value, survivor.first_name) or fuzzy?(value, survivor.last_name))
  end

  defp fuzzy?(value, candidate) do
    candidate = normalise(candidate)

    candidate != "" and
      (String.contains?(candidate, value) or String.contains?(value, candidate))
  end

  ## Merge helpers

  defp move_check_ins(survivor, duplicate) do
    survivor_sessions =
      from(c in CheckIn, where: c.participant_id == ^survivor.id, select: c.training_session_id)
      |> Repo.all()
      |> MapSet.new()

    from(c in CheckIn, where: c.participant_id == ^duplicate.id)
    |> Repo.all()
    |> Enum.each(fn check_in ->
      if MapSet.member?(survivor_sessions, check_in.training_session_id) do
        {:ok, _} = Repo.delete(check_in)
      else
        {:ok, _} =
          check_in
          |> Ecto.Changeset.change(participant_id: survivor.id)
          |> Repo.update()
      end
    end)
  end

  defp move_photo(survivor, duplicate) do
    case {Repo.get_by(ParticipantPhoto, participant_id: survivor.id),
          Repo.get_by(ParticipantPhoto, participant_id: duplicate.id)} do
      {nil, %ParticipantPhoto{} = photo} ->
        {:ok, _} =
          photo
          |> Ecto.Changeset.change(participant_id: survivor.id)
          |> Repo.update()

      _ ->
        :ok
    end
  end

  defp merged_source(survivor, duplicate) do
    if Participant.webling?(survivor) or Participant.webling?(duplicate),
      do: "webling",
      else: "local"
  end

  defp present(value), do: is_binary(value) and String.trim(value) != ""

  defp normalise(value) when is_binary(value), do: value |> String.trim() |> String.downcase()
  defp normalise(_value), do: ""
end
