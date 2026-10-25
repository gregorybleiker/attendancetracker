defmodule AttendanceTracker.VersionTest do
  use ExUnit.Case, async: true

  alias AttendanceTracker.Version

  test "version/0 reports the application version" do
    assert Version.version() == "0.4.0"
  end

  test "git_hash/0 reports a revision" do
    assert is_binary(Version.git_hash())
    assert Version.git_hash() != ""
  end

  test "full/0 combines the version and the revision" do
    assert Version.full() == "#{Version.version()}+#{Version.git_hash()}"
    assert String.starts_with?(Version.full(), Version.version() <> "+")
  end
end
