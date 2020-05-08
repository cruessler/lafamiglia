defmodule LaFamigliaWeb.Plugs.Timer do
  def init(default), do: default

  def call(conn, _default) do
    LaFamiglia.DateTime.clock!()
    conn
  end
end
