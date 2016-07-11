defmodule LaFamiglia.EventHandlerCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias LaFamiglia.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query

      alias LaFamiglia.Villa

      import LaFamiglia.Factory
    end
  end

  setup tags do
    LaFamiglia.DateTime.clock!

    :ok = Ecto.Adapters.SQL.Sandbox.checkout(LaFamiglia.Repo, [])

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(LaFamiglia.Repo, {:shared, self()})
    end

    :ok
  end
end
