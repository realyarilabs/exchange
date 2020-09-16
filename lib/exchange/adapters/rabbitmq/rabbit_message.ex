if Code.ensure_loaded?(AMQP) do
  defmodule Exchange.Adapters.RabbitBus.RabbitMessage do
    @moduledoc """
    A struct representing the payload of :order_cancelled events.
    """

    use TypedStruct

    @typedoc "OrderCancelled"
    typedstruct do
      field(:event, atom(), enforce: true)

      field(
        :payload,
        Exchange.Adapters.MessageBus.OrderCancelled
        | Exchange.Adapters.MessageBus.OrderExpired
        | Exchange.Adapters.MessageBus.OrderQueued
        | Exchange.Adapters.MessageBus.PriceBroadcast
        | Exchange.Adapters.MessageBus.TradeExecuted
        | Exchange.Adapters.MessageBus.TradeProcessed
        | Exchange.Adapters.MessageBus.OrderPlaced,
        enforce: true
      )
    end
  end

  defimpl Jason.Encoder, for: Exchange.Adapters.RabbitBus.RabbitMessage do
    def encode(value, opts) do
      Jason.Encode.map(Map.take(value, [:event, :payload]), opts)
    end
  end
end
