# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :exq,
  name: Exq,
  host: "127.0.0.1",
  port: 6379,
  namespace: "exq",
  concurrency: :infinite,
  queues: ["default"],
  poll_timeout: 50,
  scheduler_poll_timeout: 200,
  scheduler_enable: true,
  max_retries: 7,
  shutdown_timeout: 5000

# Configures the endpoint
config :dc_shelf, DcShelfWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "kSZRlcWwrK0bDjQ1l+jpUVX8OeT1094NRruZ+is5Ws+Vg3nadN3kVV7YbNfWEZI7",
  render_errors: [view: DcShelfWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: DcShelf.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

# shelf: gpio_pin
config :dc_shelf,
  webhook_urls: [
    %{
      url: "http://localhost:4000/api/tuktuk_webhook_update",
      header: "dnada/616c5cc9cab1ecf30e45fe8781cf71b2"
    }
  ],
  shelf_slots: %{
    "shelf_slot_blue" => [shelf_pin: 22, shopper_pin: 4, driver_pin: 14],
    "shelf_slot_red" => [shelf_pin: 23, shopper_pin: 17, driver_pin: 18]
  }
