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
end
