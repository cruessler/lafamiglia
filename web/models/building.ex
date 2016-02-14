defmodule LaFamiglia.Building do
  import Ecto.Changeset
  alias Ecto.Changeset

  alias LaFamiglia.Villa

  def all do
    Application.get_env(:la_famiglia, :buildings)
  end

  def get_by_id(id) do
    case all |> Enum.find(fn({_k, b}) -> b.id == id end)
    do
      {_k, b} -> b
      _       -> nil
    end
  end

  def level(%Changeset{} = changeset, building) do
    get_field(changeset, building.key)
  end
  def level(%Villa{} = villa, building) do
    Map.get(villa, building.key)
  end

  def virtual_level(%Changeset{} = changeset, building) do
    level(changeset, building) +
      enqueued_count(get_field(changeset, :building_queue_items), building)
  end
  def virtual_level(%Villa{} = villa, building) do
    level(villa, building) +
      enqueued_count(villa.building_queue_items, building)
  end

  defp enqueued_count(queue, building) do
    Enum.count queue, fn(item) ->
      item.building_id == building.id
    end
  end

  def build_time(building, level) do
    building.build_time.(level) / Application.get_env(:la_famiglia, :game_speed)
  end
end
