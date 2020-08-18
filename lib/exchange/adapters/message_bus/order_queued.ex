defmodule Exchange.Adapters.MessageBus.OrderQueued do
  @moduledoc """
  A struct representing the payload of :order_queued events.
  """

  use TypedStruct

  @typedoc "OrderQueued"
  typedstruct do
    field(:order, Exchange.Order.order(), enforce: true)
  end

  @spec decode_from_jason(map) :: Exchange.Adapters.MessageBus.OrderQueued.t()
  @doc """
  Decodes the payload to an OrderQueued struct
  ## Parameters
    - payload: map with necessary parameters to populate the struct
  """
  def decode_from_jason(data) do
    order = Map.get(data, :order)
    %Exchange.Adapters.MessageBus.OrderQueued{order: Exchange.Order.decode_from_jason(order)}
  end
end

defimpl Jason.Encoder, for: Exchange.Adapters.MessageBus.OrderQueued do
  def encode(value, opts) do
    Jason.Encode.map(
      Map.take(value, [
        :order
      ]),
      opts
    )
  end
end
