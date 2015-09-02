defmodule LaFamiglia.Queue do
  def completed_at([]) do
    LaFamiglia.DateTime.now
  end
  def completed_at(queue) when is_list(queue) do
    List.last(queue).completed_at
  end
end
