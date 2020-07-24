defmodule EventBus.TradeExecuted do
  @moduledoc """
  A struct representing the payload of :trade_executed events.
  """

  use TypedStruct

  @typedoc "TradeExecuted"
  typedstruct do
    field(:trade, Exchange.Trade, enforce: true)
  end
end
