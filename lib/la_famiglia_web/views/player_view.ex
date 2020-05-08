defmodule LaFamigliaWeb.PlayerView do
  use LaFamiglia.Web, :view

  def render("search.json", %{players: players}) do
    players
  end
end
