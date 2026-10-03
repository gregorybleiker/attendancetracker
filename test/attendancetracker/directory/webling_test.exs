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

  test "matches members whose training field equals a configured training" do
    Req.Test.stub(__MODULE__, fn conn ->
      params = URI.decode_query(conn.query_string)
      assert params["format"] == "full"

      Req.Test.json(conn, %{
        "objects" => [
          %{
            "properties" => %{
              "Vorname" => "Ada",
              "Name" => "Lovelace",
              "Telefon" => "079 123",
              "Training" => "Kids Judo"
            }
          },
          %{
            "properties" => %{
              "Vorname" => "Bob",
              "Name" => "Other",
              "Training" => "Erwachsene"
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

  test "matches case-insensitively and trims whitespace" do
    Req.Test.stub(__MODULE__, fn conn ->
      Req.Test.json(conn, %{
        "objects" => [
          %{
            "properties" => %{
              "Vorname" => "Ada",
              "Name" => "Lovelace",
              "Training" => "  kids judo "
            }
          }
        ]
      })
    end)

    assert {:ok, [_]} = Webling.fetch_members(["Kids Judo"], %{"apikey" => "key"})
  end

  test "splits a separated training list on ; , and |" do
    Req.Test.stub(__MODULE__, fn conn ->
      Req.Test.json(conn, %{
        "objects" => [
          %{
            "properties" => %{
              "Vorname" => "Ada",
              "Name" => "L",
              "Training" => "Kids Judo; Erwachsene"
            }
          },
          %{"properties" => %{"Vorname" => "Bob", "Name" => "M", "Training" => "A, B"}},
          %{"properties" => %{"Vorname" => "Cid", "Name" => "N", "Training" => "X | Y"}}
        ]
      })
    end)

    assert {:ok, members} = Webling.fetch_members(["B", "Kids Judo"], %{"apikey" => "key"})
    first_names = Enum.map(members, & &1.first_name)

    assert "Ada" in first_names
    assert "Bob" in first_names
    refute "Cid" in first_names
  end

  test "supports multi-value (list) training properties" do
    Req.Test.stub(__MODULE__, fn conn ->
      Req.Test.json(conn, %{
        "objects" => [
          %{
            "properties" => %{
              "Vorname" => "Ada",
              "Name" => "L",
              "Training" => ["Kids Judo", "Erwachsene"]
            }
          }
        ]
      })
    end)

    assert {:ok, [_]} = Webling.fetch_members(["Erwachsene"], %{"apikey" => "key"})
  end

  test "uses the configured training field and property names" do
    Req.Test.stub(__MODULE__, fn conn ->
      Req.Test.json(conn, %{
        "objects" => [
          %{
            "properties" => %{
              "firstname" => "Tim",
              "lastname" => "Muster",
              "mobile" => "076 000",
              "Kurs" => "Kids Judo"
            }
          }
        ]
      })
    end)

    config = %{
      "apikey" => "key",
      "training_field" => "Kurs",
      "first_name_property" => "firstname",
      "last_name_property" => "lastname",
      "phone_property" => "mobile"
    }

    assert {:ok, [member]} = Webling.fetch_members(["Kids Judo"], config)
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
