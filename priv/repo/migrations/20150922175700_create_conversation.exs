defmodule LaFamiglia.Repo.Migrations.CreateConversation do
  use Ecto.Migration

  def change do
    create table(:conversations) do
      timestamps
    end

    create table(:conversation_statuses) do
      add :conversation_id, references(:conversations)
      add :player_id, references(:players)

      timestamps
    end

    create index(:conversation_statuses, [:conversation_id, :player_id], unique: true)
  end
end
