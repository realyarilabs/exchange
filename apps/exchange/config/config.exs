use Mix.Config
config :exchange, Exchange.Application,
  tickers: [{:AUXLND, :GBP, 1000, 100_000}, {:AGUS, :USD, 1000, 100_000}]

config :exchange, message_bus_adapter: EventBus, time_series_adapter: Flux
