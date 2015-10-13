defmodule LaFamiglia.AttackMovement do
  use LaFamiglia.Web, :model

  alias Ecto.Changeset

  alias LaFamiglia.Repo
  alias LaFamiglia.Villa

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

  before_insert :calculate_arrives_at

  @required_fields ~w(origin_id target_id unit_1 unit_2)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_origin_and_target_are_different
    |> preload_associations
    |> validate_origin_and_target_belong_to_different_players
    |> validate_unit_numbers
    |> validate_at_least_one_unit
    |> remove_associations
    |> assoc_constraint(:origin)
    |> assoc_constraint(:target)
  end

  def cancel!(attack) do
    attack = Repo.preload(attack, [:origin, :target])

    time_remaining = LaFamiglia.DateTime.time_diff(attack.arrives_at, LaFamiglia.DateTime.now)
    duration_of_return = duration(attack.origin, attack.target, units(attack)) - time_remaining
    new_arrives_at = LaFamiglia.DateTime.add_seconds(LaFamiglia.DateTime.now, duration_of_return)

    # The new ComebackMovement is identical to `attack` except for `arrives_at`.
    params =
      Map.from_struct(attack)
      |> Map.put(:arrives_at, new_arrives_at)

    changeset = ComebackMovement.changeset(%ComebackMovement{}, params)

    Repo.transaction fn ->
      Repo.delete(attack)
      Repo.insert!(changeset)
    end
  end

  defp validate_origin_and_target_are_different(changeset) do
    validate_change changeset, :origin_id, fn _field, value ->
      case get_change(changeset, :target_id) do
        ^value -> [{:target, "must not be the origin"}]
        _      -> []
      end
    end
  end

  # So far, there seems to be no standard way of validating fields of associated
  # models. This is a hack to make `origin` and `target` available to the
  # validations.
  defp preload_associations(changeset) do
    case changeset.changes do
      %{origin_id: origin_id, target_id: target_id} ->
        changeset
        |> put_change(:origin, Repo.get(Villa, origin_id))
        |> put_change(:target, Repo.get(Villa, target_id))
      _ ->
        changeset
    end
  end

  defp remove_associations(%Changeset{changes: changes} = changeset) do
    %Changeset{changeset | changes: Map.drop(changes, [:origin, :target])}
  end

  defp validate_origin_and_target_belong_to_different_players(changeset) do
    case changeset.changes do
      %{origin: origin, target: target} ->
        cond do
          origin.player_id == target.player_id ->
            add_error(changeset, :target, "must not be owned by you")
          true ->
            changeset
        end
      _ -> changeset
    end
  end

  defp validate_unit_numbers(changeset) do
    case changeset.changes do
      %{origin: origin} ->
        Enum.reduce LaFamiglia.Unit.all, changeset, fn({k, u}, changeset) ->
          changeset
          |> validate_number(k, less_than_or_equal_to: Unit.number(origin, u))
        end
      _ -> changeset
    end
  end

  defp validate_at_least_one_unit(%Changeset{changes: changes} = changeset) do
    cond do
      unit_number_given?(changeset) ->
        total_unit_number =
          LaFamiglia.Unit.all
          |> Enum.reduce 0, fn({k, _u}, acc) -> acc + (changes[k] || 0) end

        case total_unit_number == 0 do
          true -> add_error(changeset, :unit_count, "must be greater than 0")
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

  defp calculate_arrives_at(changeset) do
    %{changes: changes} = changeset

    origin = Repo.get(Villa, changes.origin_id)
    target = Repo.get(Villa, changes.target_id)

    duration = duration(origin, target, units(changes))

    arrives_at = LaFamiglia.DateTime.add_seconds(LaFamiglia.DateTime.now, duration)
    put_change(changeset, :arrives_at, arrives_at)
  end

  defp units(movement) do
    Enum.filter LaFamiglia.Unit.all, fn({_k, u}) -> LaFamiglia.Unit.number(movement, u) > 0 end
  end

  defp duration(origin, target, units) do
    distance_between(origin, target) / speed(units)
  end

  defp distance_between(origin, target) do
    :math.sqrt(:math.pow(origin.x - target.x, 2) + :math.pow(origin.y - target.y, 2))
  end

  defp speed(units) do
    Enum.map(units, fn({_k, u}) -> u.speed end)
    |> Enum.min
  end
end
