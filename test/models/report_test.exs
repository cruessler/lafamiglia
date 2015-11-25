defmodule LaFamiglia.ReportTest do
  use LaFamiglia.ModelCase

  alias LaFamiglia.Report

  @valid_attrs %{title: "This is a title", data: %{"key" => "value"}, player_id: 1}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Report.changeset(%Report{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Report.changeset(%Report{}, @invalid_attrs)
    refute changeset.valid?
  end
end
