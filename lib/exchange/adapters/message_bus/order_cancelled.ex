defmodule Exchange.Adapters.MessageBus.OrderCancelled do
  @moduledoc """
  A struct representing the payload of :order_cancelled events.
  """

  use TypedStruct

  @typedoc "OrderCancelled"
  typedstruct do
    field(:order, Exchange.Order.order(), enforce: true)
  end

  @doc """
  Decodes the params to an OrderCancelled struct
  ## Parameters
    - params: map with necessary parameters to populate the struct
  """
  @spec decode_from_jason(map) :: Exchange.Adapters.MessageBus.OrderCancelled.t()
  def decode_from_jason(params) do
    order = Map.get(params, :order)
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
