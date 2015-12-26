defmodule LaFamiglia.PlayerController do
  use LaFamiglia.Web, :controller

  alias LaFamiglia.Player

  @search_query_limit 10

  def new(conn, _params) do
    changeset = Player.changeset(%Player{})
    render conn, "new.html", changeset: changeset
  end

  def create(conn, %{"player" => player_params}) do
    changeset = Player.changeset(%Player{}, player_params)

    if changeset.valid? do
      Repo.insert(changeset)

      conn
      |> put_flash(:info, "Player created successfully.")
      |> redirect(to: page_path(conn, :index))
    else
      render(conn, "new.html", changeset: changeset)
    end
  end

  def search(conn, %{"query" => query}) do
    query = "%" <> query <> "%"

    players =
      from(p in Player,
        select: %{id: p.id, name: p.name},
        where: like(p.name, ^query),
        limit: @search_query_limit)
      |> Repo.all

    render(conn, :search, players: players)
  end
end
