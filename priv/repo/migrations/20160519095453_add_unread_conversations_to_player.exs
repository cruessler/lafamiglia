defmodule LaFamiglia.Repo.Migrations.AddUnreadConversationsToPlayer do
  use Ecto.Migration

  def change do
    alter table(:players) do
      add :unread_conversations, :integer
    end
  end
end
