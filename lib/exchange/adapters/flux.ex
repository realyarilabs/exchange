defmodule Exchange.Adapters.Flux do
  @moduledoc """
  Documentation for a Flux adapter
  default configuration
    config :exchange, Exchange.Adapters.Flux.Connection,
        database: System.get_env("FLUX_DB_NAME") || "dbname",
        host: System.get_env("FLUX_DB_HOST") || "localhost",
        port: System.get_env("FLUX_DB_PORT") || 8086,
  """
  use Exchange.TimeSeries, required_config: [:database, :host, :port], required_deps: [Instream]
  use Instream.Connection, otp_app: :exchange
  alias Exchange.Adapters.Flux.{Orders, Trades}

  def completed_trades_by_id(ticker, trader_id) do
    Trades.completed_trades_by_id(ticker, trader_id)
  end

  def get_live_orders(ticker) do
    Orders.get_live_orders(ticker)
  end
end
