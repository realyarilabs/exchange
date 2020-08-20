defmodule Exchange.Adapters.Flux do
  @moduledoc """
  Public API to use the adapter of `Exchange.TimeSeries`, the Flux.
  This module uses the InfluxDB to write and query the data
  To use this adapter is necessary to add the Instream to the dependencies.
        config :exchange, Exchange.Adapters.Flux.Connection,
          database: System.get_env("FLUX_DB_NAME") || "dbname",
          host: System.get_env("FLUX_DB_HOST") || "localhost",
          port: System.get_env("FLUX_DB_PORT") || 8086`
  """
  use Exchange.TimeSeries, required_config: [:database, :host, :port], required_deps: [Instream]

  alias Exchange.Adapters.Flux.{Orders, Trades}

  def completed_trades(ticker) do
    Flux.Trades.completed_trades(ticker)
  end

  def completed_trades_by_id(ticker, trader_id) do
    Trades.completed_trades_by_id(ticker, trader_id)
  end

  def get_live_orders(ticker) do
    Orders.get_live_orders(ticker)
  end
end
