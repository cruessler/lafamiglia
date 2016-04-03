defmodule LaFamiglia.ComebackMovement do
  use LaFamiglia.Web, :model

  import LaFamiglia.Movement

  alias LaFamiglia.Repo
  alias LaFamiglia.Villa
  alias LaFamiglia.ComebackMovement

  alias LaFamiglia.Unit

  schema "comeback_movements" do
    belongs_to :origin, Villa
    belongs_to :target, Villa

    field :unit_1, :integer
    field :unit_2, :integer

    field :resource_1, :integer
    field :resource_2, :integer
    field :resource_3, :integer

    field :arrives_at, Ecto.DateTime

    timestamps
  end

  @required_fields ~w(unit_1 unit_2)
  @optional_fields ~w(resource_1 resource_2 resource_3)

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end

  @doc """
  This function creates a ComebackMovement.

  It does so by applying the `result` of a combat to an AttackMovement.
  It assumes that at least one attacking unit has survived the attack.
  """
  def from_combat(attack, result) do
    duration_of_return = duration(attack.origin, attack.target, units(result.attacker_after_combat))
    new_arrives_at = LaFamiglia.DateTime.from_now(duration_of_return)

    %ComebackMovement{}
    |> changeset(result.attacker_after_combat)
    |> put_assoc(:origin, attack.origin)
    |> put_assoc(:target, attack.target)
    |> put_change(:arrives_at, new_arrives_at)
  end

  def arrive!(comeback) do
    Repo.transaction fn ->
      comeback = Repo.preload(comeback, :origin)

      change(comeback.origin)
      |> Villa.add_units(Unit.filter(comeback))
      |> Repo.update!

      Repo.delete(comeback)
    end
  end
end
