defmodule LaFamiglia.OccupationTest do
  use LaFamiglia.ModelCase

  alias LaFamiglia.Repo

  alias LaFamiglia.Occupation

  test "associations" do
    origin = Forge.saved_villa(Repo)
    target = Forge.saved_villa(Repo)

    params =
      %{unit_1: 0, unit_2: 0, origin_id: origin.id, target_id: target.id,
        succeeds_at: LaFamiglia.DateTime.now}

    occupation = Occupation.changeset(%Occupation{}, params)

    assert {:ok, occupation} = Repo.insert(occupation)

    assert [^occupation] = assoc(origin, :occupations) |> Repo.all
    assert ^occupation = assoc(target, :occupation) |> Repo.one
  end
end
