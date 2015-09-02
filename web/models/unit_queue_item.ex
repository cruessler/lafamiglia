defmodule LaFamiglia.UnitQueueItem do
  use LaFamiglia.Web, :model

  import LaFamiglia.Queue

  alias LaFamiglia.Repo
  alias LaFamiglia.Villa

  schema "unit_queue_items" do
    field :unit_id, :integer
    field :number, :integer
    field :build_time, :float
    field :completed_at, Ecto.DateTime

    belongs_to :villa, Villa

    timestamps
  end

  @required_fields ~w(unit_id number completed_at villa_id)
  @optional_fields ~w()

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end

  def enqueue!(old_villa, unit, number) do
    old_villa = Repo.preload(old_villa, :unit_queue_items)
    villa     = Villa.process_virtually_until(old_villa, LaFamiglia.DateTime.now)

    costs      = unit.costs
                 |> Enum.map(fn({k, v}) -> {k, v * number} end)
                 |> Enum.into(%{})
    supply     = unit.supply * number
    build_time = unit.build_time * number
    completed_at =
      completed_at(villa.unit_queue_items)
      |> LaFamiglia.DateTime.add_seconds(build_time)

    cond do
      !Villa.has_supply?(villa, supply) ->
        {:error, "You don’t have enough supply to recruit these units."}
      !Villa.has_resources?(villa, costs) ->
        {:error, "You don’t have enough resources to recruit these units."}
      true ->
        new_item = Ecto.Model.build(villa, :unit_queue_items,
                                    unit_id: unit.id,
                                    number: number,
                                    build_time: build_time / 1,
                                    completed_at: completed_at)

        Repo.transaction fn ->
          Villa.changeset(old_villa, Map.from_struct(villa)
                                     |> Map.put(:supply, villa.supply + supply))
          |> Repo.update!

          Repo.insert!(new_item)
        end
    end
  end
end
