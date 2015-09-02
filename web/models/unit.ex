defmodule LaFamiglia.Unit do
  alias LaFamiglia.Repo

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
    Ecto.Model.assoc(villa, :unit_queue_items)
    |> Repo.all
    |> Enum.reduce(0, fn(item, acc) ->
      cond do
        item.unit_id == unit.id -> acc + item.number
        true -> acc
      end
    end)
  end
end
