defmodule LaFamiglia.MovementController do
  use LaFamiglia.Web, :controller

  alias LaFamiglia.AttackMovement
  alias LaFamiglia.ComebackMovement

  def index(conn, _params) do
    attacks   = Repo.all(AttackMovement) |> Repo.preload([:origin, :target])
    comebacks = Repo.all(ComebackMovement) |> Repo.preload([:origin, :target])

    render(conn, "index.html", attacks: attacks, comebacks: comebacks)
  end
end
