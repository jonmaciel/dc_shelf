defmodule DcShelfWeb.Router do
  use DcShelfWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", DcShelfWeb do
    pipe_through :api
  end
end
