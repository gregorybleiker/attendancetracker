defmodule AttendanceTrackerWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use AttendanceTrackerWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  use AttendanceTrackerWeb, :verified_routes

  import Phoenix.ConnTest, only: [post: 3]

  using do
    quote do
      # The default endpoint for testing
      @endpoint AttendanceTrackerWeb.Endpoint

      use AttendanceTrackerWeb, :verified_routes

      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import AttendanceTrackerWeb.ConnCase
    end
  end

  setup tags do
    AttendanceTracker.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Logs the client in with the default admin PIN and returns the
  authenticated connection.
  """
  def log_in(conn) do
    post(conn, ~p"/login", %{"pin" => "1234"})
  end
end
