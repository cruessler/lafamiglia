defmodule LaFamiglia.DateTime do
  def to_seconds %Ecto.DateTime{} = datetime do
    datetime
    |> Ecto.DateTime.to_erl
    |> :calendar.datetime_to_gregorian_seconds
  end

  def to_msecs %Ecto.DateTime{usec: usecs} = datetime do
    datetime
    |> to_seconds
    |> +(usecs / 1000)
  end

  def add_seconds(%Ecto.DateTime{usec: usecs} = datetime, seconds) do
    new_seconds =
      datetime
      |> to_seconds
      |> +(seconds)

    new_datetime =
      new_seconds
      |> :calendar.gregorian_seconds_to_datetime
      |> Ecto.DateTime.from_erl

    %Ecto.DateTime{new_datetime | usec: usecs}
  end
end
