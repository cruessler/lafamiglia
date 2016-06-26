defmodule LaFamiglia.Repo.Migrations.AddSentAtToMessage do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      add :sent_at, :datetime
    end
  end
end
