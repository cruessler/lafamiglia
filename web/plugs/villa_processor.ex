defmodule LaFamiglia.Plugs.VillaProcessor do
  import Plug.Conn

  alias LaFamiglia.Villa

  def init(default), do: default

  def call(conn, _default) do
    conn
    |> process_villa
  end

  defp process_villa(%Plug.Conn{assigns: %{current_villa: villa}} = conn) do
    processed_villa =
      villa
      |> Villa.process_virtually_until(LaFamiglia.DateTime.now)
      |> Ecto.Changeset.apply_changes
    assign(conn, :current_villa, processed_villa)
  end
end
