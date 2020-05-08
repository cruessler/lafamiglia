defmodule LaFamiglia.ConquestReport do
  use LaFamiglia.Web, :model

  import Ecto.Changeset

  alias Ecto.Multi

  alias LaFamiglia.Villa
  alias LaFamiglia.Report

  alias __MODULE__

  schema "conquest_reports" do
    belongs_to :report, Report

    belongs_to :target, Villa
  end

  @spec deliver(Occupation.t()) :: Multi.t()
  def deliver(occupation) do
    Multi.new()
    |> Multi.insert(:report_for_origin, report_for(occupation.origin, occupation))
    |> Multi.insert(:report_for_target, report_for(occupation.target, occupation))
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [])
  end

  defp report_for(villa, occupation) do
    conquest_report =
      %ConquestReport{}
      |> changeset(Map.from_struct(occupation))
      |> put_assoc(:target, occupation.target)

    %Report{}
    |> Report.changeset(%{title: title_for(villa, occupation)})
    |> put_assoc(:conquest_report, conquest_report)
    |> put_assoc(:player, villa.player)
    |> put_assoc(:origin, occupation.origin)
    |> put_assoc(:target, occupation.target)
  end

  defp title_for(villa, occupation) do
    if villa == occupation.origin do
      "Conquest of #{occupation.target}"
    else
      "Loss of #{occupation.target}"
    end
  end
end
