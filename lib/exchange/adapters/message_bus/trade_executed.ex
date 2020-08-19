defmodule Exchange.Adapters.MessageBus.TradeExecuted do
  @moduledoc """
  A struct representing the payload of :trade_executed events.
  """

  use TypedStruct

  @typedoc "TradeExecuted"
  typedstruct do
    field(:trade, Exchange.Trade, enforce: true)
  end

  @doc """
  Decodes the params to a TradeExecuted struct
  ## Parameters
    - params: map with necessary parameters to populate the struct
  """
  @spec decode_from_jason(map) :: Exchange.Adapters.MessageBus.TradeExecuted.t()
  def decode_from_jason(params) do
    trade = Map.get(params, :trade)

    trade_executed = %Exchange.Adapters.MessageBus.TradeExecuted{
      trade: Exchange.Trade.decode_from_jason(trade)
    }

    trade_executed
  end
end

defimpl Jason.Encoder, for: Exchange.Adapters.MessageBus.TradeExecuted do
  def encode(value, opts) do
    Jason.Encode.map(
      Map.take(value, [
        :trade
      ]),
      opts
    )
  end
end
