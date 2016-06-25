defmodule LaFamiglia.Occupation do
  use LaFamiglia.Web, :model

  alias LaFamiglia.Repo
  alias LaFamiglia.Villa

  alias Ecto.Multi

  alias __MODULE__

  schema "occupations" do
    field :succeeds_at, Ecto.DateTime

    field :unit_1, :integer
    field :unit_2, :integer

    belongs_to :origin, Villa
    belongs_to :target, Villa

    timestamps
  end

  @duration_of_occupation 86_400 / Application.get_env(:la_famiglia, :game_speed)

  def from_combat(combat) do
    %{attack: attack, result: result} = combat

    succeeds_at = LaFamiglia.DateTime.from_now(@duration_of_occupation)

    changeset =
      %Occupation{}
      |> change(result.attacker_after_combat)
      |> put_assoc(:origin, attack.origin)
      |> put_assoc(:target, attack.target)
      |> put_change(:succeeds_at, succeeds_at)

    Multi.new
    |> Multi.insert(:occupation, changeset)
  end
end
