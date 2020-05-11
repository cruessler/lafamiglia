defmodule LaFamiglia.Session do
  alias LaFamiglia.Repo
  alias LaFamiglia.Player

  def login(params) do
    player = Repo.get_by(Player, email: String.downcase(params["email"]))

    case authenticate(player, params["password"]) do
      true -> {:ok, player}
      _ -> :error
    end
  end

  defp authenticate(player, password) do
    case player do
      nil -> false
      _ -> Bcrypt.verify_pass(password, player.hashed_password)
    end
  end
end
