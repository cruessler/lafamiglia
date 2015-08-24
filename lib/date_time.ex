defmodule LaFamiglia.DateTime do
  @moduledoc """
  This module manages the game’s time. It does so by providing the function
  `now/0` which returns the same value for subsequent calls until `clock!/1`
  is called. `clock!/1` will typically be called at the beginning of a request
  or test, or before an event is processed by the backend. That way, the game’s
  time does not change across multiple calls of `now/0`.
  """

  def to_seconds %Ecto.DateTime{usec: usecs} = datetime do
    datetime
    |> Ecto.DateTime.to_erl
    |> :calendar.datetime_to_gregorian_seconds
    |> +(usecs / 1_000_000)
  end

  def add_seconds(%Ecto.DateTime{usec: usecs} = datetime, seconds) do
    new_seconds = to_seconds(datetime) + seconds
    frac        = new_seconds - round(new_seconds)
    new_seconds = trunc(new_seconds)

    new_datetime =
      new_seconds
      |> :calendar.gregorian_seconds_to_datetime
      |> Ecto.DateTime.from_erl

    %Ecto.DateTime{new_datetime | usec: trunc(frac * 1_000_000)}
  end

  def time_diff(%Ecto.DateTime{} = time1, %Ecto.DateTime{} = time2) do
    to_seconds(time2) - to_seconds(time1)
  end

  def clock!(time \\ Ecto.DateTime.utc) do
    Process.put(:la_famiglia_now, time)
  end

  def now do
    Process.get(:la_famiglia_now)
  end
end
