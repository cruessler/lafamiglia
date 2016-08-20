defmodule LaFamiglia.Report do
  use LaFamiglia.Web, :model

  alias LaFamiglia.Repo

  alias LaFamiglia.Player
  alias LaFamiglia.Villa
  alias LaFamiglia.RelatedReportVilla
  alias LaFamiglia.CombatReport

  schema "reports" do
    belongs_to :player, Player

    field :title, :string
    field :read, :boolean

    has_one :combat_report, CombatReport

    field :delivered_at, Ecto.DateTime

    many_to_many :related_villas, Villa, join_through: RelatedReportVilla,
                                         join_keys: [related_report_id: :id, villa_id: :id]

    timestamps
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:title])
    |> validate_required([:title])
    |> assoc_constraint(:player)
    |> put_change(:delivered_at, LaFamiglia.DateTime.now)
    |> put_change(:read, false)
  end
end
