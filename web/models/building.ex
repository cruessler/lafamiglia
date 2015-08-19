defmodule Building do
  def get_by_id(id) do
    {_k, b} = Enum.find Application.get_env(:la_famiglia, :buildings), fn({_k, b}) ->
      b.id == id
    end
    b
  end

  def level(villa, building) do
    Map.get(villa, building.key)
  end
end
