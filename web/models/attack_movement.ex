defmodule LaFamiglia.AttackMovement do
  use LaFamiglia.Web, :model

  import LaFamiglia.Movement

  alias Ecto.Changeset

  alias LaFamiglia.Villa
  alias LaFamiglia.AttackMovement

  alias LaFamiglia.Unit
  alias LaFamiglia.ComebackMovement

  schema "attack_movements" do
    belongs_to :origin, Villa
    belongs_to :target, Villa

    field :unit_1, :integer
    field :unit_2, :integer

    field :arrives_at, :utc_datetime

    timestamps
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:unit_1, :unit_2])
    |> validate_required([:unit_1, :unit_2])
  end

  def create(origin_changeset, target, params) do
    movement =
      %AttackMovement{}
      |> changeset(params)

    origin_changeset =
      Villa.order_units_changeset(origin_changeset, Unit.filter(movement))

    movement
    |> put_assoc(:origin, origin_changeset)
    |> put_assoc(:target, target)
    |> validate_origin_and_target_belong_to_different_players
    |> validate_at_least_one_unit
    |> assoc_constraint(:origin)
    |> assoc_constraint(:target)
    |> calculate_arrives_at
  end

  def cancel(attack) do
    ComebackMovement.from_attack(attack)
  end

  defp validate_origin_and_target_belong_to_different_players(changeset) do
    origin = get_field(changeset, :origin)
    target = get_field(changeset, :target)

    cond do
      origin == target ->
        add_error(changeset, :target, "must not be owned by you")
      true ->
        changeset
    end
  end

  defp validate_at_least_one_unit(%Changeset{changes: changes} = changeset) do
    cond do
      unit_number_given?(changeset) ->
        total_unit_number =
          LaFamiglia.Unit.all
          |> Enum.reduce(0, fn(u, acc) -> acc + (changes[u.key] || 0) end)

        case total_unit_number == 0 do
          true -> add_error(changeset, :unit_count, "You have to select at least 1 unit.")
          _    -> changeset
        end
      true -> changeset
    end
  end

  defp unit_number_given?(%Changeset{changes: changes}) do
    Enum.any? LaFamiglia.Unit.all, fn(u) ->
      Map.has_key?(changes, u.key)
    end
  end

  defp calculate_arrives_at(%{valid?: false} = changeset) do
    changeset
  end
  defp calculate_arrives_at(changeset) do
    %{changes: changes} = changeset

    origin = get_field(changeset, :origin)
    target = get_field(changeset, :target)

    duration = duration(origin, target, units(changes))

    arrives_at = LaFamiglia.DateTime.from_now(duration)
    put_change(changeset, :arrives_at, arrives_at)
  end
end
