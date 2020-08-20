defmodule Exchange.Adapters.Flux do
  @moduledoc """
  Documentation for a Flux adapter
  """
  @behaviour Exchange.TimeSeries

  def completed_trades(ticker) do
    Flux.Trades.completed_trades(ticker)
  end

  def completed_trades_by_id(ticker, trader_id) do
    Flux.Trades.completed_trades_by_id(ticker, trader_id)
  end

  def get_live_orders(ticker) do
    Flux.Orders.get_live_orders(ticker)
  end
end
