defmodule TwitterEnginePhxWeb.Router do
  use TwitterEnginePhxWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", TwitterEnginePhxWeb do
    pipe_through :browser

    get "/", PageController, :index
    get "/login_action", PageController, :login_action
    get "/login", PageController, :login
    get "/logout", PageController, :logout
    get "/signup", PageController, :signup
    get "/register_action", PageController, :register_action
    get "/home", PageController, :home
    get "/posttweet", PageController, :posttweet
    get "/allusers", PageController, :allusers
    get "/simulator", PageController, :simulator
    get "/start", PageController, :start

  end

  # Other scopes may use custom stacks.
  # scope "/api", TwitterEnginePhxWeb do
  #   pipe_through :api
  # end
end
