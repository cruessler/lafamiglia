# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     LaFamiglia.Repo.insert!(%LaFamiglia.SomeModel{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

LaFamiglia.DateTime.clock!

# This can only be run once as the email addresses generated by Blacksmith
# violate the unique constraint on subsequent runs of the application.
for p <- LaFamiglia.Factory.build_list(5, :player) do
  for _ <- 1..(:rand.uniform(5)),
    do: LaFamiglia.Villa.create_for(p)
end
