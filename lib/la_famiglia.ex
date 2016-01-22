defmodule LaFamiglia do
  use Application

  import Supervisor.Spec, warn: false

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    children = [
      # Start the endpoint when the application starts
      supervisor(LaFamiglia.Endpoint, []),
      # Start the Ecto repository
      worker(LaFamiglia.Repo, [])
    ] ++ worker_children

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LaFamiglia.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    LaFamiglia.Endpoint.config_change(changed, removed)
    :ok
  end

  defp start_event_loop?() do
    Application.get_env(:la_famiglia, :start_event_loop, false)
  end

  defp worker_children() do
    if start_event_loop? do
      [worker(LaFamiglia.EventLoop, []),
       worker(LaFamiglia.EventQueue, [])]
    else
      []
    end
  end
end
