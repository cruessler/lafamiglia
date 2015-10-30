defmodule LaFamiglia.MovementController do
  use LaFamiglia.Web, :controller

  alias Ecto.Changeset

  alias LaFamiglia.AttackMovement
  alias LaFamiglia.ComebackMovement

  def index(conn, _params) do
    attacks   = Repo.all(AttackMovement) |> Repo.preload([:origin, :target])
    comebacks = Repo.all(ComebackMovement) |> Repo.preload([:origin, :target])

    conn
    |> assign(:current_villa, Changeset.apply_changes(conn.assigns.current_villa_changeset))
    |> render("index.html", attacks: attacks, comebacks: comebacks)
  end
end
