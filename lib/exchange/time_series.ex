defmodule Exchange.TimeSeries do
  @moduledoc """
  Behaviour that a time series database must implement
  to be able to communicate with the Exchange.
  """

  @doc """
  Function that fetches the completed trades from a market which a specific user participated.
  """
  @callback completed_trades(atom) :: [Exchange.Trade]

  @doc """
  Function that fetches the completed trades from a market which a specific user participated.
  """
  @callback completed_trades_by_id(atom, String.t()) :: [Exchange.Trade]
  @doc """
  Function that fetches the active orders of the application.
  It is called when the application starts running allowing the recovery of the previous state when a crash happens.
  """
  @callback get_live_orders(atom) :: [Exchange.Order]
end
