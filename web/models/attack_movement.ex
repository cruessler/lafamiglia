defmodule LaFamiglia.AttackMovement do
  use LaFamiglia.Web, :model

  import LaFamiglia.Movement

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
  after_insert LaFamiglia.EventCallbacks, :after_insert

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
    |> validate_origin_and_target_belong_to_different_players
    |> validate_at_least_one_unit
    |> assoc_constraint(:origin)
    |> assoc_constraint(:target)
  end

  def attack(%{model: villa} = changeset, attack) do
    villa     = Repo.preload(villa, :attack_movements)
    changeset = %Changeset{changeset | model: villa}

    changeset
    |> Villa.order_units_changeset(attack, Unit.filter(attack))
  end

  def cancel!(attack) do
    attack = Repo.preload(attack, [:origin, :target])

    time_remaining = LaFamiglia.DateTime.time_diff(attack.arrives_at, LaFamiglia.DateTime.now)
    duration_of_return = duration(attack.origin, attack.target, units(attack)) - time_remaining
    new_arrives_at = LaFamiglia.DateTime.from_now(duration_of_return)

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

  defp validate_origin_and_target_belong_to_different_players(changeset) do
    origin = Repo.get!(Villa, get_field(changeset, :origin_id))
    target = Repo.get!(Villa, get_field(changeset, :target_id))

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

    arrives_at = LaFamiglia.DateTime.from_now(duration)
    put_change(changeset, :arrives_at, arrives_at)
  end
end
