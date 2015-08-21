defmodule LaFamiglia.DateTime do
  def to_seconds %Ecto.DateTime{usec: usecs} = datetime do
    datetime
    |> Ecto.DateTime.to_erl
    |> :calendar.datetime_to_gregorian_seconds
    |> +(usecs / 1000)
  end

  def add_seconds(%Ecto.DateTime{usec: usecs} = datetime, seconds) do
    new_seconds =
      datetime
      |> Ecto.DateTime.to_erl
      |> :calendar.datetime_to_gregorian_seconds
      |> +(seconds)

    new_datetime =
      new_seconds
      |> :calendar.gregorian_seconds_to_datetime
      |> Ecto.DateTime.from_erl

    %Ecto.DateTime{new_datetime | usec: usecs}
  end
end
