defmodule LaFamiglia.Actions.Cancel do
  alias Ecto.Multi

  alias LaFamiglia.AttackMovement

  def cancel(%AttackMovement{} = attack) do
    Multi.new
    |> Multi.delete(:attack, attack)
    |> Multi.insert(:comeback, AttackMovement.cancel(attack))
    |> Multi.run(:update_queue, fn(_repo, %{attack: attack, comeback: comeback}) ->
      LaFamiglia.EventCallbacks.drop_from_queue(attack)
      LaFamiglia.EventCallbacks.send_to_queue(comeback)
    end)
  end
end
