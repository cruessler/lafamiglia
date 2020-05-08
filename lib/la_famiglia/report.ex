defmodule LaFamiglia.Report do
  use LaFamiglia.Web, :model

  alias LaFamiglia.Repo

  alias LaFamiglia.Player
  alias LaFamiglia.Villa
  alias LaFamiglia.{CombatReport, ConquestReport}

  schema "reports" do
    belongs_to :player, Player

    belongs_to :origin, Villa
    belongs_to :target, Villa

    field :title, :string
    field :read, :boolean

    has_one :combat_report, CombatReport
    has_one :conquest_report, ConquestReport

    field :delivered_at, :utc_datetime_usec

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
    |> put_change(:delivered_at, LaFamiglia.DateTime.now())
    |> put_change(:read, false)
  end

  def payload(%{combat_report: %CombatReport{} = payload}), do: payload
  def payload(%{conquest_report: %ConquestReport{} = payload}), do: payload

  def preload_payload(report) do
    report
    |> Repo.preload([:combat_report, :conquest_report])
  end
end
