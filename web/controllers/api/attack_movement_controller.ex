defmodule LaFamiglia.Api.AttackMovementController do
  use LaFamiglia.Web, :controller

  alias LaFamiglia.Villa
  alias LaFamiglia.AttackMovement
  alias LaFamiglia.Actions.Attack

  def create(conn, %{"attack_movement" => movement_params}) do
    movement_params =
      Map.merge(movement_params, default_units, fn
        (_, v1, v2) when is_nil(v1) -> v2
        (_, v1, _) -> v1
      end)

    target    = Repo.get!(Villa, movement_params["target_id"])
    changeset = AttackMovement.create(conn.assigns.current_villa_changeset, target, movement_params)
    multi     = Attack.attack(changeset)

    case Repo.transaction(multi) do
      {:error, :attack_movement, changeset, _} ->
        conn
        |> put_status(:bad_request)
        |> render(LaFamiglia.ChangesetView, "error.json", changeset: changeset)
      {:ok, %{attack_movement: movement}} ->
        conn
        |> put_status(:created)
        |> render("create.json", movement: movement)
    end
  end

  defp default_units do
    LaFamiglia.Unit.all
    |> Map.new(fn(u) -> {Atom.to_string(u.key), 0} end)
  end
end
