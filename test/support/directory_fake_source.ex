defmodule AttendanceTracker.Directory.FakeSource do
  @moduledoc """
  A test `AttendanceTracker.Directory.Source` that returns fixed members and
  records the config it was called with.
  """

  @behaviour AttendanceTracker.Directory.Source

  @impl true
  def label, do: "Fake"

  @impl true
  def config_fields do
    [%{key: :token, label: "Token", default: "", secret: true}]
  end

  @impl true
  def fetch_members(config) do
    send(self(), {:fake_fetch, config})

    {:ok,
     [
       %{first_name: "Ada", last_name: "Lovelace", phone: "079 111", trainings: ["Kids Judo"]},
       %{first_name: "Grace", last_name: "Hopper", phone: "079 222", trainings: ["Kung Fu"]}
     ]}
  end
end
