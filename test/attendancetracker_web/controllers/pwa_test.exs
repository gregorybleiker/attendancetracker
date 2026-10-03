defmodule AttendanceTrackerWeb.PwaTest do
  use AttendanceTrackerWeb.ConnCase

  test "serves the web app manifest with a manifest content type", %{conn: conn} do
    conn = get(conn, "/manifest.webmanifest")

    assert response(conn, 200) =~ "\"name\": \"AttendanceTracker\""
    assert response(conn, 200) =~ "\"orientation\": \"any\""
    assert get_resp_header(conn, "content-type") == ["application/manifest+json"]
  end

  test "serves the service worker", %{conn: conn} do
    conn = get(conn, "/service-worker.js")

    assert response(conn, 200) =~ "addEventListener"
  end

  test "serves the install icons", %{conn: conn} do
    assert response(get(conn, "/images/icon-192.png"), 200)
    assert response(get(conn, "/images/icon-512.png"), 200)
    assert response(get(conn, "/images/icon-maskable-512.png"), 200)
    assert response(get(conn, "/images/apple-touch-icon.png"), 200)
    assert response(get(conn, "/images/favicon-32.png"), 200)
  end

  test "the root layout links the manifest and sets the theme colour", %{conn: conn} do
    html = conn |> get(~p"/login") |> html_response(200)

    assert html =~ ~s(rel="manifest")
    assert html =~ ~s(name="theme-color")
    assert html =~ ~s(rel="icon")
    assert html =~ ~s(rel="apple-touch-icon")
  end
end
