defmodule Building do
  alias LaFamiglia.Repo

  def get_by_id(id) do
    {_k, b} = Enum.find Application.get_env(:la_famiglia, :buildings), fn({_k, b}) ->
      b.id == id
    end
    b
  end

  def level(villa, building) do
    Map.get(villa, building.key)
  end

  def virtual_level(villa, building) do
    level(villa, building) + enqueued_count(villa, building)
  end

  defp enqueued_count(villa, building) do
    Ecto.Model.assoc(villa, :building_queue_items)
    |> Repo.all
    |> Enum.count fn(item) ->
      item.building_id == building.id
    end
  end
end
