ExUnit.start

# Create the database, run migrations, and start the test transaction.
Mix.Task.run "ecto.create", ["--quiet"]
Mix.Task.run "ecto.migrate", ["--quiet"]
Ecto.Adapters.SQL.begin_test_transaction(LaFamiglia.Repo)

Code.require_file("test/test_event_queue.ex")

LaFamiglia.TestEventQueue.start_link()
