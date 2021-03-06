defmodule LaFamigliaWeb.AttackMovementController do
  use LaFamiglia.Web, :controller

  alias LaFamiglia.Villa
  alias LaFamiglia.AttackMovement

  def new(conn, %{"target_id" => target_id}) do
    target = Repo.get!(Villa, target_id)
    changeset = AttackMovement.create(conn.assigns.current_villa_changeset, target, default_units)

    conn
    |> assign(:changeset, changeset)
    |> assign(:target, target)
    |> render("new.html")
  end

  def create(conn, %{"attack_movement" => movement_params}) do
    movement_params =
      Map.merge(movement_params, default_units, fn
        _, v1, v2 when is_nil(v1) -> v2
        _, v1, _ -> v1
      end)

    target = Repo.get!(Villa, movement_params["target_id"])

    changeset =
      AttackMovement.create(conn.assigns.current_villa_changeset, target, movement_params)

    case Repo.insert(changeset) do
      {:error, changeset} ->
        conn
        |> assign(:changeset, changeset)
        |> assign(:target, target)
        |> render("new.html")

      {:ok, attack_movement} ->
        LaFamiglia.EventCallbacks.send_to_queue(attack_movement)

        conn
        |> redirect(to: Routes.villa_path(conn, :show, conn.assigns.current_villa.id))
    end
  end

  defp default_units do
    LaFamiglia.Unit.all()
    |> Map.new(fn u -> {Atom.to_string(u.key), 0} end)
  end
end
