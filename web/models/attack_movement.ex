defmodule LaFamiglia.AttackMovement do
  use LaFamiglia.Web, :model

  import LaFamiglia.Movement

  alias Ecto.Changeset
  alias Ecto.Multi

  alias LaFamiglia.Repo
  alias LaFamiglia.Villa
  alias LaFamiglia.AttackMovement

  alias LaFamiglia.Unit
  alias LaFamiglia.ComebackMovement

  schema "attack_movements" do
    belongs_to :origin, Villa
    belongs_to :target, Villa

    field :unit_1, :integer
    field :unit_2, :integer

    field :arrives_at, Ecto.DateTime

    timestamps
  end

  @required_fields ~w(unit_1 unit_2)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_origin_and_target_belong_to_different_players
    |> validate_at_least_one_unit
    |> assoc_constraint(:origin)
    |> assoc_constraint(:target)
    |> calculate_arrives_at
  end

  def create(origin_changeset, target, params) do
    movement =
      %AttackMovement{}
      |> cast(params, @required_fields, @optional_fields)

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

  def attack(changeset) do
    Multi.new
    |> Multi.insert(:attack_movement, changeset)
    |> Multi.run(:send_to_queue, fn(%{attack_movement: movement}) ->
      LaFamiglia.EventCallbacks.send_to_queue(movement)
    end)
  end

  def cancel(attack) do
    changeset = ComebackMovement.from_attack(attack)

    Multi.new
    |> Multi.delete(:attack, attack)
    |> Multi.insert(:comeback, changeset)
    |> Multi.run(:update_queue, fn(%{attack: attack, comeback: comeback}) ->
      LaFamiglia.EventCallbacks.drop_from_queue(attack)
      LaFamiglia.EventCallbacks.send_to_queue(comeback)
    end)
  end

  defp validate_origin_and_target_belong_to_different_players(changeset) do
    origin = get_field(changeset, :origin)
    target = get_field(changeset, :target)

    cond do
      origin.player_id == target.player_id ->
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
          |> Enum.reduce(0, fn({k, _u}, acc) -> acc + (changes[k] || 0) end)

        case total_unit_number == 0 do
          true -> add_error(changeset, :unit_count, "You have to select at least 1 unit.")
          _    -> changeset
        end
      true -> changeset
    end
  end

  defp unit_number_given?(%Changeset{changes: changes}) do
    Enum.any? changes, fn({k, _v}) ->
      Dict.has_key?(LaFamiglia.Unit.all, k)
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
