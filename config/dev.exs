use Mix.Config

config :exchange,
  message_bus_adapter: EventBus,
  time_series_adapter: Exchange.Adapters.InMemoryTimeSeries

config :exchange, Exchange.Application,
  tickers: [{:AUXLND, :GBP, 1000, 100_000}, {:AGUS, :USD, 1000, 100_000}]
