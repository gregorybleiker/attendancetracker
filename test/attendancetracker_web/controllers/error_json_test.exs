defmodule AttendanceTrackerWeb.ErrorJSONTest do
  use AttendanceTrackerWeb.ConnCase, async: true

  test "renders 404" do
    assert AttendanceTrackerWeb.ErrorJSON.render("404.json", %{}) == %{
             errors: %{detail: "Not Found"}
           }
  end

  test "renders 500" do
    assert AttendanceTrackerWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
