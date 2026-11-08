defmodule AttendanceTracker.AdminSessionTest do
  use AttendanceTracker.DataCase

  alias AttendanceTracker.AdminSession

  @timeout 600

  test "starts an active session" do
    token = AdminSession.start()

    assert AdminSession.active?(token, @timeout)
    assert {:ok, remaining_ms} = AdminSession.expires_in(token, @timeout)
    assert remaining_ms > 0
  end

  test "refresh extends an active session and returns true" do
    token = AdminSession.start()
    AdminSession.backdate(token, 300_000)

    assert AdminSession.refresh(token, @timeout)
    assert {:ok, remaining_ms} = AdminSession.expires_in(token, @timeout)
    assert remaining_ms > 300_000
  end

  test "active? does not extend the session" do
    token = AdminSession.start()
    AdminSession.backdate(token, 300_000)

    assert AdminSession.active?(token, @timeout)
    assert {:ok, remaining_ms} = AdminSession.expires_in(token, @timeout)
    assert remaining_ms <= 300_000
  end

  test "refresh drops a session idle past the timeout" do
    token = AdminSession.start()
    AdminSession.backdate(token, (@timeout + 1) * 1000)

    refute AdminSession.refresh(token, @timeout)
    assert AdminSession.expires_in(token, @timeout) == :unknown
  end

  test "a session idle past the timeout is inactive" do
    token = AdminSession.start()
    AdminSession.backdate(token, (@timeout + 1) * 1000)

    refute AdminSession.active?(token, @timeout)
    assert AdminSession.expires_in(token, @timeout) == :unknown
  end

  test "forget removes a session" do
    token = AdminSession.start()

    assert AdminSession.forget(token) == :ok
    refute AdminSession.active?(token, @timeout)
    assert AdminSession.expires_in(token, @timeout) == :unknown
  end

  test "unknown tokens are inactive" do
    refute AdminSession.active?("nope", @timeout)
    assert AdminSession.expires_in("nope", @timeout) == :unknown
  end

  test "a nil token is inactive" do
    refute AdminSession.active?(nil, @timeout)
    assert AdminSession.expires_in(nil, @timeout) == :unknown
  end
end
