defmodule LaFamiglia.Plugs.VillaProcessor do
  import Plug.Conn

  alias LaFamiglia.Villa

  def init(default), do: default

  def call(conn, _default) do
    conn
    |> process_villa
  end

  defp process_villa(%Plug.Conn{assigns: %{current_villa: villa}} = conn) do
    changeset =
      Ecto.Changeset.change(villa)
      |> Villa.process_virtually_until(LaFamiglia.DateTime.now)

    conn
    |> assign(:current_villa_changeset, changeset)
    |> assign(:current_villa, Ecto.Changeset.apply_changes(changeset))
  end
end
