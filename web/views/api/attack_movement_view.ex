defmodule LaFamiglia.Api.AttackMovementView do
  use LaFamiglia.Web, :view

  def render("create.json", %{movement: movement}) do
    movement
  end
end
