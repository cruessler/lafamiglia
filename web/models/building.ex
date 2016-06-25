defmodule LaFamiglia.Building do
  import Ecto.Changeset
  alias Ecto.Changeset

  alias LaFamiglia.Villa

  @game_speed Application.get_env(:la_famiglia, :game_speed)

  def all do
    Application.get_env(:la_famiglia, :buildings)
  end

  def get(id) when is_integer(id) do
    Enum.find(all, fn(b) -> b.id == id end)
  end
  def get(key) when is_atom(key) do
    Enum.find(all, fn(b) -> b.key == key end)
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
    building.build_time.(level) / @game_speed
  end
end
