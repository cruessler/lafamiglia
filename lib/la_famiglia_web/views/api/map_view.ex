defmodule LaFamigliaWeb.Api.MapView do
  use LaFamiglia.Web, :view

  def render("show.json", %{villas: villas}) do
    villas
  end
end
