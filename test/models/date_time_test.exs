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

    %{usec: usec} = time

    assert usec > 0
  end

  test "add_seconds with usecs" do
    time1 = Ecto.DateTime.cast!("2016-01-29T21:08:00.06Z")

    assert DateTime.add_seconds(time1, 1).usec == 60_000
    assert DateTime.add_seconds(time1, 1.0).usec == 60_000
    assert DateTime.add_seconds(time1, 1.2).usec == 260_000
  end

  test "time_diff" do
    time1 = Ecto.DateTime.cast!("2016-01-29T21:08:00.06Z")
    time2 = Ecto.DateTime.cast!("2016-01-29T21:08:00.26Z")

    assert DateTime.time_diff(time1, time2) == 0.2
  end
end
