defmodule AttendanceTracker.RateLimitTest do
  use ExUnit.Case, async: false

  alias AttendanceTracker.RateLimit

  setup do
    RateLimit.clear_all()
    :ok
  end

  test "allows attempts while under the limit" do
    key = make_ref()

    for _ <- 1..3 do
      assert RateLimit.check(key, 5, 60_000) == :ok
      RateLimit.record(key, 5, 60_000)
    end

    assert RateLimit.check(key, 5, 60_000) == :ok
  end

  test "reports a positive retry_after once the limit is reached" do
    key = make_ref()
    window = 60_000

    for _ <- 1..5, do: RateLimit.record(key, 5, window)

    assert {:error, seconds} = RateLimit.check(key, 5, window)
    assert seconds > 0
    assert seconds <= div(window, 1000)
  end

  test "keys are independent" do
    RateLimit.record(:a, 1, 60_000)

    assert {:error, _seconds} = RateLimit.check(:a, 1, 60_000)
    assert RateLimit.check(:b, 1, 60_000) == :ok
  end

  test "clear forgets a single key" do
    RateLimit.record(:key, 1, 60_000)
    assert {:error, _seconds} = RateLimit.check(:key, 1, 60_000)

    assert RateLimit.clear(:key) == :ok
    assert RateLimit.check(:key, 1, 60_000) == :ok
  end

  test "retains at most limit failures, so retry_after stays within the window" do
    key = make_ref()
    window = 10_000

    for _ <- 1..25, do: RateLimit.record(key, 5, window)

    assert {:error, seconds} = RateLimit.check(key, 5, window)
    assert seconds <= div(window, 1000)
  end
end
