defmodule Exchange.TimeSeries do
  @moduledoc """
  Behaviour that a time series database must implement
  to be able to comunicate with the Exchange
  """
  @callback completed_trades_by_id(atom, String.t()) :: [Exchange.Trade]
  @callback get_live_orders(atom) :: [Exchange.Order]
end
