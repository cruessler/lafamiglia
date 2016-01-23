defmodule LaFamiglia.Unit do
  import Ecto.Changeset
  alias Ecto.Changeset

  alias LaFamiglia.Villa

  def all do
    Application.get_env(:la_famiglia, :units)
  end

  def get_by_id(id) do
    case Application.get_env(:la_famiglia, :units)
         |> Enum.find(fn({_k, b}) -> b.id == id end)
    do
      {_k, b} -> b
      _       -> nil
    end
  end

  def number(%Changeset{} = changeset, unit) do
    get_field(changeset, unit.key)
  end
  def number(map, unit) do
    Map.get(map, unit.key)
  end

  def enqueued_number(%Changeset{} = changeset, unit) do
    enqueued_number(get_field(changeset, :unit_queue_items), unit)
  end
  def enqueued_number(%Villa{} = villa, unit) do
    enqueued_number(villa.unit_queue_items, unit)
  end

  def enqueued_number(queue, unit) when is_list(queue) do
    Enum.reduce queue, 0, fn(item, acc) ->
      if item.unit_id == unit.id do
        acc + item.number
      else
        acc
      end
    end
  end

  def virtual_number(map, unit) do
    number(map, unit) + enqueued_number(map, unit)
  end

  def filter(%Changeset{} = changeset) do
    Enum.reduce all, %{}, fn({k, _}, map) ->
      Map.put(map, k, get_field(changeset, k))
    end
  end
  def filter(map) do
    all
    |> Map.new(fn({k, _u}) -> {k, Map.get(map, k)} end)
  end

  def supply(map) do
    Enum.reduce all, 0, fn({k, u}, acc) ->
      acc + Map.get(map, k) * u.supply
    end
  end

  def subtract(map1, map2) do
    Map.merge map1, map2, fn(_k, v1, v2) ->
      v1 - v2
    end
  end

  def multiply(map, percentage) do
    Map.new map, fn({k, _u}) ->
      {k, round(Map.get(map, k) * percentage)}
    end
  end

  def build_time(unit, number \\ 1) do
    number * unit.build_time / Application.get_env(:la_famiglia, :game_speed)
  end
end
