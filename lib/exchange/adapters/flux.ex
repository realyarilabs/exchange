defmodule Exchange.Adapters.Flux do
  @moduledoc """
  Documentation for a Flux adapter
  """
  use Exchange.TimeSeries, required_config: [], required_deps: [:instream]
  alias Exchange.Adapters.Flux.{Trades, Orders}

  def completed_trades_by_id(ticker, trader_id) do
    Trades.completed_trades_by_id(ticker, trader_id)
  end

  def get_live_orders(ticker) do
    Orders.get_live_orders(ticker)
  end
end
