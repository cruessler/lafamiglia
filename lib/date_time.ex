defmodule LaFamiglia.DateTime do
  @moduledoc """
  This module manages the game’s time. It does so by providing the function
  `now/0` which returns the same value for subsequent calls until `clock!/1`
  is called. `clock!/1` will typically be called at the beginning of a request
  or test, or before an event is processed by the backend. That way, the game’s
  time does not change across multiple calls of `now/0`.

  Most helper functions will be obsolete once a library for handling date and
  time has been selected.
  """

  defp to_seconds %Ecto.DateTime{usec: usecs} = datetime do
    seconds =
      datetime
      |> Ecto.DateTime.to_erl
      |> :calendar.datetime_to_gregorian_seconds

    {seconds, usecs}
  end

  defp to_datetime({seconds, usecs}) do
    new_datetime =
      seconds
      |> :calendar.gregorian_seconds_to_datetime
      |> Ecto.DateTime.from_erl

    %Ecto.DateTime{new_datetime | usec: usecs}
  end

  @doc """
  This function will be obsolete once a library for handling date and time has
  been selected.
  """
  def add_seconds(%Ecto.DateTime{} = datetime, seconds2) when is_integer(seconds2) do
    {seconds1, usecs} = to_seconds(datetime)

    to_datetime({seconds1 + seconds2, usecs})
  end
  def add_seconds(%Ecto.DateTime{} = datetime, seconds2) when is_float(seconds2) and seconds2 >= 0 do
    {seconds1, usecs1} = to_seconds(datetime)

    usecs = usecs1 + trunc(seconds2 * 1_000_000)

    {seconds1 + div(usecs, 1_000_000), rem(usecs, 1_000_000)}
    |> to_datetime
  end
  def add_seconds(%Ecto.DateTime{} = datetime, seconds2) when is_float(seconds2) do
    {seconds1, usecs1} = to_seconds(datetime)

    usecs2   = rem(-trunc(seconds2 * 1_000_000), 1_000_000)
    seconds2 = -trunc(seconds2)

    if usecs1 < usecs2 do
      {seconds1 - seconds2 - 1, (usecs1 - usecs2) + 1_000_000}
    else
      {seconds1 - seconds2, usecs1 - usecs2}
    end
    |> to_datetime
  end

  def time_diff({seconds1, usecs1}, {seconds2, usecs2}) when usecs2 > usecs1 do
    seconds1 - seconds2 - 1 + ((usecs1 - usecs2) + 1_000_000) / 1_000_000
  end
  def time_diff({seconds1, usecs1}, {seconds2, usecs2}) do
    seconds1 - seconds2 + (usecs1 - usecs2) / 1_000_000
  end
  def time_diff(%Ecto.DateTime{} = time1, %Ecto.DateTime{} = time2) do
    time_diff(to_seconds(time2), to_seconds(time1))
  end

  def max(time1, time2) do
    case Ecto.DateTime.compare(time1, time2) do
      :gt -> time1
      _   -> time2
    end
  end

  def from_now(seconds) do
    add_seconds(now, seconds)
  end

  def clock!(time \\ Ecto.DateTime.utc(:usec)) do
    Process.put(:la_famiglia_now, time)
  end

  def now do
    Process.get(:la_famiglia_now)
  end
end
