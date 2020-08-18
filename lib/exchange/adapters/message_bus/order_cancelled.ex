defmodule Exchange.Adapters.MessageBus.OrderCancelled do
  @moduledoc """
  A struct representing the payload of :order_cancelled events.
  """

  use TypedStruct

  @typedoc "OrderCancelled"
  typedstruct do
    field(:order, Exchange.Order.order(), enforce: true)
  end

  @spec decode_from_jason(map) :: Exchange.Adapters.MessageBus.OrderCancelled.t()
  @doc """
  Decodes the payload to an OrderCancelled struct
  ## Parameters
    - payload: map with necessary parameters to populate the struct
  """
  def decode_from_jason(data) do
    order = Map.get(data, :order)
    %Exchange.Adapters.MessageBus.OrderCancelled{order: Exchange.Order.decode_from_jason(order)}
  end
end

defimpl Jason.Encoder, for: Exchange.Adapters.MessageBus.OrderCancelled do
  def encode(value, opts) do
    Jason.Encode.map(
      Map.take(value, [
        :order
      ]),
      opts
    )
  end
end
