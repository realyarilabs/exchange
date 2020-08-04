use Mix.Config
config :exchange, message_bus_adapter: Exchange.Adapters.TestEventBus
config :exchange, Exchange.Application,
  tickers: [{:AUXLND,:GBP,1000,100_000}, {:AGUS,:USD,2000,80_000}]
