defmodule Exchange.Adapters.MessageBus.TradeExecuted do
  @moduledoc """
  A struct representing the payload of :trade_executed events.
  """

  use TypedStruct

  @typedoc "TradeExecuted"
  typedstruct do
    field(:trade, Exchange.Trade, enforce: true)
  end

  @spec decode_from_jason(map) :: Exchange.Adapters.MessageBus.TradeExecuted.t()
  @doc """
  Decodes the payload to a TradeExecuted struct
  ## Parameters
    - payload: map with necessary parameters to populate the struct
  """
  def decode_from_jason(data) do
    trade = Map.get(data, :trade)
    %Exchange.Adapters.MessageBus.TradeExecuted{trade: Exchange.Trade.decode_from_jason(trade)}
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
