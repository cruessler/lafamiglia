defmodule LaFamiglia.AttackMovement do
  use LaFamiglia.Web, :model

  alias Ecto.Changeset

  alias LaFamiglia.Repo
  alias LaFamiglia.Villa

  alias LaFamiglia.Unit

  schema "attack_movements" do
    belongs_to :origin, Villa
    belongs_to :target, Villa

    field :unit_1, :integer
    field :unit_2, :integer

    field :arrives_at, Ecto.DateTime

    timestamps
  end

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
    |> assoc_constraint(:origin)
    |> assoc_constraint(:target)
  end

  defp validate_origin_and_target_are_different(changeset) do
    case changeset.changes.origin_id == changeset.changes.target_id do
      true -> add_error(changeset, :target_id, "must be different from origin")
      _    -> changeset
    end
  end

  # So far, there seems to be no standard way of validating fields of associated
  # models. This is a hack to make `origin` and `target` available to the
  # validations.
  defp preload_associations(%Changeset{changes: changes, model: model} = changeset) do
    model =
      model
      |> Map.put(:origin, Repo.get!(Villa, changes.origin_id))
      |> Map.put(:target, Repo.get!(Villa, changes.target_id))
    %Changeset{changeset | model: model}
  end

  defp validate_origin_and_target_belong_to_different_players(changeset) do
    case get_field(changeset, :origin).player_id == get_field(changeset, :target).player_id do
      true -> add_error(changeset, :target_id, "must not be owned by you")
      _    -> changeset
    end
  end

  defp validate_unit_numbers(changeset) do
    origin = get_field(changeset, :origin)

    LaFamiglia.Unit.all
    |> Enum.reduce changeset, fn({k, u}, changeset) ->
      changeset
      |> validate_number(k, less_than_or_equal_to: Unit.number(origin, u))
    end
  end

  defp validate_at_least_one_unit(%Changeset{changes: changes} = changeset) do
    total_unit_number =
      LaFamiglia.Unit.all
      |> Enum.reduce 0, fn({k, _u}, acc) -> acc + changes[k] end

    case total_unit_number == 0 do
      true -> add_error(changeset, :unit_count, "must be greater than 0")
      _    -> changeset
    end
  end
end
