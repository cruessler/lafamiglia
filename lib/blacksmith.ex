defmodule Blacksmith.Config do
  def save(repo, model) do
    model |> repo.insert!
  end

  def save_all(repo, list) do
    Enum.map(list, &repo.insert!/1)
  end
end
