defmodule LaFamiglia.Unit do
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

  def number(villa, unit) do
    Map.get(villa, unit.key)
  end

  def enqueued_number(villa, unit) do
    villa.unit_queue_items
    |> Enum.reduce 0, fn(item, acc) ->
      if item.unit_id == unit.id do
        acc + item.number
      else
        acc
      end
    end
  end

  def virtual_number(villa, unit) do
    number(villa, unit) + enqueued_number(villa, unit)
  end
end
