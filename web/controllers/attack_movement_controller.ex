defmodule LaFamiglia.AttackMovementController do
  use LaFamiglia.Web, :controller

  alias LaFamiglia.Villa
  alias LaFamiglia.AttackMovement

  plug :scrub_params, "attack_movement" when action in [:create]

  def new(conn, %{"target_id" => target_id}) do
    # To make `target_id` and `target` available in the template, both are set
    # on the model.
    target    = Repo.get!(Villa, target_id)
    movement  = %AttackMovement{target_id: target_id, target: target}
    changeset = AttackMovement.changeset(movement)

    conn
    |> assign(:changeset, changeset)
    |> render("new.html")
  end

  def create(conn, %{"attack_movement" => movement_params}) do
    # To make validations check unit numbers, a map with all unit numbers
    # set to 0 is merged into `movement_params`.
    units =
      LaFamiglia.Unit.all
      |> Enum.map(fn({k, _u}) -> {Atom.to_string(k), 0} end)
      |> Enum.into(%{})

    movement_params =
      movement_params
      |> Map.put("origin_id", conn.assigns.current_villa.id)
      |> Map.merge units, fn
        (_k, v1, v2) when is_nil(v1) -> v2
        (_, v1, _) -> v1
      end

    target    = Repo.get(Villa, movement_params["target_id"])
    movement  = %AttackMovement{target: target}
    changeset = AttackMovement.changeset(movement, movement_params)

    case Repo.insert(changeset) do
      {:error, changeset} ->
        conn
        |> assign(:changeset, changeset)
        |> render("new.html")
      {:ok, movement} ->
        LaFamiglia.EventQueue.cast({:new_event, movement})

        conn
        |> redirect(to: villa_path(conn, :show, conn.assigns.current_villa.id))
    end
  end
end
