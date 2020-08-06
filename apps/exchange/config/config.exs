use Mix.Config

config :exchange, Exchange.Application,
  tickers: [{:AUXLND, :GBP, 1000, 100_000}, {:AGUS, :USD, 1000, 100_000}]

# Configures the endpoint
config :exchange, ExchangeWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "wf85GyugBkhtZnzTEWSXdrptN1zERfYEYlvqLZEzR00mdTN7RTTJlOfPcdf1Ev/V",
  render_errors: [view: ExchangeWeb.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: Exchange.PubSub,
  live_view: [signing_salt: "DS2hH8D7"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
