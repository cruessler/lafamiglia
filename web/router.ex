defmodule LaFamiglia.Router do
  use LaFamiglia.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", LaFamiglia do
    pipe_through :browser # Use the default browser stack

    resources "/sessions", SessionController, only: [ :create, :new ]

    resources "/players", PlayerController, only: [ :create, :new ]

    get "/", PageController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", LaFamiglia do
  #   pipe_through :api
  # end
end
