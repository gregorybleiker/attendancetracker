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

  test "returns every member with their trainings" do
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
              "Geburtstag" => "1990-12-10",
              "Geschlecht" => "f",
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

    assert {:ok, [ada, bob]} = Webling.fetch_members(config)
    assert ada.first_name == "Ada"
    assert ada.last_name == "Lovelace"
    assert ada.phone == "079 123"
    assert ada.birthday == "1990-12-10"
    assert ada.gender == "f"
    assert ada.trainings == ["Kids Judo"]
    assert bob.trainings == ["Erwachsene"]
    assert bob.birthday == nil
  end

  test "accepts European and datetime birthday formats" do
    Req.Test.stub(__MODULE__, fn conn ->
      Req.Test.json(conn, %{
        "objects" => [
          %{"properties" => %{"Vorname" => "A", "Name" => "One", "Geburtstag" => "10.12.1990"}},
          %{
            "properties" => %{
              "Vorname" => "B",
              "Name" => "Two",
              "Geburtstag" => "1990-12-10T00:00:00"
            }
          },
          %{"properties" => %{"Vorname" => "C", "Name" => "Three", "Geburtstag" => "nonsense"}}
        ]
      })
    end)

    assert {:ok, [a, b, c]} = Webling.fetch_members(%{"apikey" => "key"})
    assert a.birthday == "1990-12-10"
    assert b.birthday == "1990-12-10"
    assert c.birthday == nil
  end

  test "excludes members whose exit field is not empty" do
    Req.Test.stub(__MODULE__, fn conn ->
      Req.Test.json(conn, %{
        "objects" => [
          %{"properties" => %{"Vorname" => "Ada", "Name" => "L", "Training" => "Kids Judo"}},
          %{
            "properties" => %{
              "Vorname" => "Bob",
              "Name" => "M",
              "Training" => "Kids Judo",
              "Austritt" => "2026-08-31"
            }
          }
        ]
      })
    end)

    assert {:ok, [member]} = Webling.fetch_members(%{"apikey" => "key"})
    assert member.first_name == "Ada"
  end

  test "splits delimited training values" do
    Req.Test.stub(__MODULE__, fn conn ->
      Req.Test.json(conn, %{
        "objects" => [
          %{
            "properties" => %{
              "Vorname" => "Ada",
              "Name" => "L",
              "Training" => "Kids Judo; Erwachsene, Wettkampf "
            }
          }
        ]
      })
    end)

    assert {:ok, [member]} = Webling.fetch_members(%{"apikey" => "key"})
    assert member.trainings == ["Kids Judo", "Erwachsene", "Wettkampf"]
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

    assert {:ok, [member]} = Webling.fetch_members(%{"apikey" => "key"})
    assert member.trainings == ["Kids Judo", "Erwachsene"]
  end

  test "uses the configured training, exit and property names" do
    Req.Test.stub(__MODULE__, fn conn ->
      Req.Test.json(conn, %{
        "objects" => [
          %{
            "properties" => %{
              "firstname" => "Tim",
              "lastname" => "Muster",
              "mobile" => "076 000",
              "dob" => "01.02.2000",
              "sex" => "m",
              "Kurs" => "Kids Judo",
              "Ausgetreten" => ""
            }
          },
          %{
            "properties" => %{
              "firstname" => "Gone",
              "lastname" => "Away",
              "Kurs" => "Kids Judo",
              "Ausgetreten" => "yes"
            }
          }
        ]
      })
    end)

    config = %{
      "apikey" => "key",
      "training_field" => "Kurs",
      "exit_field" => "Ausgetreten",
      "first_name_property" => "firstname",
      "last_name_property" => "lastname",
      "phone_property" => "mobile",
      "birthday_property" => "dob",
      "gender_property" => "sex"
    }

    assert {:ok, [member]} = Webling.fetch_members(config)
    assert member.first_name == "Tim"
    assert member.last_name == "Muster"
    assert member.phone == "076 000"
    assert member.birthday == "2000-02-01"
    assert member.gender == "m"
    assert member.trainings == ["Kids Judo"]
  end

  test "requires an API key" do
    assert {:error, :missing_apikey} = Webling.fetch_members(%{})
  end

  test "returns an error when the API responds with a failure" do
    Req.Test.stub(__MODULE__, fn conn ->
      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.send_resp(401, ~s({"error":"Unauthorized"}))
    end)

    assert {:error, {:webling_http_error, 401, "Unauthorized"}} =
             Webling.fetch_members(%{"apikey" => "bad"})
  end
end
