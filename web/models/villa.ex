defmodule LaFamiglia.Villa do
  use LaFamiglia.Web, :model

  alias LaFamiglia.Repo
  alias LaFamiglia.Villa

  import Ecto.Query, only: [ from: 2 ]
  import LaFamiglia.DateTime, only: [ to_msecs: 1 ]

  schema "villas" do
    field :name, :string
    field :x, :integer
    field :y, :integer

    field :resource_1, :float
    field :resource_2, :float
    field :resource_3, :float

    field :storage_capacity, :integer

    field :processed_until, Ecto.DateTime

    belongs_to :player, Player

    timestamps
  end

  @required_fields ~w(name x y resource_1 resource_2 resource_3 storage_capacity processed_until player_id)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> validate_length(:name, min: 3)
  end

  @max_x 10
  @max_y 10

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
        |> Enum.sort_by(fn (_) -> :random.uniform end)
        |> Enum.find_value fn(rectangle) -> empty_coordinates(rectangle) end
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
        changeset = Villa.changeset(%Villa{},
                                    %{ name: "New villa",
                                       x: x,
                                       y: y,
                                       resource_1: 0, resource_2: 0, resource_3: 0,
                                       storage_capacity: 100,
                                       processed_until: Ecto.DateTime.local,
                                       player_id: player.id })
        Repo.insert!(changeset)
      _ -> nil
    end
  end

  @doc """
  Processes resource gains and recruiting of units without saving
  the results to the database.
  """
  def process_virtually_until %Villa{processed_until: processed_until} = villa, time do
    case to_msecs(time) - to_msecs(processed_until) do
      0 ->
        villa
      time_diff ->
        villa = villa
                |> add_resources(resource_gains time_diff)

        %Villa{ villa | processed_until: time }
    end
  end

  def get_resources(%Villa{resource_1: resource_1, resource_2: resource_2, resource_3: resource_3}) do
    %{resource_1: resource_1, resource_2: resource_2, resource_3: resource_3}
  end

  def put_resources(villa, %{resource_1: resource_1, resource_2: resource_2, resource_3: resource_3}) do
    %Villa{villa | resource_1: resource_1, resource_2: resource_2, resource_3: resource_3}
  end

  def add_resources(%Villa{storage_capacity: storage_capacity} = villa, resources) do
    old_resources = Villa.get_resources(villa)

    new_resources = Map.merge old_resources, resources, fn(_k, v1, v2) ->
      min(v1 + v2, storage_capacity)
    end

    Villa.put_resources(villa, new_resources)
  end

  def resource_gains time_diff do
    %{
      resource_1: time_diff * 0.01,
      resource_2: time_diff * 0.01,
      resource_3: time_diff * 0.01
    }
  end

  def to_string(%Villa{name: name, x: x, y: y}) do
    "#{name} (#{x}|#{y})"
  end
end
