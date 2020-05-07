defmodule Mix.Tasks.LaFamiglia.Server do
  use Mix.Task

  @shortdoc "Starts a La Famiglia server"

  def run(args) do
    Application.put_env(:la_famiglia, :start_event_loop, true, persistent: true)
    Mix.Task.run("phx.server", args)
  end
end
