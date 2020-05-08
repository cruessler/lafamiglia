defmodule LaFamiglia.Report.Schema do
  import Ecto.Changeset

  defmodule Units do
    use Ecto.Schema

    embedded_schema do
      field :unit_1, :integer
      field :unit_2, :integer
    end

    def changeset(struct, params \\ %{}) do
      struct
      |> cast(params, [:unit_1, :unit_2])
    end
  end

  defmodule Resources do
    use Ecto.Schema

    embedded_schema do
      field :resource_1, :integer
      field :resource_2, :integer
      field :resource_3, :integer
    end

    def changeset(struct, params \\ %{}) do
      struct
      |> cast(params, [:resource_1, :resource_2, :resource_3])
    end
  end
end
