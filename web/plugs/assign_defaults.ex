defmodule LaFamiglia.Plugs.AssignDefaults do
  import Plug.Conn
  import Phoenix.Controller

  def init(_params), do: _params

  def call(conn, _params) do
    conn
    |> assign_defaults
  end

  defp assign_defaults(conn) do
    # Setting these variables to nil enables checking for existence via
    # `@current_player` in templates. If the variables would not be set, an
    # error would be thrown.
    conn
    |> assign(:current_player, nil)
    |> assign(:current_villa, nil)
  end
end
