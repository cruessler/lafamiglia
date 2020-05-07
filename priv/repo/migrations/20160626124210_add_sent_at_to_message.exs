defmodule LaFamiglia.Repo.Migrations.AddSentAtToMessage do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      add :sent_at, :utc_datetime
    end
  end
end
