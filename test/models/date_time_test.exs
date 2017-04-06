defmodule LaFamiglia.DateTimeTest do
  use LaFamiglia.ModelCase

  alias LaFamiglia.DateTime

  test "should set and get game time" do
    DateTime.clock!(nil)

    assert DateTime.now == nil

    DateTime.clock!

    assert DateTime.now != nil
  end

  test "from_now" do
    time = DateTime.from_now(0.7)

    %{microsecond: {microseconds, 6}} = time

    assert is_integer(microseconds)
  end
end
