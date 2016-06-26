defmodule LaFamiglia.Villa do
  use LaFamiglia.Web, :model

  alias LaFamiglia.Building
  alias LaFamiglia.Unit

  alias LaFamiglia.Repo
  alias LaFamiglia.Player
  alias LaFamiglia.Villa
  alias LaFamiglia.BuildingQueueItem
  alias LaFamiglia.UnitQueueItem
  alias LaFamiglia.{AttackMovement, Occupation}
  alias LaFamiglia.Report
  alias LaFamiglia.RelatedReportVilla

  alias Ecto.Changeset

  import Ecto.Query, only: [ from: 2 ]

  schema "villas" do
    field :name, :string
    field :x, :integer
    field :y, :integer

    field :is_occupied, :boolean

    field :resource_1, :float
    field :resource_2, :float
    field :resource_3, :float

    field :storage_capacity, :integer

    field :building_1, :integer
    field :building_2, :integer
    field :building_3, :integer
    field :building_4, :integer
    field :building_5, :integer
    field :building_6, :integer

    field :unit_1, :integer
    field :unit_2, :integer

    field :points, :integer

    field :supply, :integer
    field :max_supply, :integer

    field :resources_gained_until, Ecto.DateTime
    field :units_recruited_until, Ecto.DateTime

    belongs_to :player, Player
    has_many :building_queue_items, BuildingQueueItem, on_replace: :delete
    has_many :unit_queue_items, UnitQueueItem, on_replace: :delete

    has_many :attack_movements, AttackMovement, on_replace: :delete,
                                                foreign_key: :origin_id

    many_to_many :related_reports, Report, join_through: RelatedReportVilla,
                                           join_keys: [villa_id: :id, related_report_id: :id]

    has_one :occupation, Occupation, foreign_key: :target_id
    has_many :occupations, Occupation, foreign_key: :origin_id

    timestamps
  end

  @required_fields ~w(name x y resource_1 resource_2 resource_3
                      building_1 building_2 building_3 building_4 building_5
                      building_6
                      unit_1 unit_2
                      supply
                      resources_gained_until units_recruited_until
                      player_id)
  @optional_fields ~w()

  @resources [:resource_1, :resource_2, :resource_3]

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_length(:name, min: 3)
    |> unique_constraint(:x, name: :villas_x_y_index)
  end

  def build_changeset(%{data: villa} = changeset, new_item, costs) do
    new_building_queue_items = Enum.map(villa.building_queue_items ++ [new_item], &Changeset.change/1)

    changeset
    |> subtract_resources(costs)
    |> validate_maxlevel(new_item)
    |> Changeset.put_assoc(:building_queue_items, new_building_queue_items)
    |> validate_resources
  end

  def recruit_changeset(%{data: villa} = changeset, new_item, costs, supply) do
    new_unit_queue_items = Enum.map(villa.unit_queue_items ++ [new_item], &Changeset.change/1)

    changeset
    |> subtract_resources(costs)
    |> Changeset.put_change(:supply, Changeset.get_field(changeset, :supply) + supply)
    |> Changeset.put_assoc(:unit_queue_items, new_unit_queue_items)
    |> validate_supply
    |> validate_resources
  end

  def order_units_changeset(%Changeset{} = changeset, units) do
    changeset
    |> subtract_units(units)
    |> validate_units
  end

  defp validate_maxlevel(%Changeset{} = changeset, item) do
    building = Building.get(item.building_id)

    case Building.virtual_level(changeset, building) >= building.maxlevel do
      true -> add_error(changeset, building.id, "Building already at maxlevel.")
      _    -> changeset
    end
  end

  defp validate_supply(%{data: villa} = changeset) do
    case get_field(changeset, :supply) > villa.max_supply do
      true -> add_error(changeset, :supply, "Not enough supply.")
      _    -> changeset
    end
  end

  defp validate_resources(changeset) do
    enough_resources =
      Enum.all? @resources, fn(r) -> get_field(changeset, r) > 0 end

    case enough_resources do
      false -> add_error(changeset, :resources, "Not enough resources.")
      _     -> changeset
    end
  end

  defp validate_units(changeset) do
    Enum.reduce LaFamiglia.Unit.all, changeset, fn(u, changeset) ->
      changeset
      |> validate_number(u.key, greater_than_or_equal_to: 0, message: "Not enough units.")
    end
  end

  @max_x 10
  @max_y 10
  def max_x, do: @max_x
  def max_y, do: @max_y

  def empty_coordinates do
    empty_coordinates({0, @max_x, 0, @max_y})
  end
  def empty_coordinates({x_1, x_2, y_1, y_2}) do
    x_range_length = x_2 - x_1 + 1
    y_range_length = y_2 - y_1 + 1

    max_villas_in_rectangle = x_range_length * y_range_length
    villas_in_rectangle     = in_rectangle(x_1, x_2, y_1, y_2)
                              |> Repo.all |> Enum.count

    if villas_in_rectangle < max_villas_in_rectangle do
      if max_villas_in_rectangle == 1 do
        { x_1, y_1 }
      else
        y_range_mean = y_1 + div(y_range_length, 2)
        x_range_mean = x_1 + div(x_range_length, 2)

        [ { x_1, x_2, y_1, y_range_mean - 1 },
          { x_1, x_2, y_range_mean, y_2 },
          { x_1, x_range_mean - 1, y_1, y_2 },
          { x_range_mean, x_2, y_1, y_2 } ]
        |> Enum.sort_by(fn (_) -> :rand.uniform end)
        |> Enum.find_value(fn(rectangle) -> empty_coordinates(rectangle) end)
      end
    end
  end

  def in_rectangle(x_1, x_2, y_1, y_2) do
    from v in Villa,
         where: v.x >= ^x_1 and v.x <= ^x_2
                and v.y >= ^y_1 and v.y <= ^y_2
  end

  def create_for(player) do
    case empty_coordinates do
      {x, y} ->
        %Villa{}
        |> Villa.changeset(
          %{ name: "New villa",
             x: x,
             y: y,
             resource_1: 0, resource_2: 0, resource_3: 0,
             building_1: 1, building_2: 0,
             building_3: 0, building_4: 0, building_5: 0,
             building_6: 0,
             unit_1: 0, unit_2: 0,
             supply: 0, max_supply: 100,
             resources_gained_until: LaFamiglia.DateTime.now,
             units_recruited_until: LaFamiglia.DateTime.now,
             player_id: player.id })
        |> Villa.recalc_points
        |> Villa.recalc_storage_capacity
        |> Villa.recalc_max_supply
      _ -> nil
    end
  end

  @doc """
  Processes resource gains and recruiting of units without saving
  the results to the database.
  """
  def process_virtually_until(%Changeset{} = changeset, time) do
    changeset
    |> gain_resources_until(time)
    |> process_units_virtually_until(time)
  end

  def process_virtually_until(%Villa{} = villa, time),
    do: villa |> Changeset.change |> process_virtually_until(time)

  @doc """
  Processes resource gains.

  This function assumes constant resource gains. It is the responsibility of
  the caller, i. e. mostly the event handler, to guarantee that there is no
  change in resource gains between `villa.resources_gained_until` and `time`.
  """
  def gain_resources_until(%Changeset{data: villa} = changeset, time) do
    case LaFamiglia.DateTime.time_diff(villa.resources_gained_until, time) do
      0 ->
        changeset
      time_diff ->
        changeset
        |> add_resources(resource_gains(villa, time_diff))
        |> put_change(:resources_gained_until, time)
    end
  end

  def has_supply?(%Changeset{} = changeset, supply) do
    get_field(changeset, :supply) + supply <= get_field(changeset, :max_supply)
  end
  def has_supply?(%Villa{} = villa, supply) do
    villa.supply + supply <= villa.max_supply
  end

  def has_resources?(%Changeset{} = changeset, resources) do
    Enum.all? resources, fn({k, v}) ->
      get_field(changeset, k) >= v
    end
  end

  def add_resources(%Changeset{} = changeset, resources) do
    storage_capacity = get_field(changeset, :storage_capacity)

    Enum.reduce @resources, changeset, fn(r, changeset) ->
      changeset
      |> put_change(r, min(get_field(changeset, r) + Map.get(resources, r, 0),
                           storage_capacity / 1))
    end
  end

  def subtract_resources!(%Changeset{} = changeset, resources) do
    changeset
    |> subtract_resources(resources)
    |> validate_resources
  end

  def subtract_resources(%Changeset{} = changeset, resources) do
    Enum.reduce @resources, changeset, fn(r, changeset) ->
      changeset
      |> put_change(r, get_field(changeset, r) - Map.get(resources, r, 0))
    end
  end

  def subtract_supply(%Changeset{} = changeset, supply) do
    put_change(changeset, :supply, get_field(changeset, :supply) - supply)
  end

  def resource_gains(villa, time_diff) do
    for {k, v} <- Application.get_env(:la_famiglia, :resource_gains).(villa),
      into: %{}, do: {k, v * time_diff / 3600}
  end

  def add_units(%Changeset{} = changeset, units) do
    Enum.reduce LaFamiglia.Unit.all, changeset, fn(u, changeset) ->
      changeset
      |> put_change(u.key, get_field(changeset, u.key) + Map.get(units, u.key, 0))
    end
  end

  def subtract_units(%Changeset{} = changeset, units) do
    Enum.reduce LaFamiglia.Unit.all, changeset, fn(u, changeset) ->
      changeset
      |> put_change(u.key, get_field(changeset, u.key) - Map.get(units, u.key, 0))
    end
  end

  def process_units_virtually_until(%Changeset{data: villa} = changeset, time) do
    case get_field(changeset, :unit_queue_items) do
      [first|rest] ->
        unit = Unit.get(first.unit_id)
        key  = unit.key

        number_recruited =
          UnitQueueItem.units_recruited_between(first, villa.units_recruited_until, time)

        first      = Changeset.change(first, %{number: first.number - number_recruited})
        changesets = [first | Enum.map(rest, &Changeset.change/1)]

        changeset
        |> put_change(key, get_field(changeset, key) + number_recruited)
        |> put_assoc(:unit_queue_items, changesets)
        |> put_change(:units_recruited_until, time)
      [] -> changeset
    end
  end

  def recalc_points(%Changeset{} = changeset) do
    new_points = for b <- Building.all do
      Building.level(changeset, b)
      |> b.points.()
      |> round
    end
    |> Enum.sum

    put_change(changeset, :points, new_points)
  end

  def recalc_storage_capacity(%Changeset{} = changeset) do
    new_storage_capacity =
      Application.get_env(:la_famiglia, :storage_capacity).(Changeset.apply_changes(changeset))
    put_change(changeset, :storage_capacity, new_storage_capacity)
  end

  def recalc_max_supply(%Changeset{} = changeset) do
    new_max_supply =
      Application.get_env(:la_famiglia, :max_supply).(Changeset.apply_changes(changeset))
    put_change(changeset, :max_supply, new_max_supply)
  end
end

defimpl String.Chars, for: LaFamiglia.Villa do
  def to_string(%LaFamiglia.Villa{name: name, x: x, y: y}) do
    "#{name} (#{x}|#{y})"
  end
end

defimpl Phoenix.HTML.Safe, for: LaFamiglia.Villa do
  def to_iodata(villa) do
    Plug.HTML.html_escape(to_string(villa))
  end
end
