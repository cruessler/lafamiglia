defmodule LaFamigliaWeb.Api.PlayerController do
  use LaFamiglia.Web, :controller

  alias LaFamiglia.Player

  @search_query_limit 10

  def search(conn, %{"query" => query}) do
    query_start = query <> "%"
    query_in = "%" <> query <> "%"

    players =
      from(p in Player,
        select: %{id: p.id, name: p.name},
        where: ilike(p.name, ^query_start) or ilike(p.name, ^query_in),
        limit: @search_query_limit
      )
      |> Repo.all()

    render(conn, :search, players: players)
  end
end
