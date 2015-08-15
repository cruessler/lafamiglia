defmodule LaFamiglia.Plugs.VillaProcessor do
  import Plug.Conn

  use Ecto.Model

  alias LaFamiglia.Villa

  def init(default), do: default

  def call(conn, _default) do
    conn
    |> process_villa
  end

  defp process_villa(%Plug.Conn{assigns: %{current_villa: villa}} = conn) do
    assign(conn, :current_villa, Villa.process_virtually_until(villa, Ecto.DateTime.local))
  end
end
