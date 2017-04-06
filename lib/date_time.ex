defmodule LaFamiglia.DateTime do
  @moduledoc """
  This module manages the game’s time. It does so by providing the function
  `now/0` which returns the same value for subsequent calls until `clock!/1`
  is called. `clock!/1` will typically be called at the beginning of a request
  or test, or before an event is processed by the backend. That way, the game’s
  time does not change across multiple calls of `now/0`.
  """

  def max(time1, time2) do
    case DateTime.compare(time1, time2) do
      :gt -> time1
      _   -> time2
    end
  end

  def from_now(seconds) do
    Timex.shift(now, microseconds: trunc(seconds * 1_000_000))
  end

  def clock!(time \\ DateTime.utc_now) do
    Process.put(:la_famiglia_now, time)
  end

  def now do
    Process.get(:la_famiglia_now)
  end
end
