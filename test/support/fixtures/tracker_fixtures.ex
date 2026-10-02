defmodule AttendanceTracker.TrackerFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `AttendanceTracker.Tracker` context.
  """

  @doc """
  Generate a participant.
  """
  def participant_fixture(attrs \\ %{}) do
    {source, attrs} = Map.pop(attrs, :source, "local")

    {:ok, participant} =
      attrs
      |> Enum.into(%{
        active: true,
        name: "some name"
      })
      |> AttendanceTracker.Tracker.create_participant(source)

    participant
  end

  @doc """
  Attach a photo to a participant.
  """
  def participant_photo_fixture(participant, attrs \\ %{}) do
    data = Map.get(attrs, :data, "photo-bytes")
    content_type = Map.get(attrs, :content_type, "image/jpeg")

    {:ok, photo} =
      AttendanceTracker.Tracker.put_participant_photo(participant, data, content_type)

    photo
  end

  @doc """
  Generate a training.
  """
  def training_fixture(attrs \\ %{}) do
    {:ok, training} =
      attrs
      |> Enum.into(%{
        weekday: 1,
        starts_at: ~T[19:00:00],
        ends_at: ~T[21:30:00]
      })
      |> AttendanceTracker.Tracker.create_training()

    training
  end

  @doc """
  Generate a training_session.
  """
  def training_session_fixture(attrs \\ %{}) do
    {:ok, training_session} =
      attrs
      |> Enum.into(%{
        date: ~D[2026-09-14]
      })
      |> AttendanceTracker.Tracker.create_training_session()

    training_session
  end

  @doc """
  Generate a check_in (creating a participant and training session
  on the fly unless given via attrs).
  """
  def check_in_fixture(attrs \\ %{}) do
    participant = Map.get(attrs, :participant) || participant_fixture()
    training_session = Map.get(attrs, :training_session) || training_session_fixture()

    {:ok, check_in} =
      AttendanceTracker.Tracker.check_in(participant, training_session)

    check_in
  end
end
