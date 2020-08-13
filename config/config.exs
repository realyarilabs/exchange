use Mix.Config

config :exchange, environment: Mix.env()

config :exchange,
  message_bus_adapter: Exchange.Adapters.EventBus,
  time_series_adapter: Exchange.Adapters.InMemoryTimeSeries

if Mix.env() == :test do
  config :exchange,
    message_bus_adapter: Exchange.Adapters.TestEventBus,
    time_series_adapter: Exchange.Adapters.InMemoryTimeSeries

  config :exchange, Exchange.Application,
    tickers: [{:TEST1, :GBP, 1000, 100_000}, {:TEST2, :USD, 2000, 80_000}]
end
