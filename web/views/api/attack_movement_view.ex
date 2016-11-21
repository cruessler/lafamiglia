defmodule LaFamiglia.Api.AttackMovementView do
  use LaFamiglia.Web, :view

  def render("create.json", %{movement: movement}) do
    %{attack_movement: %{id: movement.id}}
  end
end
