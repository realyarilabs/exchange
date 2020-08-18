defmodule Exchange.Adapters.MessageBus.OrderExpired do
  @moduledoc """
  A struct representing the payload of :order_expired events.
  """

  use TypedStruct

  @typedoc "OrderExpired"
  typedstruct do
    field(:order, Exchange.Order.order(), enforce: true)
  end

  def decode_from_jason(data) do
    order = Map.get(data, :order)
    %Exchange.Adapters.MessageBus.OrderExpired{order: Exchange.Order.decode_from_jason(order)}
  end
end

defimpl Jason.Encoder, for: Exchange.Adapters.MessageBus.OrderExpired do
  def encode(value, opts) do
    Jason.Encode.map(
      Map.take(value, [
        :order
      ]),
      opts
    )
  end
end
