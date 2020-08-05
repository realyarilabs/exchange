use Mix.Config
config :exchange, message_bus_adapter: Exchange.Adapters.TestEventBus, environment: Mix.env()
config :exchange, Exchange.Application,
  tickers: [{:TEST1,:GBP,1000,100_000}, {:TEST2,:USD,2000,80_000}]
