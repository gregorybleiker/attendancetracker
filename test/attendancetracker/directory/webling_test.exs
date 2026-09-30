defmodule AttendanceTracker.Directory.WeblingTest do
  use ExUnit.Case, async: false

  alias AttendanceTracker.Directory.Webling

  setup do
    Application.put_env(:attendancetracker, :directory_req_options, plug: {Req.Test, __MODULE__})

    on_exit(fn ->
      Application.delete_env(:attendancetracker, :directory_req_options)
    end)

    :ok
  end

  test "fetches and normalises members from matching groups" do
    Req.Test.stub(__MODULE__, fn conn ->
      params = URI.decode_query(conn.query_string)
      assert params["format"] == "full"
      assert params["filter"] =~ ~s($parents.title = "Kids Judo")

      Req.Test.json(conn, %{
        "objects" => [
          %{
            "properties" => %{
              "Vorname" => "Ada",
              "Name" => "Lovelace",
              "Telefon" => "079 123"
            }
          }
        ]
      })
    end)

    config = %{"base_url" => "https://demo.webling.ch", "apikey" => "key"}

    assert {:ok, [member]} = Webling.fetch_members(["Kids Judo"], config)
    assert member.first_name == "Ada"
    assert member.last_name == "Lovelace"
    assert member.phone == "079 123"
  end

  test "supports custom property names and multiple trainings" do
    Req.Test.stub(__MODULE__, fn conn ->
      params = URI.decode_query(conn.query_string)
      assert params["filter"] =~ ~s($parents.title = "A")
      assert params["filter"] =~ ~s($parents.title = "B")

      Req.Test.json(conn, %{
        "objects" => [
          %{
            "properties" => %{
              "firstname" => "Tim",
              "lastname" => "Muster",
              "mobile" => "076 000"
            }
          }
        ]
      })
    end)

    config = %{
      "apikey" => "key",
      "first_name_property" => "firstname",
      "last_name_property" => "lastname",
      "phone_property" => "mobile"
    }

    assert {:ok, [member]} = Webling.fetch_members(["A", "B"], config)
    assert member.first_name == "Tim"
    assert member.last_name == "Muster"
    assert member.phone == "076 000"
  end

  test "returns no members without training names" do
    assert {:ok, []} = Webling.fetch_members([], %{"apikey" => "key"})
  end

  test "requires an API key" do
    assert {:error, :missing_apikey} = Webling.fetch_members(["X"], %{})
  end

  test "returns an error when the API responds with a failure" do
    Req.Test.stub(__MODULE__, fn conn ->
      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.send_resp(401, ~s({"error":"Unauthorized"}))
    end)

    assert {:error, {:webling_http_error, 401, "Unauthorized"}} =
             Webling.fetch_members(["X"], %{"apikey" => "bad"})
  end
end
