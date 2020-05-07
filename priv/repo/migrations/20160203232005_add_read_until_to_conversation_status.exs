defmodule LaFamiglia.Repo.Migrations.AddReadUntilToConversationStatus do
  use Ecto.Migration

  def change do
    alter table(:conversation_statuses) do
      add :read_until, :utc_datetime
    end

    create index(:conversation_statuses, [:read_until])
  end
end
