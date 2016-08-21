defmodule LaFamiglia.Report do
  use LaFamiglia.Web, :model

  alias LaFamiglia.Repo

  alias LaFamiglia.Player
  alias LaFamiglia.Villa
  alias LaFamiglia.RelatedReportVilla
  alias LaFamiglia.{CombatReport, ConquestReport}

  schema "reports" do
    belongs_to :player, Player

    field :title, :string
    field :read, :boolean

    has_one :combat_report, CombatReport
    has_one :conquest_report, ConquestReport

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

  def payload(%{combat_report: %CombatReport{} = payload}), do: payload
  def payload(%{conquest_report: %ConquestReport{} = payload}), do: payload

  def preload_payload(report) do
    report
    |> Repo.preload([:combat_report, :conquest_report])
  end
end
