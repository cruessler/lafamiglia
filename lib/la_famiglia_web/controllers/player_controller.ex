defmodule LaFamigliaWeb.PlayerController do
  use LaFamiglia.Web, :controller

  alias LaFamiglia.Player

  def new(conn, _params) do
    changeset = Player.changeset(%Player{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"player" => player_params}) do
    changeset = Player.changeset(%Player{}, player_params)

    case Repo.insert(changeset) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Player created successfully.")
        |> redirect(to: Routes.page_path(conn, :index))

      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def index(conn, _params) do
    players =
      from(p in Player,
        left_join: v in assoc(p, :villas),
        group_by: p.id,
        order_by: [desc: [p.points, count(v.id)], asc: p.id],
        select: %{name: p.name, points: p.points, villa_count: count(v.id)}
      )
      |> Repo.all()

    conn
    |> assign(:players, players)
    |> render("index.html")
  end
end
