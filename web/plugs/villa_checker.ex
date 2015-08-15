defmodule LaFamiglia.Plugs.VillaChecker do
  import Phoenix.Controller

  def init(error_page_path), do: error_page_path

  def call(conn, error_page_path) do
    conn
    |> check_for_villa(error_page_path)
  end

  defp check_for_villa(conn, error_page_path) do
    case conn.assigns[:current_villa] do
      nil ->
        conn
        |> put_flash(:error, "There is no villa left for you.")
        |> redirect(to: error_page_path)
      _ -> conn
    end
  end
end
