defmodule LaFamiglia.AttackMovementController do
  use LaFamiglia.Web, :controller

  alias LaFamiglia.Villa
  alias LaFamiglia.AttackMovement

  def new(conn, %{"target_id" => target_id}) do
    # To make `target_id` and `target` available in the template, both are set
    # on the model.
    target    = Repo.get!(Villa, target_id)
    movement  = %AttackMovement{target_id: target_id, target: target}
    movement_params = Map.merge(%{"origin_id" => conn.assigns.current_villa.id,
                                  "target_id" => target_id}, default_units)

    attack_changeset = AttackMovement.changeset(movement, movement_params)
    changeset        = AttackMovement.attack(conn.assigns.current_villa_changeset, attack_changeset)

    conn
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  # FIXME: As soon as ecto supports belongs_to associations in changesets,
  # the hierarchy of changesets can be reversed for increased elegance.
  # scrub_params can be reintroduced then.
  def create(conn, %{"villa" => %{"attack_movements" => %{"0" => movement_params}}}) do
    movement_params =
      movement_params
      |> Map.put("origin_id", conn.assigns.current_villa.id)
      |> Map.merge(default_units, fn
        (_, v1, v2) when is_nil(v1) -> v2
        (_, v1, _) -> v1
      end)

    target   = Repo.get!(Villa, movement_params["target_id"])
    movement = %AttackMovement{target: target}

    attack_changeset = AttackMovement.changeset(movement, movement_params)
    changeset        = AttackMovement.attack(conn.assigns.current_villa_changeset, attack_changeset)

    case Repo.update(changeset) do
      {:error, changeset} ->
        conn
        |> assign(:changeset, changeset)
        |> render("new.html")
      {:ok, _movement} ->
        conn
        |> redirect(to: villa_path(conn, :show, conn.assigns.current_villa.id))
    end
  end

  defp default_units do
    units =
      LaFamiglia.Unit.all
      |> Enum.map(fn({k, _u}) -> {Atom.to_string(k), 0} end)
      |> Enum.into(%{})
  end
end
