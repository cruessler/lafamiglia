defmodule Mix.Tasks.LaFamiglia.EventLoop do
  use Mix.Task

  @shortdoc "Starts La Famiglia’s event loop"

  def run(args) do
    Application.put_env(:la_famiglia, :start_event_loop, true, persistent: true)
    Mix.Task.run "run", ["--no-halt"] ++ args
  end
end
