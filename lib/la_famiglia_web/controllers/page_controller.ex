defmodule LaFamigliaWeb.PageController do
  use LaFamiglia.Web, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
