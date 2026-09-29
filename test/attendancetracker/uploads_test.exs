defmodule AttendanceTracker.UploadsTest do
  use ExUnit.Case, async: true

  alias AttendanceTracker.Uploads

  defp stored_path(filename) do
    Path.join([:code.priv_dir(:attendancetracker), "static", "uploads", filename])
  end

  test "write_binary/2 stores the contents and returns the public path" do
    assert {:ok, "/uploads/" <> filename} = Uploads.write_binary("photo-bytes", ".jpg")
    assert String.ends_with?(filename, ".jpg")

    path = stored_path(filename)
    assert File.read!(path) == "photo-bytes"

    File.rm!(path)
  end

  test "copy_uploaded/2 copies a temp file and keeps the original extension" do
    source = Path.join(System.tmp_dir!(), "uploads-test-#{System.unique_integer([:positive])}")
    File.write!(source, "jpeg-bytes")

    assert {:ok, "/uploads/" <> filename} = Uploads.copy_uploaded(source, "selfie.JPEG")
    assert String.ends_with?(filename, ".JPEG")

    path = stored_path(filename)
    assert File.read!(path) == "jpeg-bytes"

    File.rm!(path)
    File.rm!(source)
  end
end
