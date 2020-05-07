defmodule LaFamiglia.Actions.Attack do
  alias Ecto.Multi

  def attack(changeset) do
    Multi.new
    |> Multi.insert(:attack_movement, changeset)
    |> Multi.run(:send_to_queue, fn(_repo, %{attack_movement: movement}) ->
      LaFamiglia.EventCallbacks.send_to_queue(movement)
    end)
  end
end
