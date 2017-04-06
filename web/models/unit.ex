defmodule LaFamiglia.Unit do
  import Ecto.Changeset
  alias Ecto.Changeset

  alias LaFamiglia.Mechanics

  alias LaFamiglia.Villa

  @game_speed Application.get_env(:la_famiglia, :game_speed)

  defstruct [
    :id, :key, :build_time, :costs, :supply,
    :speed, :attack, :defense, :load
  ]

  def all, do: Mechanics.Units.units

  def get(id) when is_integer(id),
    do: Enum.find(all, fn(u) -> u.id == id end)
  def get(key) when is_atom(key),
    do: Enum.find(all, fn(u) -> u.key == key end)

  def number(%Changeset{} = changeset, unit),
    do: get_field(changeset, unit.key)
  def number(map, unit),
    do: Map.get(map, unit.key)

  def enqueued_number(%Changeset{} = changeset, unit),
    do: enqueued_number(get_field(changeset, :unit_queue_items), unit)
  def enqueued_number(%Villa{} = villa, unit),
    do: enqueued_number(villa.unit_queue_items, unit)

  def enqueued_number([], _), do: 0
  def enqueued_number([first|rest], unit) do
    case first.unit_id == unit.id do
      true -> first.number + enqueued_number(rest, unit)
      _    -> enqueued_number(rest, unit)
    end
  end

  def virtual_number(map, unit),
    do: number(map, unit) + enqueued_number(map, unit)

  def filter(%Changeset{} = changeset),
    do: for u <- all, into: %{}, do: {u.key, get_field(changeset, u.key)}
  def filter(map),
    do: for u <- all, into: %{}, do: {u.key, Map.get(map, u.key)}

  def supply(map), do: supply(map, all)

  def supply(_, []), do: 0
  def supply(map, [unit|rest]),
    do: Map.get(map, unit.key) * unit.supply + supply(map, rest)

  def subtract(map1, map2),
    do: Map.merge map1, map2, fn(_k, v1, v2) -> v1 - v2 end

  def multiply(map, percentage),
    do: for {k, _} <- map, into: %{}, do: {k, round(Map.get(map, k) * percentage)}

  def build_time(unit, number \\ 1),
    do: trunc(number * unit.build_time / @game_speed)
end
