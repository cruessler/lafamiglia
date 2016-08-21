defmodule LaFamiglia.ComebackMovement do
  use LaFamiglia.Web, :model

  import LaFamiglia.Movement

  alias Ecto.Multi

  alias LaFamiglia.Repo
  alias LaFamiglia.Villa
  alias LaFamiglia.ComebackMovement

  alias LaFamiglia.Unit

  schema "comeback_movements" do
    belongs_to :origin, Villa
    belongs_to :target, Villa

    field :unit_1, :integer
    field :unit_2, :integer

    field :resource_1, :integer, default: 0
    field :resource_2, :integer, default: 0
    field :resource_3, :integer, default: 0

    field :arrives_at, Ecto.DateTime

    timestamps
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:unit_1, :unit_2, :resource_1, :resource_2, :resource_3])
    |> validate_required([:unit_1, :unit_2])
  end

  @doc """
  This function creates a ComebackMovement.

  It does so by applying the `result` of a combat to an AttackMovement.
  It assumes that at least one attacking unit has survived the attack.
  """
  def from_combat(attack, result) do
    duration_of_return = duration(attack.origin, attack.target, units(result.attacker_after_combat))
    new_arrives_at = LaFamiglia.DateTime.from_now(duration_of_return)

    params =
      result.attacker_after_combat
      |> Map.merge(result.resources_plundered)

    %ComebackMovement{}
    |> changeset(params)
    |> put_assoc(:origin, attack.origin)
    |> put_assoc(:target, attack.target)
    |> put_change(:arrives_at, new_arrives_at)
  end

  @doc """
  This function creates a ComebackMovement.

  It is used when a user cancels an attack before it arrives at its target.
  """
  def from_attack(attack) do
    attack = Repo.preload(attack, [:origin, :target])

    time_remaining = LaFamiglia.DateTime.time_diff(attack.arrives_at, LaFamiglia.DateTime.now)
    duration_of_return = duration(attack.origin, attack.target, units(attack)) - time_remaining
    new_arrives_at = LaFamiglia.DateTime.from_now(duration_of_return)

    # The new ComebackMovement is identical to `attack` except for `arrives_at`.
    %ComebackMovement{}
    |> changeset(Unit.filter(attack))
    |> put_assoc(:origin, attack.origin)
    |> put_assoc(:target, attack.target)
    |> put_change(:arrives_at, new_arrives_at)
  end

  @doc """
  This function creates a ComebackMovement.

  It is used when an occupation succeeds and the occupying units return.
  """
  def from_occupation(occupation) do
    duration_of_return = duration(occupation.origin, occupation.target, units(occupation))
    arrives_at = LaFamiglia.DateTime.from_now(duration_of_return)

    %ComebackMovement{}
    |> changeset(Unit.filter(occupation))
    |> put_assoc(:origin, occupation.origin)
    |> put_assoc(:target, occupation.target)
    |> put_change(:arrives_at, arrives_at)
  end

  def arrive(comeback) do
    comeback = Repo.preload(comeback, :origin)

    origin_changeset =
      change(comeback.origin)
      |> Villa.add_units(comeback)
      |> Villa.add_resources(comeback)

    Multi.new
    |> Multi.update(:origin, origin_changeset)
    |> Multi.delete(:comeback, comeback)
  end
end
