defmodule LaFamiglia.EventQueue.Store do
  import Ecto.Query

  alias LaFamiglia.Repo

  alias LaFamiglia.BuildingQueueItem
  alias LaFamiglia.UnitQueueItem
  alias LaFamiglia.AttackMovement
  alias LaFamiglia.ComebackMovement
  alias LaFamiglia.Occupation

  def load do
    queries = [
      from(i in BuildingQueueItem, order_by: [asc: i.completed_at]),
      from(i in UnitQueueItem, order_by: [asc: i.completed_at]),
      from(m in AttackMovement, order_by: [asc: m.arrives_at]),
      from(m in ComebackMovement, order_by: [asc: m.arrives_at]),
      from(o in Occupation, order_by: [asc: o.succeeds_at])
    ]

    queue =
      queries
      |> Enum.map(&Repo.all/1)
      |> Enum.concat()
  end

  def get!(module, id), do: Repo.get!(module, id)
end
